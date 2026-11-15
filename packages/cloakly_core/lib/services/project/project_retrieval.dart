import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/data/repositories/meeting_repository.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/project/project_document_reader.dart';
import 'package:cloakly_core/services/project/project_indexer.dart';

enum ProjectQuestionMode { search, overview }

class ProjectSource {
  const ProjectSource({
    required this.projectId,
    required this.title,
    required this.location,
    required this.text,
    required this.date,
    required this.group,
    this.meetingId,
  });

  final String projectId;
  final String title;
  final String location;
  final String text;
  // File modification time is not a decision's effective date.
  final DateTime date;
  final String group;
  final String? meetingId;

  String get label => '$title · $location';
}

class ProjectEvidence {
  const ProjectEvidence({required this.sources, required this.warnings});
  final List<ProjectSource> sources;
  final List<String> warnings;

  String context(String projectName, ProjectQuestionMode mode) {
    final l10n = CloaklyLocale.strings;
    return jsonEncode({
      'project': projectName,
      'queriedAt': DateTime.now().toIso8601String(),
      'mode': mode.name,
      'coverage': l10n.coverageNote,
      'warnings': [
        ...warnings
            .take(20)
            .map(
              (warning) => warning.length > 300
                  ? '${warning.substring(0, 300)}…'
                  : warning,
            ),
        if (warnings.length > 20) l10n.moreReadLimits(warnings.length - 20),
      ],
      'sources': [
        for (var i = 0; i < sources.length; i++)
          {
            'id': 'S${i + 1}',
            'title': sources[i].title,
            'location': sources[i].location,
            'date': sources[i].date.toIso8601String(),
            'dateMeaning': sources[i].meetingId == null
                ? l10n.fileModifiedNotDecision
                : l10n.meetingTimeShort,
            'text': sources[i].text,
          },
      ],
    });
  }

  Set<int> citations(String answer) {
    final found = <int>{};
    for (final match in RegExp(r'\[S(\d+)\]').allMatches(answer)) {
      final index = int.parse(match.group(1)!) - 1;
      if (index < 0 || index >= sources.length) {
        throw StateError(CloaklyLocale.strings.citationMissing);
      }
      found.add(index);
    }
    if (found.isEmpty) {
      throw StateError(CloaklyLocale.strings.citationRequired);
    }
    return found;
  }
}

/// Local lexical RAG: English words and Chinese bigrams, with explicit scope.
/// No embeddings, cross-project search, or claims of complete project status.
class ProjectRetrieval {
  ProjectRetrieval(this.repository);
  final MeetingRepository repository;
  static const maxSources = 16;
  static const chunkChars = 1200;

