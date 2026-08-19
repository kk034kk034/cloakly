import 'package:cloakly/data/models/project_pack.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:cloakly/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('專案'),
        actions: [
          IconButton(
            tooltip: '新增專案資料夾',
            onPressed: () => ref.read(projectsProvider.notifier).addFolder(),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          if (projects.valueOrNull?.active != null)
            IconButton(
              tooltip: '重新索引',
              onPressed: () => ref.read(projectsProvider.notifier).reindex(),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('讀取失敗：$error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(projectsProvider.notifier).addFolder(),
                  child: const Text('新增專案資料夾'),
                ),
              ],
            ),
          ),
        ),
        data: (library) {
          if (library.projects.isEmpty) return const _EmptyProject();
          final pack = library.active;
          return _ProjectBody(
            library: library,
            pack: pack,
            onSelect: (id) => ref.read(projectsProvider.notifier).select(id),
            onAdd: () => ref.read(projectsProvider.notifier).addFolder(),
            onRemove: pack == null
                ? null
                : () => _confirmRemove(context, ref, pack),
            onToggle: pack == null
                ? (_, _) {}
                : (path, included) => ref
                    .read(projectsProvider.notifier)
                    .toggle(path, included, projectId: pack.id),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ProjectPack pack,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移除「${pack.name}」？'),
        content: const Text(
          '只會從 App 拿掉這個專案。資料夾本身不會刪。裡面的會議會移到「未分類」。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(meetingRepositoryProvider).unassignProject(pack.id);
    await ref.read(projectsProvider.notifier).remove(pack.id);
    await ref.read(meetingsProvider.notifier).refresh();
  }
}

class _EmptyProject extends ConsumerWidget {
  const _EmptyProject();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '新增專案資料夾',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '專案是選用的。每個資料夾是一個專案，裡面放 WBS、Spec、Issue；開會時提示會讀這些文件。也可以先不選，直接開始會議。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(projectsProvider.notifier).addFolder(),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('選定資料夾'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectBody extends StatelessWidget {
  const _ProjectBody({
    required this.library,
    required this.pack,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
    required this.onToggle,
  });

  final ProjectLibrary library;
  final ProjectPack? pack;
  final ValueChanged<String?> onSelect;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final void Function(String path, bool included) onToggle;

  @override
  Widget build(BuildContext context) {
    final grouped = <KnowledgeKind, List<KnowledgeDoc>>{};
    if (pack != null) {
      for (final kind in KnowledgeKind.values) {
        final docs = pack!.docs.where((doc) => doc.kind == kind).toList();
        if (docs.isNotEmpty) grouped[kind] = docs;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('未選擇'),
                  selected: pack == null,
                  onSelected: (_) => onSelect(null),
                ),
              ),
              for (final project in library.projects)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(project.name),
                    selected: project.id == pack?.id,
                    onSelected: (_) => onSelect(project.id),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('新增'),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (pack == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('未選擇專案', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '開始會議不會綁定資料夾，提示也不會讀專案文件。要依 Spec、WBS 給提示，再選上面的專案。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack!.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    pack!.folderPath,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '已納入 ${pack!.includedCount} 份文件，這個專案的會議提示會讀這些內容。',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: onRemove,
                        child: const Text('移除此專案'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('納入會議的文件', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '檔名含 spec、wbs、agenda、issue、承諾 的會自動勾選。可再手動調整。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                entry.key.label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...entry.value.map(
              (doc) => CheckboxListTile(
                value: doc.included,
                onChanged: (value) => onToggle(doc.relativePath, value ?? false),
                title: Text(doc.relativePath),
                subtitle:
                    Text('${(doc.byteLength / 1024).toStringAsFixed(1)} KB'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
