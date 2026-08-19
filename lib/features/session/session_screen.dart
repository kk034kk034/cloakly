import 'package:cloakly/features/session/session_controller.dart';
import 'package:cloakly/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    final wrapping = session.phase == SessionPhase.wrappingUp;
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final projectName = session.projectName;

    return PopScope(
      canPop: !wrapping && session.phase != SessionPhase.live,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || wrapping) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('結束這場會議？'),
            content: const Text('結束後會依逐字稿與筆記產生會議紀錄。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('繼續'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('結束並整理'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          await _finish();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title.isEmpty ? '即時會議' : session.title),
                  Text(
                    '${formatDuration(session.elapsed)}'
                    '${projectName == null ? '' : ' · $projectName'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                if (session.phase == SessionPhase.paused)
                  IconButton(
                    tooltip: '繼續',
                    onPressed: controller.resume,
                    icon: const Icon(Icons.play_arrow),
                  )
                else
                  IconButton(
                    tooltip: '暫停',
                    onPressed: session.phase == SessionPhase.live
                        ? controller.pause
                        : null,
                    icon: const Icon(Icons.pause),
                  ),
                IconButton(
                  tooltip: '結束',
                  onPressed: wrapping ? null : _finish,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
              ],
              bottom: wide
                  ? null
                  : TabBar(
                      controller: _tabs,
                      tabs: const [
                        Tab(text: '逐字稿'),
                        Tab(text: '筆記'),
                        Tab(text: '提示'),
                      ],
                    ),
            ),
            body: Column(
              children: [
                if (session.error != null)
                  MaterialBanner(
                    content: Text(session.error!),
                    actions: const [SizedBox.shrink()],
                  ),
                if (session.isDemo)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('示範模式：正在播放模擬對話，不必對著麥克風說話。'),
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 980) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TranscriptList(lines: session.lines),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              flex: 2,
                              child: _NotesPane(
                                session: session,
                                controller: _noteController,
                                onSubmit: _submitNote,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              flex: 2,
                              child: _HintPane(
                                session: session,
                                onSuggest: controller.suggestNow,
                              ),
                            ),
                          ],
                        );
                      }
                      return TabBarView(
                        controller: _tabs,
                        children: [
                          TranscriptList(lines: session.lines),
                          _NotesPane(
                            session: session,
                            controller: _noteController,
                            onSubmit: _submitNote,
                          ),
                          _HintPane(
                            session: session,
                            onSuggest: controller.suggestNow,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (wrapping)
            const ModalBarrier(dismissible: false, color: Colors.black54),
          if (wrapping)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在整理會議紀錄與發言人…'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitNote() async {
    await ref
        .read(sessionControllerProvider.notifier)
        .addNote(_noteController.text);
    _noteController.clear();
  }

  Future<void> _finish() async {
    final id =
        await ref.read(sessionControllerProvider.notifier).stopAndWrapUp();
    if (!mounted || id == null) return;
    context.go('/meeting/$id');
  }
}

class _NotesPane extends StatelessWidget {
  const _NotesPane({
    required this.session,
    required this.controller,
    required this.onSubmit,
  });

  final SessionState session;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: session.notes.isEmpty
              ? Center(
                  child: Text(
                    '邊聽邊記重點，結束後會一併寫進會議紀錄。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: session.notes.length,
                  itemBuilder: (context, index) {
                    final note = session.notes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_note),
                      title: Text(note.text),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: '寫下現場筆記'),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSubmit,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HintPane extends StatelessWidget {
  const _HintPane({
    required this.session,
    required this.onSuggest,
  });

  final SessionState session;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: onSuggest,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('給我提示'),
        ),
        const SizedBox(height: 12),
        SuggestionCard(
          suggestion: session.latestSuggestion,
          busy: session.busyHint,
        ),
        if (session.suggestions.length > 1) ...[
          const SizedBox(height: 16),
          Text('稍早的提示', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...session.suggestions.reversed.skip(1).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SuggestionCard(suggestion: item),
                ),
              ),
        ],
      ],
    );
  }
}