  Future<ProjectEvidence> retrieve(
    ProjectPack pack,
    String question, {
    ProjectQuestionMode mode = ProjectQuestionMode.search,
  }) async {
    final candidates = <ProjectSource>[];
    final warnings = <String>[];
    var scanned = 0;
    void collect(Iterable<ProjectSource> sources) {
      for (final source in sources) {
        scanned++;
        candidates.add(source);
        if (candidates.length >= 1024) {
          final best = rank(
            candidates,
            question,
            projectId: pack.id,
            mode: mode,
          );
          candidates
            ..clear()
            ..addAll(best);
        }
      }
    }

    String? root;
    try {
      root = await Directory(pack.folderPath).resolveSymbolicLinks();
    } on FileSystemException {
      warnings.add(CloaklyLocale.strings.folderUnreadable);
    }
    if (root != null) {
      final discovered = await ProjectIndexer().index(root, id: pack.id);
      if (discovered.docs.length >= ProjectIndexer.maxDocs) {
        warnings.add(CloaklyLocale.strings.scanCap(ProjectIndexer.maxDocs));
      }
      for (final doc in discovered.docs) {
        try {
          final content = await ProjectDocumentReader().read(pack, doc);
          warnings.addAll(
            content.warnings.map((warning) => '${doc.relativePath}: $warning'),
          );
          for (final section in content.sections) {
            collect(
              _chunks(
                pack.id,
                doc.relativePath,
                section.text,
                content.modified,
                group: 'file:${doc.relativePath}',
                location: section.location,
              ),
            );
          }
        } on FileSystemException {
          warnings.add(CloaklyLocale.strings.docUnreadable(doc.relativePath));
        } on FormatException catch (error) {
          warnings.add(
            CloaklyLocale.strings.docReadError(doc.relativePath, error.message),
          );
        }
      }
    }
    for (final meeting in await repository.list(projectId: pack.id)) {
      // Keep the boundary even if a custom repository returns extra records.
      if (meeting.projectId != pack.id) continue;
      final title =
          '${meeting.startedAt.toLocal().toIso8601String().substring(0, 16)} ${meeting.title}';
      final group = 'meeting:${meeting.id}';
      collect(
        _chunks(
          pack.id,
          title,
          meeting.minutesMarkdown ?? '',
          meeting.startedAt,
          group: group,
          location: CloaklyLocale.strings.aiMinutesLocation,
          meetingId: meeting.id,
        ),
      );
      final lines = (await repository.listLines(
        meeting.id,
      )).where((line) => line.isFinal).toList();
      if (lines.isEmpty && (meeting.audioPath?.isNotEmpty ?? false)) {
        warnings.add(
          CloaklyLocale.strings.audioWithoutTranscript(meeting.title),
        );
      }
      // Keep adjacent utterances together: the next speaker often gives the
      // owner or deadline without repeating the feature name in the question.
      for (var i = 0; i < lines.length; i += 4) {
        final block = lines.skip(i).take(6).toList();
        collect(
          _chunks(
            pack.id,
            title,
            block
                .map(
                  (line) =>
                      '[${timestamp(line.startMs)}] ${line.speaker}：${line.text}',
                )
                .join('\n'),
            meeting.startedAt,
            group: group,
            location: CloaklyLocale.strings.transcriptSpan(
              timestamp(block.first.startMs),
              timestamp(block.last.endMs),
            ),
            meetingId: meeting.id,
          ),
        );
      }
      for (final note in await repository.listNotes(meeting.id)) {
        collect(
          _chunks(
            pack.id,
            title,
            note.text,
            meeting.startedAt,
            group: group,
            location: CloaklyLocale.strings.liveNotesLocation,
            meetingId: meeting.id,
          ),
        );
      }
    }
    final selected = rank(candidates, question, projectId: pack.id, mode: mode);
    if (scanned > selected.length) {
      warnings.add(
        CloaklyLocale.strings.searchSummary(scanned, selected.length),
      );
    }
    return ProjectEvidence(sources: selected, warnings: warnings);
  }

  static List<ProjectSource> rank(
    List<ProjectSource> candidates,
    String question, {
    required String projectId,
    ProjectQuestionMode mode = ProjectQuestionMode.search,
  }) {
    final terms = _terms(question);
    final ranked = <({ProjectSource source, double score})>[];
    for (final source in candidates) {
      if (source.projectId != projectId) continue;
      final hits = terms.where(source.text.toLowerCase().contains).length;
      final titleHits = terms.where(source.title.toLowerCase().contains).length;
      final progress = mode == ProjectQuestionMode.overview
          ? RegExp(
                  r'完成|進度|結果|測試|阻塞|待辦|下一步|進行中|延期|風險|時程|期限|里程碑|負責人|deadline|schedule|milestone|progress|completed|blocked|next step|wbs',
                  caseSensitive: false,
                ).allMatches(source.text).length.clamp(0, 8) *
                0.2
          : 0.0;
      if (mode == ProjectQuestionMode.search && hits + titleHits == 0) continue;
      ranked.add((
        source: source,
        score:
            progress +
            (terms.isEmpty ? 0 : (hits + titleHits * 0.25) / terms.length),
      ));
    }
    ranked.sort((a, b) {
      final relevance = b.score.compareTo(a.score);
      final recency = b.source.date.compareTo(a.source.date);
      return mode == ProjectQuestionMode.overview
          ? (recency != 0 ? recency : relevance)
          : (relevance != 0 ? relevance : recency);
    });
    // First pass gives different files/meetings room in the context.
    final selected = <ProjectSource>[];
    final perGroup = <String, int>{};
    // A recent deck must not displace all oral progress updates, or vice versa.
    if (mode == ProjectQuestionMode.overview) {
      for (final isMeeting in [false, true]) {
        var count = 0;
        for (final item in ranked) {
          if ((item.source.meetingId != null) != isMeeting) continue;
          final groupCount = perGroup[item.source.group] ?? 0;
          if (groupCount >= 3) continue;
          selected.add(item.source);
          perGroup[item.source.group] = groupCount + 1;
          if (++count >= 6) break;
        }
      }
    }
    for (final limit in [2, 6]) {
      for (final item in ranked) {
        if (selected.length >= maxSources) return selected;
        if (selected.contains(item.source)) continue;
        final count = perGroup[item.source.group] ?? 0;
        if (count >= limit) continue;
        selected.add(item.source);
        perGroup[item.source.group] = count + 1;
      }
    }
    return selected;
  }

