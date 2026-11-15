import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/features/settings/theme_mode_setting.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/utils/task_date_filter.dart';
import 'package:cloakly_core/widgets/project_task_board.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloakly'),
        actions: [
          const ThemeModeToggleButton(),
          IconButton(
            tooltip: l10n.globalSettings,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProject(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: Text(l10n.addProject),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.loadFailed('$error'), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _addProject(context, ref),
                  child: Text(l10n.addProjectFolder),
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
          onOpenPlan: (projectId) async {
            await ref.read(projectsProvider.notifier).select(projectId);
            if (!context.mounted) return;
            context.go('/home');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.push(
                  '/home/project/${Uri.encodeComponent(projectId)}/plan',
                );
              }
            });
          },
          onStatusChanged: (projectId, task, status) async {
            final libraryNow = ref.read(projectsProvider).valueOrNull;
            if (libraryNow == null) return;
            ProjectPack? pack;
            for (final project in libraryNow.projects) {
              if (project.id == projectId) pack = project;
            }
            if (pack == null) return;
            final next = [
              for (final item in pack.tasks)
                item.id == task.id
                    ? item.copyWith(
                        status: status,
                        progress: progressForStatusChange(
                          status,
                          task.progress,
                        ),
                        confirmed: true,
                      )
                    : item,
            ];
            await ref
                .read(projectsProvider.notifier)
                .updateTasks(projectId, next);
          },
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
    required this.onOpenPlan,
    required this.onStatusChanged,
  });

  final ProjectLibrary library;
  final ValueChanged<String> onOpenProject;
  final VoidCallback onOpenUnassigned;
  final VoidCallback onAdd;
  final ValueChanged<String> onOpenPlan;
  final Future<void> Function(
    String projectId,
    ProjectTask task,
    ProjectTaskStatus status,
  )
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final projects = library.projects;
    final allActiveItems = <BoardTaskItem>[
      for (final project in projects)
        for (final task in project.withNormalizedPhases().activePhaseTasks)
          BoardTaskItem(
            task: task,
            projectId: project.id,
            projectName: l10n.projectPhaseLine(
              project.name,
              project.withNormalizedPhases().activePhase?.name ??
                  l10n.phaseWord,
            ),
          ),
    ];
    final todayRange = todayDateRange();
    final boardItems = [
      for (final item in allActiveItems)
        if (taskMatchesBoardFocus(
          item.task,
          range: todayRange,
          includeOverdue: true,
        ))
          item,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (projects.isNotEmpty) ...[
          Text(l10n.allProjectBoards, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            l10n.boardFilterHelp,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (allActiveItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noTasksOnBoards),
              ),
            )
          else if (boardItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.nothingDueToday),
              ),
            )
          else
            ProjectTaskBoard(
              items: boardItems,
              onEdit: (item) => onOpenPlan(item.projectId),
              onStatusChanged: (item, status) =>
                  onStatusChanged(item.projectId, item.task, status),
            ),
          const SizedBox(height: 28),
        ],
        Text(l10n.chooseProject, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          l10n.chooseProjectHelp,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
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
                  Text(l10n.noProjects, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noProjectsHelp,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(l10n.chooseFolder),
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
    final l10n = context.l10n;
    final indexed = DateFormat('yyyy/MM/dd HH:mm').format(project.indexedAt);
    final normalized = project.withNormalizedPhases();
    final activePhase = normalized.activePhase;
    final activeCount = normalized.activePhaseTasks.length;
    final archivedCount = normalized.archivedPhases.length;

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
                            l10n.lastIndexed,
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
                      [
                        l10n.includedDocs(project.includedCount),
                        if (activePhase != null)
                          l10n.activePhaseCount(activePhase.name, activeCount),
                        if (archivedCount > 0)
                          l10n.archivedPhaseCount(archivedCount),
                        l10n.indexedAt(indexed),
                      ].join(' · '),
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
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.inbox_outlined),
        ),
        title: Text(l10n.unassigned),
        subtitle: Text(l10n.unassignedSubtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
