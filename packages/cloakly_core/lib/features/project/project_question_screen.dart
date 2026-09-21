import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProjectQuestionScreen extends ConsumerStatefulWidget {
  const ProjectQuestionScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectQuestionScreen> createState() =>
      _ProjectQuestionScreenState();
}

class _Turn {
  const _Turn(
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

class _ProjectQuestionScreenState extends ConsumerState<ProjectQuestionScreen> {
  final _question = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _question.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(projectsProvider);
    ProjectPack? pack;
    for (final item in library.valueOrNull?.projects ?? <ProjectPack>[]) {
      if (item.id == widget.projectId) pack = item;
    }
    if (pack == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('專案問答')),
        body: Center(
          child: Text(library.isLoading ? '載入專案中…' : '找不到此專案，請回到專案列表。'),
        ),
      );
    }
    final project = pack;
    final configured = ref.watch(aiServiceProvider).isConfigured;
    return Scaffold(
      appBar: AppBar(title: Text('${project.name} · 專案問答')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('查找專案資料、決議與過去的承諾。每次提問獨立檢索；請寫出主題，不會沿用上一題。'),
                  const SizedBox(height: 8),
                  Text(
                    '每次提問會自動參考「${project.name}」資料夾與子資料夾的所有支援文件，以及此專案的全部會議、逐字稿與筆記。',
                  ),
                  const SizedBox(height: 8),
                  const Text('相關片段會送至 AI 服務產生回答。問答僅保留於本頁，離開後清除。'),
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
                      // Evidence is text; do not fetch model-supplied remote images.
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
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _question,
                          enabled: !_busy,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            hintText: '例如：哪次會議決定加入登入功能？',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: '送出問題',
                        onPressed: _busy || !configured
                            ? null
                            : () => _ask(project),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            _Turn(
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
            _Turn(
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
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
