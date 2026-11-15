import 'dart:io';

import 'package:cloakly_core/data/models/models.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/audio/recording_export.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_core/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(meetingBundleProvider(meetingId));
    final l10n = context.l10n;
    return bundle.when(
      loading: () => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => _goHome(context))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => _goHome(context))),
        body: Center(child: Text(l10n.loadFailed('$error'))),
      ),
      data: (data) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => _goHome(context)),
            title: Text(data.meeting.title),
            actions: [
              IconButton(
                tooltip: l10n.share,
                onPressed: () => _showShareOptions(context, ref, data),
                icon: const Icon(Icons.ios_share),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.meetingsTitle),
                Tab(text: l10n.transcript),
                Tab(text: l10n.notes),
                Tab(text: l10n.hints),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _MinutesTab(meeting: data.meeting),
              TranscriptList(
                lines: data.lines,
                emptyLabel: l10n.meetingNoTranscript,
              ),
              _NotesTab(notes: data.notes, startedAt: data.meeting.startedAt),
              _HintsTab(
                suggestions: data.suggestions,
                startedAt: data.meeting.startedAt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _showShareOptions(
    BuildContext context,
    WidgetRef ref,
    MeetingBundle data,
  ) async {
    final projectFolder = _projectFolder(ref, data.meeting);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notes_outlined),
                title: Text(l10n.shareMinutes),
                subtitle: Text(l10n.shareMinutesSubtitle),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareText(context, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(l10n.saveRecording),
                subtitle: Text(
                  projectFolder == null
                      ? l10n.saveRecordingNoProject
                      : l10n.saveRecordingInProject,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveAudio(context, data, projectFolder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(l10n.shareRecording),
                subtitle: Text(l10n.shareRecordingSubtitle),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareAudio(context, data);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String? _projectFolder(WidgetRef ref, Meeting meeting) {
    final id = meeting.projectId;
    if (id == null || id.isEmpty) return null;
    final projects =
        ref.read(projectsProvider).valueOrNull?.projects ?? const [];
    for (final project in projects) {
      if (project.id == id) return project.folderPath;
    }
    return null;
  }

  Future<void> _shareText(BuildContext context, MeetingBundle data) async {
    final buffer = StringBuffer()
      ..writeln('# ${data.meeting.title}')
      ..writeln()
      ..writeln(formatMeetingWhen(data.meeting))
      ..writeln()
      ..writeln(
        MinutesResult.readableMinutesMarkdown(
              data.meeting.minutesMarkdown ?? '',
            ) ??
            data.meeting.minutesMarkdown ??
            context.l10n.noMinutesYetExport,
      )
      ..writeln()
      ..writeln('## ${context.l10n.headingTranscript}')
      ..writeln();
    for (final line in data.lines) {
      buffer.writeln(
        '[${formatDuration(Duration(milliseconds: line.startMs))}] ${line.speaker}: ${line.text}',
      );
    }
    if (data.notes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## ${context.l10n.headingNotes}')
        ..writeln();
      for (final note in data.notes) {
        buffer.writeln(
          '[${formatElapsedSince(note.createdAt, data.meeting.startedAt)}] ${note.text}',
        );
      }
    }
    if (data.suggestions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## ${context.l10n.headingPrompts}')
        ..writeln();
      for (final hint in data.suggestions) {
        buffer
          ..writeln(
            '[${formatElapsedSince(hint.createdAt, data.meeting.startedAt)}]',
          )
          ..writeln(hint.answer)
          ..writeln();
      }
    }
    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: data.meeting.title,
        sharePositionOrigin: _shareOrigin(context),
      ),
    );
  }

  Future<void> _saveAudio(
    BuildContext context,
    MeetingBundle data,
    String? projectFolder,
  ) async {
    final source = await RecordingExport.find(data.meeting);
    if (!context.mounted) return;
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noRecordingToSave)));
      return;
    }
    try {
      final exportSource = await RecordingExport.preferredM4a(source);
      final saved = await RecordingExport.saveToUserFolder(
        source: exportSource,
        fileName: RecordingExport.fileNameFor(data.meeting, exportSource),
        projectFolder: projectFolder,
      );
      if (!context.mounted) return;
      final inProject =
          projectFolder != null &&
          p.normalize(saved).startsWith(p.normalize(projectFolder));
      final l10n = context.l10n;
      final where = inProject
          ? saved
          : Platform.isIOS
          ? l10n.iosFilesPath
          : Platform.isAndroid
          ? l10n.androidDownloadsPath
          : saved;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.savedTo(where))));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveFailed('$error'))),
      );
    }
  }

  Future<void> _shareAudio(BuildContext context, MeetingBundle data) async {
    final source = await RecordingExport.find(data.meeting);
    if (!context.mounted) return;
    if (source == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noRecordingToShare)));
      return;
    }

    final exportSource = await RecordingExport.preferredM4a(source);
    final name = RecordingExport.fileNameFor(data.meeting, exportSource);
    final dest = File(p.join((await getTemporaryDirectory()).path, name));
    if (await dest.exists()) {
      await dest.delete();
    }
    await exportSource.copy(dest.path);
    if (!context.mounted) return;

    final mime = p.extension(name).toLowerCase() == '.m4a'
        ? 'audio/mp4'
        : 'audio/wav';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(dest.path, mimeType: mime, name: name)],
        subject: data.meeting.title,
        sharePositionOrigin: _shareOrigin(context),
      ),
    );
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _MinutesTab extends StatelessWidget {
  const _MinutesTab({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final markdown = meeting.minutesMarkdown;
    final when = formatMeetingWhen(meeting);
    if (markdown == null || markdown.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                when,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(context.l10n.noMinutesBody),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          when,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        MarkdownBody(
          data: MinutesResult.readableMinutesMarkdown(markdown) ?? markdown,
        ),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes, required this.startedAt});

  final List<Note> notes;
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(child: Text(context.l10n.noLiveNotes));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: 48,
            child: Text(
              formatElapsedSince(note.createdAt, startedAt),
              style: elapsedTimeStyle(context),
            ),
          ),
          title: Text(note.text),
        );
      },
    );
  }
}

class _HintsTab extends StatelessWidget {
  const _HintsTab({required this.suggestions, required this.startedAt});

  final List<Suggestion> suggestions;
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Center(child: Text(context.l10n.noPrompts));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SuggestionCard(
            suggestion: suggestions[index],
            startedAt: startedAt,
          ),
        );
      },
    );
  }
}
