import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/data/repositories/meeting_repository.dart';
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

  String context(String projectName, ProjectQuestionMode mode) => jsonEncode({
    'project': projectName,
    'queriedAt': DateTime.now().toIso8601String(),
    'mode': mode.name,
    'coverage': '提問時掃描本專案資料夾內支援的文件與已儲存的會議資料；不是完整即時狀態。',
    'warnings': [
      ...warnings
          .take(20)
          .map(
            (warning) => warning.length > 300
                ? '${warning.substring(0, 300)}…'
                : warning,
          ),
      if (warnings.length > 20) '另有 ${warnings.length - 20} 項讀取限制，介面可查看完整列表。',
    ],
    'sources': [
      for (var i = 0; i < sources.length; i++)
        {
          'id': 'S${i + 1}',
          'title': sources[i].title,
          'location': sources[i].location,
          'date': sources[i].date.toIso8601String(),
          'dateMeaning': sources[i].meetingId == null
              ? '檔案修改時間，非決議生效日'
              : '會議時間',
          'text': sources[i].text,
        },
    ],
  });

  Set<int> citations(String answer) {
    final found = <int>{};
    for (final match in RegExp(r'\[S(\d+)\]').allMatches(answer)) {
      final index = int.parse(match.group(1)!) - 1;
      if (index < 0 || index >= sources.length) {
        throw StateError('回答引用了不存在的來源，請重新提問。');
      }
      found.add(index);
    }
    if (found.isEmpty) throw StateError('回答沒有附上來源，請重新提問或縮小問題。');
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
      warnings.add('專案資料夾無法讀取，未搜尋文件。');
    }
    if (root != null) {
      final discovered = await ProjectIndexer().index(root, id: pack.id);
      if (discovered.docs.length >= ProjectIndexer.maxDocs) {
        warnings.add('資料夾掃描已達 ${ProjectIndexer.maxDocs} 份安全上限，可能還有未搜尋文件。');
      }
      for (final doc in discovered.docs) {
        try {
          final content = await ProjectDocumentReader().read(pack, doc);
          warnings.addAll(
            content.warnings.map((warning) => '${doc.relativePath}：$warning'),
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
          warnings.add('${doc.relativePath} 無法讀取或不在專案內，未搜尋。');
        } on FormatException catch (error) {
          warnings.add('${doc.relativePath}：${error.message}，未搜尋。');
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
          location: 'AI 會議紀錄（需核對逐字稿）',
          meetingId: meeting.id,
        ),
      );
      final lines = (await repository.listLines(
        meeting.id,
      )).where((line) => line.isFinal).toList();
      if (lines.isEmpty && (meeting.audioPath?.isNotEmpty ?? false)) {
        warnings.add('${meeting.title} 有音檔但沒有定稿逐字稿；本次不會直接分析音檔。');
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
            location:
                '逐字稿 ${timestamp(block.first.startMs)}–${timestamp(block.last.endMs)}',
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
            location: '現場筆記',
            meetingId: meeting.id,
          ),
        );
      }
    }
    final selected = rank(candidates, question, projectId: pack.id, mode: mode);
    if (scanned > selected.length) {
      warnings.add('搜尋 $scanned 個段落，提供 ${selected.length} 個檢索片段；未命中不代表從未討論。');
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
                  r'完成|進度|結果|測試|阻塞|待辦|下一步|進行中|延期|風險|progress|completed|blocked|next step',
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
          r'(目前|現在|最新|整體|專案|研究).{0,8}(進度|狀況|現況)|做到哪|進展|project\s+(status|progress)',
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
          location: '$location · 第 $firstLine–$i 行',
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
            location: '$location · 第 ${i + 1} 行，字元 ${offset + 1}',
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
        location: '$location · 第 $firstLine–${lines.length} 行',
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
