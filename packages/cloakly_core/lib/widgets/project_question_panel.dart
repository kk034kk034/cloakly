import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProjectQuestionTurn {
  const ProjectQuestionTurn(
    this.question,
    this.answer,
    this.evidence,
    this.citations, {
    this.usage,
  });
  final String question;
  final String answer;
  final ProjectEvidence evidence;
  final Set<int> citations;
  final AiUsage? usage;
}

/// Inline project Q&A panel used on the project home page and the dedicated route.
class ProjectQuestionPanel extends ConsumerStatefulWidget {
  const ProjectQuestionPanel({
    super.key,
    required this.project,
    this.compactIntro = false,
    this.scrollController,
  });

  final ProjectPack project;
  final bool compactIntro;
  final ScrollController? scrollController;

  @override
  ConsumerState<ProjectQuestionPanel> createState() =>
      ProjectQuestionPanelState();
}

class ProjectQuestionPanelState extends ConsumerState<ProjectQuestionPanel> {
  final _question = TextEditingController();
  final _turns = <ProjectQuestionTurn>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(aiServiceProvider).isConfigured;
    final project = widget.project;
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (widget.compactIntro) ...[
                Text(
                  l10n.projectQa,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.qaCompactIntro,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Text(l10n.qaIntro),
                const SizedBox(height: 8),
                Text(l10n.qaScope(project.name)),
                const SizedBox(height: 8),
                Text(l10n.qaPrivacy),
              ],
              if (!configured)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.setupAiForAnswers),
                  trailing: TextButton(
                    onPressed: () => context.push('/settings'),
                    child: Text(l10n.settings),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: Text(l10n.summarizeStatus),
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _question.text = l10n.summarizeStatusQuery;
                            });
                          },
                  ),
                  ActionChip(
                    label: Text(l10n.whichMeeting),
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _question.text = l10n.whichMeetingQuery;
                            });
                          },
                  ),
                ],
              ),
              for (final turn in _turns) ...[
                const Divider(height: 32),
                Text(
                  turn.question,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                MarkdownBody(
                  data: turn.answer.replaceAllMapped(
                    RegExp(r'\[S(\d+)\]'),
                    (match) => '[S${match[1]}](source:${match[1]})',
                  ),
                  selectable: true,
                  onTapLink: (_, href, _) {
                    if (href == null || !href.startsWith('source:')) return;
                    final index = int.tryParse(href.substring(7));
                    if (index != null &&
                        index > 0 &&
                        index <= turn.evidence.sources.length) {
                      _showSource(turn.evidence.sources[index - 1]);
                    }
                  },
                  sizedImageBuilder: (_) => Text(l10n.imageOmitted),
                ),
                for (final index in turn.citations)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.source_outlined),
                    title: Text(
                      '[S${index + 1}] ${turn.evidence.sources[index].label}',
                    ),
                    onTap: () => _showSource(turn.evidence.sources[index]),
                  ),
                for (final warning in turn.evidence.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      warning,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (turn.usage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.turnUsage(turn.usage!.display),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent) {
                          return KeyEventResult.ignored;
                        }
                        final isEnter =
                            event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.numpadEnter;
                        if (!isEnter ||
                            HardwareKeyboard.instance.isShiftPressed) {
                          return KeyEventResult.ignored;
                        }
                        if (!_busy && configured) {
                          _ask(project);
                        }
                        return KeyEventResult.handled;
                      },
                      child: TextField(
                        controller: _question,
                        enabled: !_busy,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _busy || !configured
                            ? null
                            : (_) => _ask(project),
                        decoration: InputDecoration(
                          hintText: l10n.questionHint,
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: l10n.sendQuestion,
                    onPressed: _busy || !configured
                        ? null
                        : () => _ask(project),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.enterToSendShort,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _ask(ProjectPack pack) async {
    final question = _question.text.trim();
    if (question.isEmpty || _busy) return;
    final ai = ref.read(aiServiceProvider);
    final retrieval = ref.read(projectRetrievalProvider);
    final mode = ProjectRetrieval.modeFor(question, ProjectQuestionMode.search);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final evidence = await retrieval.retrieve(pack, question, mode: mode);
      if (!mounted) return;
      if (evidence.sources.isEmpty) {
        setState(
          () => _turns.add(
            ProjectQuestionTurn(
              question,
              context.l10n.insufficientEvidence,
              evidence,
              {},
            ),
          ),
        );
      } else {
        final result = await ai.answerProjectQuestion(
          question: question,
          evidence: evidence.context(pack.name, mode),
        );
        if (!mounted) return;
        final citations = evidence.citations(result.content);
        setState(
          () => _turns.add(
            ProjectQuestionTurn(
              question,
              result.content,
              evidence,
              citations,
              usage: result.usage,
            ),
          ),
        );
      }
      _question.clear();
      final scroll = widget.scrollController;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll != null && scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = context.l10n.qaFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSource(ProjectSource source) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(source.title),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(source.location),
                  Text(
                    l10n.sourceTime(
                      source.meetingId == null
                          ? l10n.fileModifiedTime
                          : l10n.meetingTime,
                      '${source.date.toLocal()}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(source.text),
                  const SizedBox(height: 12),
                  Text(l10n.sourceSnapshot),
                ],
              ),
            ),
          ),
          actions: [
            if (source.meetingId != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  ref.invalidate(meetingBundleProvider(source.meetingId!));
                  context.push(
                    '/home/meeting/${Uri.encodeComponent(source.meetingId!)}',
                  );
                },
                child: Text(l10n.openMeeting),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}
