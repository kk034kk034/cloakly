import 'package:cloakly/data/models/project_pack.dart';
import 'package:cloakly/state/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// 初始畫面：列出專案，點選後進入該專案的會議列表。
class ProjectPickerScreen extends ConsumerWidget {
  const ProjectPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloakly'),
        actions: [
          IconButton(
            tooltip: '全域設定',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProject(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('新增專案'),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('讀取失敗：$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _addProject(context, ref),
                  child: const Text('新增專案資料夾'),
                ),
              ],
            ),
          ),
        ),
        data: (library) => _ProjectList(
          library: library,
          onOpenProject: (id) => _enterProject(context, ref, id),
          onOpenUnassigned: () => _enterProject(context, ref, null),
          onAdd: () => _addProject(context, ref),
        ),
      ),
    );
  }

  Future<void> _enterProject(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
  ) async {
    await ref.read(projectsProvider.notifier).select(projectId);
    if (!context.mounted) return;
    context.go('/home');
  }

  Future<void> _addProject(BuildContext context, WidgetRef ref) async {
    await ref.read(projectsProvider.notifier).addFolder();
    if (!context.mounted) return;
    final active = ref.read(projectsProvider).valueOrNull?.active;
    if (active != null) context.go('/home');
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.library,
    required this.onOpenProject,
    required this.onOpenUnassigned,
    required this.onAdd,
  });

  final ProjectLibrary library;
  final ValueChanged<String> onOpenProject;
  final VoidCallback onOpenUnassigned;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = library.projects;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text('選擇專案', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          '每個資料夾是一個專案。選進去後可開始會議，提示會讀該專案的文件。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        if (projects.isEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text('還沒有專案', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '選定一個本機資料夾當專案，裡面放 Spec、WBS、Issue 等文件。',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('選定資料夾'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ] else
          for (final project in projects) ...[
            _ProjectCard(
              project: project,
              selected: project.id == library.activeId,
              onTap: () => onOpenProject(project.id),
            ),
            const SizedBox(height: 10),
          ],
        _UnassignedCard(onTap: onOpenUnassigned),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.selected,
    required this.onTap,
  });

  final ProjectPack project;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indexed = DateFormat('yyyy/MM/dd HH:mm').format(project.indexedAt);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.folder_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (selected)
                          Text(
                            '上次',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.folderPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '納入 ${project.includedCount} 份文件 · 索引 $indexed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnassignedCard extends StatelessWidget {
  const _UnassignedCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.inbox_outlined),
        ),
        title: const Text('未分類'),
        subtitle: const Text('沒有綁定專案的會議'),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
