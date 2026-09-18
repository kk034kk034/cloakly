import 'package:cloakly/features/session/session_controller.dart';
import 'package:cloakly/widgets/meeting_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _noteController = TextEditingController();
  final Set<String> _selectedIds = {};
  var _showTranscript = true;
  var _showHints = true;
  var _showNotes = true;
  var _mobileIndex = 0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<_Pane> get _visiblePanes => [
    if (_showTranscript) _Pane.transcript,
    if (_showHints) _Pane.hints,
    if (_showNotes) _Pane.notes,
  ];

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
                _PaneToggle(
                  tooltip: '逐字稿',
                  icon: Icons.subtitles_outlined,
                  selectedIcon: Icons.subtitles,
                  selected: _showTranscript,
                  onPressed: () => _toggle(_Pane.transcript),
                ),
                _PaneToggle(
                  tooltip: '提示',
                  icon: Icons.lightbulb_outline,
                  selectedIcon: Icons.lightbulb,
                  selected: _showHints,
                  onPressed: () => _toggle(_Pane.hints),
                ),
                _PaneToggle(
                  tooltip: '筆記',
                  icon: Icons.edit_note,
                  selectedIcon: Icons.edit_note,
                  selected: _showNotes,
                  onPressed: () => _toggle(_Pane.notes),
                ),
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
                  child: wide
                      ? _wideLayout(session)
                      : _narrowLayout(session),
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

  Widget _wideLayout(SessionState session) {
    final sidebar = _showHints || _showNotes;
    return Row(
      children: [
        if (_showTranscript) ...[
          Expanded(flex: sidebar ? 3 : 1, child: _transcript(session)),
          if (sidebar) const VerticalDivider(width: 1),
        ],
        if (sidebar)
          Expanded(
            flex: _showTranscript ? 2 : 1,
            child: Column(
              children: [
                if (_showHints)
                  Expanded(
                    child: _HintPane(
                      session: session,
                      title: _showNotes ? '提示' : null,
                    ),
                  ),
                if (_showHints && _showNotes) const Divider(height: 1),
                if (_showNotes)
                  Expanded(
                    child: _NotesPane(
                      session: session,
                      controller: _noteController,
                      onSubmit: _submitNote,
                      title: _showHints ? '筆記' : null,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _narrowLayout(SessionState session) {
    final panes = _visiblePanes;
    final index = _mobileIndex.clamp(0, panes.length - 1);
    return Column(
      children: [
        if (panes.length > 1)
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                for (var i = 0; i < panes.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _mobileIndex = i),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2,
                              color: i == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          panes[i].label,
                          style: TextStyle(
                            fontWeight: i == index
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: _pane(panes[index], session)),
      ],
    );
  }

  Widget _pane(_Pane pane, SessionState session) {
    return switch (pane) {
      _Pane.transcript => _transcript(session),
      _Pane.hints => _HintPane(session: session),
      _Pane.notes => _NotesPane(
        session: session,
        controller: _noteController,
        onSubmit: _submitNote,
      ),
    };
  }

  void _toggle(_Pane pane) {
    final visible = _visiblePanes;
    final hiding = visible.contains(pane);
    if (hiding && visible.length == 1) return;
    setState(() {
      switch (pane) {
        case _Pane.transcript:
          _showTranscript = !_showTranscript;
        case _Pane.hints:
          _showHints = !_showHints;
        case _Pane.notes:
          _showNotes = !_showNotes;
      }
      final next = _visiblePanes;
      if (_mobileIndex >= next.length) _mobileIndex = next.length - 1;
    });
  }

  Widget _transcript(SessionState session) {
    final ids = _selectedIds.intersection(
      session.lines
          .where((line) => line.isFinal)
          .map((line) => line.id)
          .toSet(),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                ids.isEmpty
                    ? '點選發言，可多選後取得回覆建議。灰字與人物標籤仍可能更新。'
                    : '已選取 ${ids.length} 段發言',
              ),
              FilledButton.icon(
                onPressed:
                    ids.isEmpty ||
                        session.busyHint ||
                        session.phase == SessionPhase.wrappingUp
                    ? null
                    : () {
                        ref
                            .read(sessionControllerProvider.notifier)
                            .suggestForLines(ids);
                        setState(() {
                          _showHints = true;
                          final panes = [
                            if (_showTranscript) _Pane.transcript,
                            _Pane.hints,
                            if (_showNotes) _Pane.notes,
                          ];
                          _mobileIndex = panes.indexOf(_Pane.hints);
                        });
                      },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('建議回覆'),
              ),
              if (ids.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_selectedIds.clear),
                  child: const Text('清除選取'),
                ),
            ],
          ),
        ),
        Expanded(
          child: TranscriptList(
            lines: session.lines,
            followLatest: true,
            selectedIds: ids,
            onToggle: (id) => setState(() {
              if (!_selectedIds.add(id)) _selectedIds.remove(id);
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _submitNote() async {
    await ref
        .read(sessionControllerProvider.notifier)
        .addNote(_noteController.text);
    _noteController.clear();
  }

  Future<void> _finish() async {
    final id = await ref
        .read(sessionControllerProvider.notifier)
        .stopAndWrapUp();
    if (!mounted || id == null) return;
    context.go('/home/meeting/$id');
  }
}

enum _Pane {
  transcript('逐字稿'),
  hints('提示'),
  notes('筆記');

  const _Pane(this.label);
  final String label;
}

class _PaneToggle extends StatelessWidget {
  const _PaneToggle({
    required this.tooltip,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: selected ? '隱藏$tooltip' : '顯示$tooltip',
      isSelected: selected,
      onPressed: onPressed,
      icon: Icon(icon, color: scheme.onSurfaceVariant),
      selectedIcon: Icon(selectedIcon, color: scheme.primary),
    );
  }
}

class _NotesPane extends StatelessWidget {
  const _NotesPane({
    required this.session,
    required this.controller,
    required this.onSubmit,
    this.title,
  });

  final SessionState session;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null)
          _PaneHeader(title: title!),
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
                      leading: SizedBox(
                        width: 48,
                        child: Text(
                          formatElapsedSince(
                            note.createdAt,
                            session.startedAt,
                          ),
                          style: elapsedTimeStyle(context),
                        ),
                      ),
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
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) {
                      return KeyEventResult.ignored;
                    }
                    if (event.logicalKey != LogicalKeyboardKey.enter &&
                        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
                      return KeyEventResult.ignored;
                    }
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      _insertNewline(controller);
                      return KeyEventResult.handled;
                    }
                    onSubmit();
                    return KeyEventResult.handled;
                  },
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: '寫下現場筆記',
                      helperText: 'Enter 送出 · Shift+Enter 換行',
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
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

void _insertNewline(TextEditingController controller) {
  final value = controller.value;
  final start = value.selection.start;
  final end = value.selection.end;
  if (start < 0 || end < 0) return;
  final next = value.text.replaceRange(start, end, '\n');
  controller.value = value.copyWith(
    text: next,
    selection: TextSelection.collapsed(offset: start + 1),
    composing: TextRange.empty,
  );
}

class _HintPane extends StatelessWidget {
  const _HintPane({required this.session, this.title});

  final SessionState session;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null) _PaneHeader(title: title!),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SuggestionCard(
                suggestion: session.latestSuggestion,
                busy: session.busyHint,
                startedAt: session.startedAt,
              ),
              if (session.suggestions.length > 1) ...[
                const SizedBox(height: 16),
                Text('稍早的提示', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...session.suggestions.reversed
                    .skip(1)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SuggestionCard(
                          suggestion: item,
                          startedAt: session.startedAt,
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
