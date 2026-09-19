import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 專案內設定：納入會議的文件、此專案的背景／詞彙，以及刪除專案。
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = ref.watch(projectsProvider).valueOrNull?.active;
    return Scaffold(
      appBar: AppBar(title: const Text('專案設定')),
      body: pack == null
          ? const Center(child: Text('目前在未分類，沒有專案可設定。'))
          : _ProjectSettingsBody(pack: pack),
    );
  }
}

class _ProjectSettingsBody extends ConsumerWidget {
  const _ProjectSettingsBody({required this.pack});

  final ProjectPack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(projectsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _FileSection(
          pack: pack,
          onToggle: (path, included) =>
              notifier.toggle(path, included, projectId: pack.id),
          onSetAll: (included) =>
              notifier.setAllIncluded(included, projectId: pack.id),
          onReindex: () => notifier.reindex(),
        ),
        const SizedBox(height: 24),
        _ProjectDetailsSection(key: ValueKey(pack.id), pack: pack),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmDeleteProject(context, ref, pack),
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          label: Text(
            '刪除此專案',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

class _FileSection extends StatelessWidget {
  const _FileSection({
    required this.pack,
    required this.onToggle,
    required this.onSetAll,
    required this.onReindex,
  });

  final ProjectPack pack;
  final VoidCallback onReindex;
  final ValueChanged<bool> onSetAll;
  final void Function(String path, bool included) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <KnowledgeKind, List<KnowledgeDoc>>{};
    for (final kind in KnowledgeKind.values) {
      final docs = pack.docs.where((doc) => doc.kind == kind).toList();
      if (docs.isNotEmpty) grouped[kind] = docs;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pack.folderPath, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('納入會議的文件', style: theme.textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: onReindex,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新掃描'),
            ),
          ],
        ),
        Text(
          pack.docs.isEmpty
              ? '先掃描資料夾。找到文字檔後，就可以勾選要帶進會議提示的幾份；不會整包都讀。'
              : '已勾選 ${pack.includedCount} / ${pack.docs.length} 份。點每一列即可勾選或取消；提示只讀有勾的檔案。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (pack.docs.isNotEmpty)
          Row(
            children: [
              TextButton(
                onPressed: () => onSetAll(true),
                child: const Text('全選'),
              ),
              TextButton(
                onPressed: () => onSetAll(false),
                child: const Text('全不選'),
              ),
            ],
          ),
        const SizedBox(height: 8),
        if (pack.docs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('還沒掃到可勾選的文字檔。', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    '支援 .md .txt .json .yaml .csv 等；略過 node_modules、.git。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onReindex,
                    child: const Text('掃描資料夾'),
                  ),
                ],
              ),
            ),
          )
        else
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(entry.key.label, style: theme.textTheme.labelLarge),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    CheckboxListTile(
                      value: entry.value[i].included,
                      onChanged: (value) => onToggle(
                        entry.value[i].relativePath,
                        value ?? false,
                      ),
                      title: Text(entry.value[i].relativePath),
                      subtitle: Text(
                        '${(entry.value[i].byteLength / 1024).toStringAsFixed(1)} KB',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _ProjectDetailsSection extends ConsumerStatefulWidget {
  const _ProjectDetailsSection({super.key, required this.pack});
  final ProjectPack pack;

  @override
  ConsumerState<_ProjectDetailsSection> createState() =>
      _ProjectDetailsSectionState();
}

class _ProjectDetailsSectionState
    extends ConsumerState<_ProjectDetailsSection> {
  late final _background = TextEditingController(
    text: widget.pack.personalContext,
  );
  late final _terms = TextEditingController(
    text: widget.pack.transcriptionTerms,
  );
  bool _saving = false;

  @override
  void dispose() {
    _background.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('此專案的會議提示', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _background,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: '我在此專案的角色與背景（選填）',
            hintText: '例如：博士生，研究主題是語音辨識。',
            helperText: '只提供給此專案的 AI 建議與會議紀錄。',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _terms,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: '辨識詞彙提示（選填）',
            hintText: '例如：陳教授、Cloakly、LoRA；以逗號或換行分隔',
            helperText: '協助辨識此專案少見的人名與術語。',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '儲存中…' : '儲存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(projectsProvider.notifier)
          .updateDetails(
            widget.pack.id,
            _background.text.trim(),
            _terms.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已儲存此專案設定')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('儲存失敗：$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<void> _confirmDeleteProject(
  BuildContext context,
  WidgetRef ref,
  ProjectPack pack,
) async {
  final count = (await ref
          .read(meetingRepositoryProvider)
          .list(projectId: pack.id))
      .length;
  if (!context.mounted) return;
  var savedAudio = count == 0;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('刪除「${pack.name}」？'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? '會從 App 移除此專案。電腦上的資料夾本身不會刪。'
                      : '此專案底下的 $count 場會議紀錄、逐字稿、筆記、提示，以及尚未另存的錄音都會消失，無法復原。\n\n'
                          '資料夾本身不會刪。若還需要錄音，請先到各場會議另存檔案。',
                ),
                if (count > 0) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: savedAudio,
                    onChanged: (value) =>
                        setState(() => savedAudio = value ?? false),
                    title: const Text('我已另存需要保留的錄音，確定刪除這些紀錄'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: savedAudio
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('刪除專案'),
              ),
            ],
          );
        },
      );
    },
  );
  if (ok != true) return;
  await ref.read(meetingRepositoryProvider).deleteByProject(pack.id);
  await ref.read(projectsProvider.notifier).remove(pack.id);
  await ref.read(meetingsProvider.notifier).refresh();
  if (!context.mounted) return;
  context.go('/');
}
