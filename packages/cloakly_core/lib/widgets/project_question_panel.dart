import 'package:cloakly_core/data/models/project_pack.dart';
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (widget.compactIntro) ...[
                Text(
                  '專案問答',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '直接在這頁查文件、進度與會議決議；每次提問獨立檢索。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                const Text('查找專案資料、決議與過去的承諾。每次提問獨立檢索；請寫出主題，不會沿用上一題。'),
                const SizedBox(height: 8),
                Text(
                  '每次提問會自動參考「${project.name}」資料夾與子資料夾的所有支援文件，以及此專案的全部會議、逐字稿與筆記。',
                ),
                const SizedBox(height: 8),
                const Text('相關片段會送至 AI 服務產生回答。問答僅保留於本頁，離開後清除。'),
              ],
              if (!configured)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('先設定 AI 服務，才能產生專案回答。'),
                  trailing: TextButton(
                    onPressed: () => context.push('/settings'),
                    child: const Text('設定'),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('整理目前專案狀況'),
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _question.text = '請整理目前專案進度、阻塞事項與待確認的承諾。';
                            });
                          },
                  ),
                  ActionChip(
                    label: const Text('哪次會議提到…'),
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _question.text = '哪次會議提到';
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
                  sizedImageBuilder: (_) => const Text('（圖片省略）'),
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
                      '本次 AI 用量：${turn.usage!.display}',
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
                        decoration: const InputDecoration(
                          hintText: '例如：哪次會議決定加入登入功能？',
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '送出問題',
                    onPressed:
                        _busy || !configured ? null : () => _ask(project),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Enter 送出，Shift+Enter 換行',
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
              '目前檢索資料不足以確認。請改用具體功能名稱或關鍵字，確認文件放在專案資料夾內、會議已歸入此專案。詢問整體進度時會自動優先整理近期資料。',
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
      if (mounted) setState(() => _error = '無法完成問答，問題已保留，可重試。$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSource(ProjectSource source) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                  '${source.meetingId == null ? '檔案修改時間（非決議日期）' : '會議時間'}：${source.date.toLocal()}',
                ),
                const SizedBox(height: 12),
                SelectableText(source.text),
                const SizedBox(height: 12),
                const Text('此處顯示提問時的來源片段。'),
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
              child: const Text('開啟會議'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
