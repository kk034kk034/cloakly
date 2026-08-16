import 'package:cloakly/data/models/project_pack.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('專案知識庫'),
        actions: [
          if (project.valueOrNull != null)
            IconButton(
              tooltip: '重新索引',
              onPressed: () => ref.read(projectProvider.notifier).reindex(),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: project.when(
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
                  onPressed: () => ref.read(projectProvider.notifier).pickFolder(),
                  child: const Text('改選資料夾'),
                ),
              ],
            ),
          ),
        ),
        data: (pack) {
          if (pack == null) return const _EmptyProject();
          return _ProjectBody(
            pack: pack,
            onPick: () => ref.read(projectProvider.notifier).pickFolder(),
            onClear: () => ref.read(projectProvider.notifier).clear(),
            onToggle: (path, included) =>
                ref.read(projectProvider.notifier).toggle(path, included),
          );
        },
      ),
    );
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
                '選定專案資料夾（可略過）',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '把 WBS、API Spec、議程、Issue、客戶承諾放進這個資料夾。開會被問到時，提示會依這些文件，而不是臨場編造。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(projectProvider.notifier).pickFolder(),
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
    required this.pack,
    required this.onPick,
    required this.onClear,
    required this.onToggle,
  });

  final ProjectPack pack;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final void Function(String path, bool included) onToggle;

  @override
  Widget build(BuildContext context) {
    final grouped = <KnowledgeKind, List<KnowledgeDoc>>{};
    for (final kind in KnowledgeKind.values) {
      final docs = pack.docs.where((doc) => doc.kind == kind).toList();
      if (docs.isNotEmpty) grouped[kind] = docs;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  pack.folderPath,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '已納入 ${pack.includedCount} 份文件，會議提示會讀這些內容。',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: onPick,
                      child: const Text('改選資料夾'),
                    ),
                    TextButton(
                      onPressed: onClear,
                      child: const Text('清除'),
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
              subtitle: Text('${(doc.byteLength / 1024).toStringAsFixed(1)} KB'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }
}