  static ProjectQuestionMode modeFor(
    String question,
    ProjectQuestionMode selected,
  ) {
    if (selected == ProjectQuestionMode.overview ||
        RegExp(
          r'(目前|現在|最新|整體|專案|研究).{0,8}(進度|狀況|現況)|做到哪|進展|時程|期限|里程碑|待辦工作|project\s+(status|progress|plan|schedule)|gantt|wbs',
          caseSensitive: false,
        ).hasMatch(question)) {
      return ProjectQuestionMode.overview;
    }
    return selected;
  }

  static Set<String> _terms(String question) {
    final cleaned = question.toLowerCase().replaceAll(
      RegExp(r'目前|專案|狀況|哪一次|哪次|會議|有沒有|什麼|請問|幫我|的|了|嗎'),
      ' ',
    );
    final terms = <String>{};
    for (final match in RegExp(
      r'[a-z0-9_]+|[\u3400-\u9fff]+',
    ).allMatches(cleaned)) {
      final token = match.group(0)!;
      if (RegExp(r'^[a-z0-9_]+$').hasMatch(token)) {
        if (!{
          'the',
          'is',
          'a',
          'what',
          'when',
          'project',
          'status',
        }.contains(token)) {
          terms.add(token);
        }
      } else if (token.length == 1) {
        continue;
      } else {
        for (var i = 0; i < token.length - 1; i++) {
          terms.add(token.substring(i, i + 2));
        }
      }
    }
    return terms;
  }

  static Iterable<ProjectSource> _chunks(
    String projectId,
    String title,
    String text,
    DateTime date, {
    required String group,
    required String location,
    String? meetingId,
  }) sync* {
    final lines = const LineSplitter().convert(text);
    var buffer = StringBuffer();
    var firstLine = 1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (buffer.length + line.length > chunkChars && buffer.isNotEmpty) {
        yield ProjectSource(
          projectId: projectId,
          title: title,
          location: CloaklyLocale.strings.lineRange(location, firstLine, i),
          text: buffer.toString().trim(),
          date: date,
          group: group,
          meetingId: meetingId,
        );
        buffer = StringBuffer();
        firstLine = i + 1;
      }
      // Split long single-line JSON or transcript without dropping its tail.
      for (var offset = 0; offset < line.length; offset += chunkChars) {
        final part = line.substring(
          offset,
          math.min(offset + chunkChars, line.length),
        );
        if (part.length == chunkChars) {
          yield ProjectSource(
            projectId: projectId,
            title: title,
            location: CloaklyLocale.strings.lineOffset(
              location,
              i + 1,
              offset + 1,
            ),
            text: part,
            date: date,
            group: group,
            meetingId: meetingId,
          );
          firstLine = i + 1;
        } else {
          if (buffer.isEmpty) firstLine = i + 1;
          buffer.writeln(part);
        }
      }
    }
    if (buffer.toString().trim().isNotEmpty) {
      yield ProjectSource(
        projectId: projectId,
        title: title,
        location: CloaklyLocale.strings.lineRange(
          location,
          firstLine,
          lines.length,
        ),
        text: buffer.toString().trim(),
        date: date,
        group: group,
        meetingId: meetingId,
      );
    }
  }

  static String timestamp(int ms) {
    final seconds = ms ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
