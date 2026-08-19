import 'dart:io';

import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/services/audio/recording_export.dart';
import 'package:cloakly/services/llm/llm_service.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:cloakly/state/providers.dart';
import 'package:cloakly/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(meetingBundleProvider(meetingId));
    return bundle.when(
      loading: () => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _goHome(context)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _goHome(context)),
        ),
        body: Center(child: Text('讀取失敗：$error')),
      ),
      data: (data) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => _goHome(context)),
            title: Text(data.meeting.title),
            actions: [
              IconButton(
                tooltip: '分享',
                onPressed: () => _showShareOptions(context, ref, data),
                icon: const Icon(Icons.ios_share),
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: '會議紀錄'),
                Tab(text: '逐字稿'),
                Tab(text: '筆記'),
                Tab(text: '提示'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _MinutesTab(meeting: data.meeting),
              TranscriptList(
                lines: data.lines,
                emptyLabel: '這場會議沒有逐字稿。',
              ),
              _NotesTab(notes: data.notes),
              _HintsTab(suggestions: data.suggestions),
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
      context.go('/');
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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notes_outlined),
                title: const Text('分享會議紀錄'),
                subtitle: const Text('文字，可貼到訊息或文件'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareText(context, data);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('儲存錄音到檔案'),
                subtitle: Text(
                  projectFolder == null
                      ? '沒有專案時會存到下載資料夾'
                      : '存到專案資料夾裡的「錄音」',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveAudio(context, data, projectFolder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('分享錄音檔'),
                subtitle: const Text('傳到 Drive 或 Line'),
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
    final projects = ref.read(projectsProvider).valueOrNull?.projects ?? const [];
    for (final project in projects) {
      if (project.id == id) return project.folderPath;
    }
    return null;
  }

  Future<void> _shareText(BuildContext context, MeetingBundle data) async {
    final buffer = StringBuffer()
      ..writeln('# ${data.meeting.title}')
      ..writeln()
      ..writeln(
        DateFormat('yyyy/MM/dd HH:mm').format(data.meeting.startedAt),
      )
      ..writeln()
      ..writeln(
        MinutesResult.readableMinutesMarkdown(
              data.meeting.minutesMarkdown ?? '',
            ) ??
            data.meeting.minutesMarkdown ??
            '（尚無會議紀錄）',
      )
      ..writeln()
      ..writeln('## 逐字稿')
      ..writeln();
    for (final line in data.lines) {
      buffer.writeln('${line.speaker}：${line.text}');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('這場會議沒有錄音檔可以儲存。')),
      );
      return;
    }
    try {
      final saved = await RecordingExport.saveToUserFolder(
        source: source,
        fileName: RecordingExport.fileNameFor(data.meeting, source),
        projectFolder: projectFolder,
      );
      if (!context.mounted) return;
      final inProject = projectFolder != null &&
          p.normalize(saved).startsWith(p.normalize(projectFolder));
      final where = inProject
          ? saved
          : Platform.isIOS
              ? '檔案 App → 我的 iPhone → Cloakly'
              : Platform.isAndroid
                  ? '下載 / Cloakly'
                  : saved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已存到 $where')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('儲存失敗：$error')),
      );
    }
  }

  Future<void> _shareAudio(BuildContext context, MeetingBundle data) async {
    final source = await RecordingExport.find(data.meeting);
    if (!context.mounted) return;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('這場會議沒有錄音檔可以分享。')),
      );
      return;
    }

    final name = RecordingExport.fileNameFor(data.meeting, source);
    final dest = File(p.join((await getTemporaryDirectory()).path, name));
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(dest.path);
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
    if (markdown == null || markdown.trim().isEmpty) {
      return const Center(child: Text('還沒有會議紀錄。'));
    }
    return Markdown(
      data: MinutesResult.readableMinutesMarkdown(markdown) ?? markdown,
      padding: const EdgeInsets.all(20),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Center(child: Text('這場會議沒有現場筆記。'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          leading: const Icon(Icons.edit_note),
          title: Text(note.text),
          subtitle: Text(DateFormat('HH:mm').format(note.createdAt)),
        );
      },
    );
  }
}

class _HintsTab extends StatelessWidget {
  const _HintsTab({required this.suggestions});

  final List<Suggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const Center(child: Text('這場會議沒有產生回答提示。'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SuggestionCard(suggestion: suggestions[index]),
        );
      },
    );
  }
}
