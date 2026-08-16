import 'package:cloakly/data/models/models.dart';
import 'package:cloakly/state/providers.dart';
import 'package:cloakly/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class MeetingDetailScreen extends ConsumerWidget {
  const MeetingDetailScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(meetingBundleProvider(meetingId));
    return bundle.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('讀取失敗：$error')),
      ),
      data: (data) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(data.meeting.title),
            actions: [
              IconButton(
                tooltip: '分享會議紀錄',
                onPressed: () => _share(data),
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

  Future<void> _share(MeetingBundle data) async {
    final buffer = StringBuffer()
      ..writeln('# ${data.meeting.title}')
      ..writeln()
      ..writeln(
        DateFormat('yyyy/MM/dd HH:mm').format(data.meeting.startedAt),
      )
      ..writeln()
      ..writeln(data.meeting.minutesMarkdown ?? '（尚無會議紀錄）')
      ..writeln()
      ..writeln('## 逐字稿')
      ..writeln();
    for (final line in data.lines) {
      buffer.writeln('${line.speaker}：${line.text}');
    }
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
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
      data: markdown,
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
