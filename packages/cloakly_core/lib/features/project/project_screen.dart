import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 專案內設定：資料來源說明、會議背景／詞彙，以及刪除專案。
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(projectsProvider).valueOrNull;
    final pack = library?.active;
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('專案資料來源', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(pack.folderPath),
            subtitle: const Text(
              '每次專案問答會自動搜尋資料夾與子資料夾內所有支援文件，以及此專案的全部會議紀錄。單次掃描安全上限為 2,000 份文件。',
            ),
          ),
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
  final count =
      (await ref.read(meetingRepositoryProvider).list(projectId: pack.id))
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
