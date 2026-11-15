import 'dart:math' as math;

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/l10n/cloakly_locale.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_core/utils/task_date_filter.dart';
import 'package:cloakly_core/widgets/project_task_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum _PlanView { gantt, board }

enum _BoardDateFilter { all, today, custom }

class ProjectPlanScreen extends ConsumerStatefulWidget {
  const ProjectPlanScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectPlanScreen> createState() => _ProjectPlanScreenState();
}

class _ProjectPlanScreenState extends ConsumerState<ProjectPlanScreen> {
  bool _suggesting = false;
  String? _suggestError;
  AiUsage? _lastSuggestUsage;

  /// When set, board temporarily shows an archived phase (read-only archive view).
  String? _peekArchivedPhaseId;

  _PlanView _planView = _PlanView.gantt;
  _BoardDateFilter _boardDateFilter = _BoardDateFilter.all;
  DateTimeRange? _customBoardRange;

  @override
  Widget build(BuildContext context) {
    final projects =
        ref.watch(projectsProvider).valueOrNull?.projects ?? const [];
    ProjectPack? pack;
    for (final project in projects) {
      if (project.id == widget.projectId) pack = project;
    }
    if (pack == null) {
      return Scaffold(body: Center(child: Text(context.l10n.projectMissing)));
    }
    final l10n = context.l10n;
    final project = pack.withNormalizedPhases();
    final configured = ref.watch(aiServiceProvider).isConfigured;
    ProjectPhase? viewingPhase;
    if (_peekArchivedPhaseId != null) {
      for (final phase in project.phases) {
        if (phase.id == _peekArchivedPhaseId) viewingPhase = phase;
      }
    } else {
      viewingPhase = project.activePhase;
    }
    final boardTasks = viewingPhase == null
        ? const <ProjectTask>[]
        : project.tasksInPhase(viewingPhase.id);
    final peekingArchive = _peekArchivedPhaseId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleTitle(project.name)),
        actions: [
          IconButton(
            tooltip: configured
                ? l10n.aiSuggestSchedule
                : l10n.aiSuggestNeedsSetup,
            onPressed: _suggesting || !configured || peekingArchive
                ? (configured || peekingArchive
                      ? null
                      : () => context.push('/settings'))
                : () => _suggestSchedule(project),
            icon: _suggesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      floatingActionButton: peekingArchive
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editTask(project, phaseId: viewingPhase?.id),
              icon: const Icon(Icons.add),
              label: Text(l10n.addMainItem),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(l10n.phaseBoardHelp),
          if (!configured)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.setupAiForSchedule),
              trailing: TextButton(
                onPressed: () => context.push('/settings'),
                child: Text(l10n.settings),
              ),
            ),
          if (_lastSuggestUsage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.lastSuggestUsage(_lastSuggestUsage!.display),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (_suggestError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _suggestError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          _PhaseBar(
            project: project,
            viewingPhaseId: viewingPhase?.id,
            peekingArchive: peekingArchive,
            onSelectOpen: (phaseId) async {
              setState(() => _peekArchivedPhaseId = null);
              await ref
                  .read(projectsProvider.notifier)
                  .updatePlan(project.id, activePhaseId: phaseId);
            },
            onAddPhase: () => _addPhase(project),
            onRenamePhase: viewingPhase == null || peekingArchive
                ? null
                : () => _renamePhase(project, viewingPhase!),
            onArchivePhase: viewingPhase == null || peekingArchive
                ? null
                : () => _archivePhase(project, viewingPhase!.id, confirm: true),
            onPeekArchived: (phaseId) =>
                setState(() => _peekArchivedPhaseId = phaseId),
            onUnarchive: (phase) => _unarchivePhase(project, phase),
            onExitPeek: () => setState(() => _peekArchivedPhaseId = null),
          ),
          const SizedBox(height: 16),
          if (viewingPhase == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.noPhaseCreateFirst),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _addPhase(project),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addPhase),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._phaseBody(
              context,
              project: project,
              phase: viewingPhase,
              boardTasks: boardTasks,
              peekingArchive: peekingArchive,
            ),
        ],
      ),
    );
  }

  List<Widget> _phaseBody(
    BuildContext context, {
    required ProjectPack project,
    required ProjectPhase phase,
    required List<ProjectTask> boardTasks,
    required bool peekingArchive,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final filteredBoardTasks = _filteredBoardTasks(boardTasks);
    return [
      if (peekingArchive)
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(l10n.viewingArchived(phase.name)),
            subtitle: Text(l10n.archivedNotOnBoard),
            trailing: TextButton(
              onPressed: () => setState(() => _peekArchivedPhaseId = null),
              child: Text(l10n.backToCurrentPhase),
            ),
          ),
        ),
      if (!peekingArchive && project.isPhaseComplete(phase.id))
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(l10n.phaseAllDone),
            subtitle: Text(l10n.archivePhaseHint),
            trailing: FilledButton(
              onPressed: () => _archivePhase(project, phase.id, confirm: false),
              child: Text(l10n.archivePhase),
            ),
          ),
        ),
      const SizedBox(height: 8),
      SegmentedButton<_PlanView>(
        segments: [
          ButtonSegment(
            value: _PlanView.gantt,
            label: Text(l10n.gantt),
            icon: const Icon(Icons.view_timeline_outlined),
          ),
          ButtonSegment(
            value: _PlanView.board,
            label: Text(l10n.kanban),
            icon: const Icon(Icons.view_kanban_outlined),
          ),
        ],
        selected: {_planView},
        onSelectionChanged: (next) {
          setState(() => _planView = next.first);
        },
      ),
      const SizedBox(height: 12),
      if (boardTasks.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.phaseEmptyAdd),
                if (!peekingArchive) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _editTask(project, phaseId: phase.id),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addFirstMainItem),
                  ),
                ],
              ],
            ),
          ),
        )
      else if (_planView == _PlanView.gantt) ...[
        Text(
          l10n.progressOverview(phase.name),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _ProgressOverview(
          project: project,
          tasks: boardTasks,
          readOnly: peekingArchive,
          onEdit: (task) => _editTask(project, task: task),
          onAddChild: (parent) =>
              _editTask(project, phaseId: phase.id, parentId: parent.id),
          onDelete: (task) => _deleteTask(project, task),
          onMove: (task, delta) => _moveTask(project, task, delta),
        ),
      ] else ...[
        Text(l10n.workBoard(phase.name), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _BoardDateFilterBar(
          filter: _boardDateFilter,
          customRange: _customBoardRange,
          onFilterChanged: _setBoardDateFilter,
          onPickCustomRange: () => _pickCustomBoardRange(context),
        ),
        const SizedBox(height: 12),
        if (filteredBoardTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _boardDateFilter == _BoardDateFilter.all
                    ? l10n.phaseEmptyShort
                    : l10n.filterEmpty,
              ),
            ),
          )
        else
          ProjectTaskBoard(
            items: [
              for (final task in filteredBoardTasks)
                BoardTaskItem(task: task, projectId: project.id),
            ],
            onEdit: peekingArchive
                ? (_) {}
                : (item) => _editTask(project, task: item.task),
            onStatusChanged: peekingArchive
                ? (_, _) async {}
                : (item, status) => _changeStatus(project, item.task, status),
          ),
      ],
    ];
  }

  List<ProjectTask> _filteredBoardTasks(List<ProjectTask> tasks) {
    final range = switch (_boardDateFilter) {
      _BoardDateFilter.all => null,
      _BoardDateFilter.today => todayDateRange(),
      _BoardDateFilter.custom => _customBoardRange,
    };
    if (_boardDateFilter == _BoardDateFilter.custom && range == null) {
      return tasks;
    }
    return [
      for (final task in tasks)
        if (taskMatchesBoardFocus(
          task,
          range: range,
          includeOverdue: _boardDateFilter == _BoardDateFilter.today,
        ))
          task,
    ];
  }

  void _setBoardDateFilter(_BoardDateFilter filter) {
    setState(() => _boardDateFilter = filter);
  }

  Future<void> _pickCustomBoardRange(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        _customBoardRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(
            now.year,
            now.month,
            now.day,
          ).add(const Duration(days: 6)),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customBoardRange = picked;
      _boardDateFilter = _BoardDateFilter.custom;
    });
  }

  Future<void> _changeStatus(
    ProjectPack pack,
    ProjectTask task,
    ProjectTaskStatus status,
  ) async {
    final nextProgress = progressForStatusChange(status, task.progress);
    final next = [
      for (final item in pack.tasks)
        item.id == task.id
            ? item.copyWith(
                status: status,
                progress: nextProgress,
                confirmed: true,
              )
            : item,
    ];
    await ref.read(projectsProvider.notifier).updateTasks(pack.id, next);
    final phaseId = task.phaseId;
    if (phaseId == null || !mounted) return;
    final updated = pack.copyWith(tasks: next);
    if (!updated.isPhaseComplete(phaseId)) return;
    final archive = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.phaseCompleteTitle),
          content: Text(l10n.archiveNowBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.later),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.archive),
            ),
          ],
        );
      },
    );
    if (archive == true && mounted) {
      await _archivePhase(updated, phaseId, confirm: false);
    }
  }

  Future<void> _addPhase(ProjectPack pack) async {
    final nameController = TextEditingController(text: pack.nextPhaseName());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.addPhase),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.phaseName,
              hintText: l10n.phaseNameHint,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final phase = ProjectPhase(
      id: const Uuid().v4(),
      name: name,
      sortOrder: pack.phases.isEmpty
          ? 0
          : pack.phases.map((item) => item.sortOrder).reduce(math.max) + 1,
    );
    await ref
        .read(projectsProvider.notifier)
        .updatePlan(
          pack.id,
          phases: [...pack.phases, phase],
          activePhaseId: phase.id,
        );
    if (mounted) setState(() => _peekArchivedPhaseId = null);
  }

  Future<void> _renamePhase(ProjectPack pack, ProjectPhase phase) async {
    final nameController = TextEditingController(text: phase.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.renamePhase),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.phaseName),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    await ref
        .read(projectsProvider.notifier)
        .updatePlan(
          pack.id,
          phases: [
            for (final item in pack.phases)
              item.id == phase.id ? item.copyWith(name: name) : item,
          ],
        );
  }

  Future<void> _archivePhase(
    ProjectPack pack,
    String phaseId, {
    required bool confirm,
  }) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.archiveThisPhaseTitle),
            content: Text(l10n.archiveThisPhaseBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.archive),
              ),
            ],
          );
        },
      );
      if (ok != true || !mounted) return;
    }
    final nextPhases = [
      for (final phase in pack.phases)
        phase.id == phaseId
            ? phase.copyWith(archived: true, archivedAt: DateTime.now())
            : phase,
    ];
    final remaining = nextPhases.where((phase) => !phase.archived).toList();
    String? nextActive = remaining.isEmpty ? null : remaining.first.id;
    var phases = nextPhases;
    if (remaining.isEmpty) {
      final fresh = ProjectPhase(
        id: const Uuid().v4(),
        name: pack.copyWith(phases: nextPhases).nextPhaseName(),
        sortOrder: nextPhases.isEmpty
            ? 0
            : nextPhases.map((item) => item.sortOrder).reduce(math.max) + 1,
      );
      phases = [...nextPhases, fresh];
      nextActive = fresh.id;
    }
    await ref
        .read(projectsProvider.notifier)
        .updatePlan(pack.id, phases: phases, activePhaseId: nextActive);
    if (mounted) {
      setState(() => _peekArchivedPhaseId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining.isEmpty
                ? context.l10n.archivedAndOpenedNext
                : context.l10n.phaseArchived,
          ),
        ),
      );
    }
  }

  Future<void> _unarchivePhase(ProjectPack pack, ProjectPhase phase) async {
    await ref
        .read(projectsProvider.notifier)
        .updatePlan(
          pack.id,
          phases: [
            for (final item in pack.phases)
              item.id == phase.id
                  ? item.copyWith(archived: false, clearArchivedAt: true)
                  : item,
          ],
          activePhaseId: phase.id,
        );
    if (mounted) setState(() => _peekArchivedPhaseId = null);
  }

  Future<void> _suggestSchedule(ProjectPack pack) async {
    if (_suggesting) return;
    final ai = ref.read(aiServiceProvider);
    final retrieval = ref.read(projectRetrievalProvider);
    final l10n = context.l10n;
    final question = l10n.planQuestion;
    setState(() {
      _suggesting = true;
      _suggestError = null;
    });
    try {
      final evidence = await retrieval.retrieve(
        pack,
        question,
        mode: ProjectQuestionMode.overview,
      );
      if (!mounted) return;
      if (evidence.sources.isEmpty) {
        setState(() => _suggestError = l10n.notEnoughPlanEvidence);
        return;
      }
      final result = await ai.generateProjectPlan(
        evidence: evidence.context(pack.name, ProjectQuestionMode.overview),
      );
      if (!mounted) return;
      setState(() => _lastSuggestUsage = result.usage);
      if (result.tasks.isEmpty) {
        setState(() => _suggestError = l10n.noTrackableWork);
        return;
      }
      final existingTitles = {
        for (final task in pack.tasks) task.title.trim().toLowerCase(),
      };
      final selected = await _reviewSuggestions(
        drafts: result.tasks,
        sources: evidence.sources,
        existingTitles: existingTitles,
        usage: result.usage,
        fallbackPhaseName: pack.activePhase?.name ?? pack.nextPhaseName(),
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      await _applySuggestions(pack, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addedSuggestions(selected.length))),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _suggestError = l10n.planSuggestFailed('$error'));
      }
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  Future<void> _applySuggestions(
    ProjectPack pack,
    List<_AcceptedSuggestion> selected,
  ) async {
    final phases = [...pack.phases];
    final phaseByName = <String, ProjectPhase>{
      for (final phase in phases)
        if (!phase.archived) phase.name.trim().toLowerCase(): phase,
    };
    var sortOrder = phases.isEmpty
        ? 0
        : phases.map((item) => item.sortOrder).reduce(math.max) + 1;
    String resolvePhaseId(String name) {
      final key = name.trim().toLowerCase();
      final existing = phaseByName[key];
      if (existing != null) return existing.id;
      final created = ProjectPhase(
        id: const Uuid().v4(),
        name: name.trim().isEmpty ? pack.nextPhaseName() : name.trim(),
        sortOrder: sortOrder++,
      );
      phases.add(created);
      phaseByName[created.name.toLowerCase()] = created;
      return created.id;
    }

    final fallback = pack.activePhase?.name ?? pack.nextPhaseName();
    final nextTaskOrder = <String, int>{};
    int allocateSortOrder(String phaseId) {
      final current =
          nextTaskOrder[phaseId] ??
          pack.copyWith(phases: phases).nextSortOrder(phaseId: phaseId);
      nextTaskOrder[phaseId] = current + 1;
      return current;
    }

    final tasks = [
      ...pack.tasks,
      for (final item in selected)
        () {
          final phaseId = resolvePhaseId(
            item.draft.phaseName.isEmpty ? fallback : item.draft.phaseName,
          );
          return ProjectTask(
            id: const Uuid().v4(),
            title: item.draft.title,
            status: projectTaskStatusFromName(item.draft.status),
            updatedAt: DateTime.now(),
            phaseId: phaseId,
            progress: projectTaskStatusFromName(
              item.draft.status,
            ).defaultProgress,
            sortOrder: allocateSortOrder(phaseId),
            startDate: item.draft.startDate,
            endDate: item.draft.endDate,
            owner: item.draft.owner,
            sources: item.sourceLabels,
            confirmed: false,
          );
        }(),
    ];
    final preferred =
        pack.activePhase?.id ??
        (phases.where((phase) => !phase.archived).isEmpty
            ? null
            : phases.where((phase) => !phase.archived).first.id);
    await ref
        .read(projectsProvider.notifier)
        .updatePlan(
          pack.id,
          phases: phases,
          tasks: tasks,
          activePhaseId: preferred,
        );
  }

  Future<List<_AcceptedSuggestion>?> _reviewSuggestions({
    required List<ProjectPlanDraft> drafts,
    required List<ProjectSource> sources,
    required Set<String> existingTitles,
    required String fallbackPhaseName,
    AiUsage? usage,
  }) async {
    final candidates = <_SuggestCandidate>[
      for (final draft in drafts)
        _SuggestCandidate(
          draft: draft,
          selected: !existingTitles.contains(draft.title.trim().toLowerCase()),
          duplicate: existingTitles.contains(draft.title.trim().toLowerCase()),
          sourceLabels: [
            for (final id in draft.sourceIds)
              if (RegExp(r'^S(\d+)$').firstMatch(id) case final match?)
                if (int.tryParse(match.group(1)!) case final index?
                    when index > 0 && index <= sources.length)
                  sources[index - 1].label,
          ],
        ),
    ];
    if (candidates.every((item) => !item.selected)) {
      for (final item in candidates) {
        item.selected = true;
      }
    }
    return showModalBottomSheet<List<_AcceptedSuggestion>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = context.l10n;
            final selectedCount = candidates
                .where((item) => item.selected)
                .length;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.suggestedPlanTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.suggestedPlanHelp,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (usage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        usage.display,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = candidates[index];
                          final draft = item.draft;
                          final phaseLabel = draft.phaseName.isEmpty
                              ? fallbackPhaseName
                              : draft.phaseName;
                          final date = ProjectTaskBoard.dateText(
                            ProjectTask(
                              id: 'preview',
                              title: draft.title,
                              status: projectTaskStatusFromName(draft.status),
                              updatedAt: DateTime.now(),
                              startDate: draft.startDate,
                              endDate: draft.endDate,
                              owner: draft.owner,
                            ),
                          );
                          return CheckboxListTile(
                            value: item.selected,
                            onChanged: (value) => setSheetState(() {
                              item.selected = value ?? false;
                            }),
                            title: Text(draft.title),
                            subtitle: Text(
                              [
                                phaseLabel,
                                projectTaskStatusFromName(draft.status).label,
                                if (draft.owner.isNotEmpty) draft.owner,
                                date,
                                if (item.duplicate) l10n.duplicateTask,
                                if (item.sourceLabels.isNotEmpty)
                                  item.sourceLabels.join(', '),
                              ].join(' · '),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: selectedCount == 0
                              ? null
                              : () {
                                  Navigator.pop(context, [
                                    for (final item in candidates)
                                      if (item.selected)
                                        _AcceptedSuggestion(
                                          draft: item.draft,
                                          sourceLabels: item.sourceLabels,
                                        ),
                                  ]);
                                },
                          child: Text(l10n.addSelected(selectedCount)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _moveTask(ProjectPack pack, ProjectTask task, int delta) async {
    final next = pack.reorderedTasks(task, delta);
    if (next == null) return;
    await ref.read(projectsProvider.notifier).updateTasks(pack.id, next);
  }

  Future<void> _deleteTask(ProjectPack pack, ProjectTask task) async {
    final descendantCount = pack.descendantsOf(task.id).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.deleteTaskTitle),
          content: Text(
            descendantCount > 0
                ? l10n.deleteTaskWithChildren(task.title, descendantCount)
                : l10n.deleteTaskConfirm(task.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final removeIds = {
      task.id,
      for (final child in pack.descendantsOf(task.id)) child.id,
    };
    final next = [
      for (final item in pack.tasks)
        if (!removeIds.contains(item.id)) item,
    ];
    await ref.read(projectsProvider.notifier).updateTasks(pack.id, next);
  }

  Future<void> _editTask(
    ProjectPack pack, {
    ProjectTask? task,
    String? phaseId,
    String? parentId,
  }) async {
    final title = TextEditingController(text: task?.title ?? '');
    final owner = TextEditingController(text: task?.owner ?? '');
    final notes = TextEditingController(text: task?.notes ?? '');
    DateTime? start = task?.startDate;
    DateTime? end = task?.endDate;
    var status = task?.status ?? ProjectTaskStatus.planned;
    var progress = task?.progress ?? status.defaultProgress;
    var selectedPhaseId = task?.phaseId ?? phaseId ?? pack.activePhase?.id;
    final resolvedParentId = task?.parentId ?? parentId;
    final hasChildren = task != null && pack.hasChildren(task.id);
    final computedParentProgress = task != null && hasChildren
        ? pack.displayProgress(task)
        : null;
    final storedParentProgress = task?.progress ?? 0;
    final depth = () {
      if (task != null) return pack.taskDepth(task);
      if (resolvedParentId == null) return 0;
      final parent = pack.taskById(resolvedParentId);
      if (parent == null) return 1;
      return (pack.taskDepth(parent) + 1).clamp(0, kProjectTaskMaxDepth);
    }();
    final roleLabel = projectTaskRoleLabel(depth);
    final isChild = resolvedParentId != null;
    final openPhases = pack.openPhases;
    final isNew = task == null;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final media = MediaQuery.sizeOf(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final l10n = context.l10n;
            void applyStatus(ProjectTaskStatus next) {
              setDialogState(() {
                status = next;
                if (!hasChildren) {
                  progress = progressForStatusChange(next, progress);
                }
              });
            }

            void applyProgress(int next) {
              setDialogState(() {
                progress = next.clamp(0, 100);
                if (progress >= 100) {
                  status = ProjectTaskStatus.done;
                } else if (status == ProjectTaskStatus.done && progress < 100) {
                  status = ProjectTaskStatus.inProgress;
                }
              });
            }

            String rangeLabel() {
              if (start == null && end == null) return l10n.pickDateRange;
              final from = start == null
                  ? '?'
                  : DateFormat('yyyy/MM/dd').format(start!);
              final to = end == null
                  ? '?'
                  : DateFormat('yyyy/MM/dd').format(end!);
              return '$from ～ $to';
            }

            return AlertDialog(
              title: Text(
                isNew ? l10n.addRole(roleLabel) : l10n.editRole(roleLabel),
              ),
              constraints: BoxConstraints(
                minWidth: math.min(560, media.width * 0.92),
                maxWidth: math.min(720, media.width * 0.94),
                maxHeight: media.height * 0.88,
              ),
              content: SizedBox(
                width: math.min(640, media.width * 0.9),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: title,
                        decoration: InputDecoration(
                          labelText: l10n.roleName(roleLabel),
                        ),
                        autofocus: isNew,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: owner,
                        decoration: InputDecoration(
                          labelText: l10n.ownerOptional,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notes,
                        decoration: InputDecoration(
                          labelText: l10n.notesLabel,
                          hintText: l10n.notesHint,
                          alignLabelWithHint: true,
                        ),
                        minLines: 4,
                        maxLines: 8,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                      if (openPhases.isNotEmpty && !isChild) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue:
                              selectedPhaseId != null &&
                                  openPhases.any(
                                    (phase) => phase.id == selectedPhaseId,
                                  )
                              ? selectedPhaseId
                              : openPhases.first.id,
                          decoration: InputDecoration(
                            labelText: l10n.belongsToPhase,
                          ),
                          items: [
                            for (final phase in openPhases)
                              DropdownMenuItem(
                                value: phase.id,
                                child: Text(phase.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => selectedPhaseId = value),
                        ),
                      ],
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ProjectTaskStatus>(
                        key: ValueKey(status),
                        initialValue: status,
                        decoration: InputDecoration(
                          labelText: l10n.statusLabel,
                        ),
                        items: [
                          for (final value in ProjectTaskStatus.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) applyStatus(value);
                        },
                      ),
                      if (computedParentProgress != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.progress),
                          subtitle: Text(
                            l10n.progressFromChildren(computedParentProgress),
                          ),
                        )
                      else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.progressValue(progress)),
                          subtitle: Slider(
                            value: progress.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '$progress%',
                            onChanged: (value) => applyProgress(value.round()),
                          ),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range),
                        title: Text(l10n.dateRange),
                        subtitle: Text(rangeLabel()),
                        trailing: start != null || end != null
                            ? IconButton(
                                tooltip: l10n.clearDates,
                                onPressed: () => setDialogState(() {
                                  start = null;
                                  end = null;
                                }),
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange: start != null && end != null
                                ? DateTimeRange(start: start!, end: end!)
                                : null,
                            helpText: l10n.pickStartEnd,
                            saveText: l10n.donePicking,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              start = picked.start;
                              end = picked.end;
                            });
                          }
                        },
                      ),
                      if (task?.sources.isNotEmpty ?? false)
                        ExpansionTile(
                          title: Text(l10n.sourcesTitle),
                          children: [
                            for (final source in task!.sources)
                              ListTile(dense: true, title: Text(source)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (task != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      Navigator.pop(context, false);
                      await _deleteTask(pack, task);
                    },
                    child: Text(l10n.delete),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.saveAndConfirm),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;
    var phases = pack.phases;
    var activePhaseId = pack.activePhaseId;
    if (selectedPhaseId == null && title.text.trim().isNotEmpty) {
      final phase = ProjectPhase(
        id: const Uuid().v4(),
        name: pack.nextPhaseName(),
        sortOrder: 0,
      );
      phases = [...phases, phase];
      selectedPhaseId = phase.id;
      activePhaseId = phase.id;
    }
    if (isChild) {
      ProjectTask? parent;
      for (final item in pack.tasks) {
        if (item.id == resolvedParentId) parent = item;
      }
      selectedPhaseId = parent?.phaseId ?? selectedPhaseId;
    }
    final next = [...pack.tasks];
    if (title.text.trim().isNotEmpty) {
      var syncedStatus = status;
      final leafProgress = progress.clamp(0, 100);
      var syncedProgress = hasChildren ? storedParentProgress : leafProgress;
      if (!hasChildren) {
        if (syncedStatus == ProjectTaskStatus.done) {
          syncedProgress = 100;
        } else if (syncedProgress >= 100) {
          syncedStatus = ProjectTaskStatus.done;
          syncedProgress = 100;
        }
      }
      final updated = ProjectTask(
        id: task?.id ?? const Uuid().v4(),
        title: title.text.trim(),
        status: syncedStatus,
        updatedAt: DateTime.now(),
        phaseId: selectedPhaseId,
        parentId: resolvedParentId,
        progress: syncedProgress,
        sortOrder:
            task?.sortOrder ??
            pack.nextSortOrder(
              parentId: resolvedParentId,
              phaseId: selectedPhaseId,
            ),
        startDate: start,
        endDate: end,
        owner: owner.text.trim(),
        notes: notes.text.trim(),
        sources: task?.sources ?? const [],
        confirmed: true,
      );
      final index = next.indexWhere((item) => item.id == updated.id);
      if (index < 0) {
        next.add(updated);
      } else {
        next[index] = updated;
      }
    }
    await ref
        .read(projectsProvider.notifier)
        .updatePlan(
          pack.id,
          tasks: next,
          phases: phases,
          activePhaseId: activePhaseId,
        );
    final completedPhaseId = selectedPhaseId;
    if (completedPhaseId != null &&
        status == ProjectTaskStatus.done &&
        pack
            .copyWith(tasks: next, phases: phases)
            .isPhaseComplete(completedPhaseId) &&
        mounted) {
      final archive = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.phaseCompleteTitle),
            content: Text(l10n.archiveShortBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.later),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.archive),
              ),
            ],
          );
        },
      );
      if (archive == true && mounted) {
        await _archivePhase(
          pack.copyWith(
            tasks: next,
            phases: phases,
            activePhaseId: activePhaseId,
          ),
          completedPhaseId,
          confirm: false,
        );
      }
    }
  }
}

class _PhaseBar extends StatelessWidget {
  const _PhaseBar({
    required this.project,
    required this.viewingPhaseId,
    required this.peekingArchive,
    required this.onSelectOpen,
    required this.onAddPhase,
    required this.onRenamePhase,
    required this.onArchivePhase,
    required this.onPeekArchived,
    required this.onUnarchive,
    required this.onExitPeek,
  });

  final ProjectPack project;
  final String? viewingPhaseId;
  final bool peekingArchive;
  final ValueChanged<String> onSelectOpen;
  final VoidCallback onAddPhase;
  final VoidCallback? onRenamePhase;
  final VoidCallback? onArchivePhase;
  final ValueChanged<String> onPeekArchived;
  final ValueChanged<ProjectPhase> onUnarchive;
  final VoidCallback onExitPeek;

  ProjectPhase? get _viewingPhase {
    final id = viewingPhaseId;
    if (id == null) return null;
    for (final phase in project.phases) {
      if (phase.id == id) return phase;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = project.openPhases;
    final archived = project.archivedPhases;
    final viewing = _viewingPhase;
    final l10n = context.l10n;
    final count = viewing == null ? 0 : project.tasksInPhase(viewing.id).length;
    final title = viewing == null
        ? l10n.noPhaseYet
        : peekingArchive
        ? l10n.viewingArchived(viewing.name)
        : l10n.phaseMenuTitle(viewing.name, count);

    return Row(
      children: [
        Flexible(
          child: PopupMenuButton<String>(
            tooltip: l10n.switchPhase,
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == '__add__') {
                onAddPhase();
                return;
              }
              if (value == '__exit_peek__') {
                onExitPeek();
                return;
              }
              onSelectOpen(value);
            },
            itemBuilder: (context) => [
              if (peekingArchive)
                PopupMenuItem(
                  value: '__exit_peek__',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.undo, size: 20),
                    title: Text(l10n.backToCurrentPhase),
                  ),
                ),
              if (peekingArchive && open.isNotEmpty) const PopupMenuDivider(),
              for (final phase in open)
                PopupMenuItem(
                  value: phase.id,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(phase.name),
                    subtitle: Text(
                      l10n.itemCount(project.tasksInPhase(phase.id).length),
                    ),
                    trailing: !peekingArchive && phase.id == viewingPhaseId
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                ),
              if (open.isNotEmpty) const PopupMenuDivider(),
              PopupMenuItem(
                value: '__add__',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add, size: 20),
                  title: Text(l10n.addPhaseMenu),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (archived.isNotEmpty)
          TextButton(
            onPressed: () => _showArchivedDialog(context, archived),
            child: Text(l10n.archivedCount(archived.length)),
          ),
        if (!peekingArchive &&
            (onRenamePhase != null || onArchivePhase != null))
          PopupMenuButton<_PhaseAction>(
            tooltip: l10n.phaseOptions,
            onSelected: (action) {
              switch (action) {
                case _PhaseAction.rename:
                  onRenamePhase?.call();
                case _PhaseAction.archive:
                  onArchivePhase?.call();
              }
            },
            itemBuilder: (context) => [
              if (onRenamePhase != null)
                PopupMenuItem(
                  value: _PhaseAction.rename,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined, size: 20),
                    title: Text(l10n.rename),
                  ),
                ),
              if (onArchivePhase != null)
                PopupMenuItem(
                  value: _PhaseAction.archive,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined, size: 20),
                    title: Text(l10n.archiveThisPhase),
                  ),
                ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
      ],
    );
  }

  Future<void> _showArchivedDialog(
    BuildContext context,
    List<ProjectPhase> archived,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.archivedPhasesTitle(archived.length)),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: archived.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final phase = archived[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(phase.name),
                  subtitle: Text(
                    [
                      l10n.taskCount(project.tasksInPhase(phase.id).length),
                      if (phase.archivedAt != null)
                        l10n.archivedOn(
                          DateFormat('yyyy/MM/dd').format(phase.archivedAt!),
                        ),
                    ].join(' · '),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onPeekArchived(phase.id);
                        },
                        child: Text(l10n.view),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onUnarchive(phase);
                        },
                        child: Text(l10n.unarchive),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
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

enum _PhaseAction { rename, archive }

class _BoardDateFilterBar extends StatelessWidget {
  const _BoardDateFilterBar({
    required this.filter,
    required this.customRange,
    required this.onFilterChanged,
    required this.onPickCustomRange,
  });

  final _BoardDateFilter filter;
  final DateTimeRange? customRange;
  final ValueChanged<_BoardDateFilter> onFilterChanged;
  final VoidCallback onPickCustomRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final format = DateFormat('MM/dd');
    final customLabel = customRange == null
        ? l10n.customRange
        : '${format.format(customRange!.start)}–${format.format(customRange!.end)}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<_BoardDateFilter>(
          segments: [
            ButtonSegment(value: _BoardDateFilter.all, label: Text(l10n.all)),
            ButtonSegment(
              value: _BoardDateFilter.today,
              label: Text(l10n.today),
            ),
            ButtonSegment(
              value: _BoardDateFilter.custom,
              label: Text(customLabel),
            ),
          ],
          selected: {filter},
          onSelectionChanged: (next) {
            final value = next.first;
            if (value == _BoardDateFilter.custom) {
              onPickCustomRange();
              return;
            }
            onFilterChanged(value);
          },
        ),
        if (filter == _BoardDateFilter.custom)
          TextButton.icon(
            onPressed: onPickCustomRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(l10n.adjustDates, style: theme.textTheme.labelLarge),
          ),
      ],
    );
  }
}

class _SuggestCandidate {
  _SuggestCandidate({
    required this.draft,
    required this.selected,
    required this.duplicate,
    required this.sourceLabels,
  });

  final ProjectPlanDraft draft;
  bool selected;
  final bool duplicate;
  final List<String> sourceLabels;
}

class _AcceptedSuggestion {
  const _AcceptedSuggestion({required this.draft, required this.sourceLabels});
  final ProjectPlanDraft draft;
  final List<String> sourceLabels;
}

class _ProgressOverview extends StatefulWidget {
  const _ProgressOverview({
    required this.project,
    required this.tasks,
    required this.readOnly,
    required this.onEdit,
    required this.onAddChild,
    required this.onDelete,
    required this.onMove,
  });

  final ProjectPack project;
  final List<ProjectTask> tasks;
  final bool readOnly;
  final ValueChanged<ProjectTask> onEdit;
  final ValueChanged<ProjectTask> onAddChild;
  final ValueChanged<ProjectTask> onDelete;
  final void Function(ProjectTask task, int delta) onMove;

  @override
  State<_ProgressOverview> createState() => _ProgressOverviewState();
}

class _ProgressOverviewState extends State<_ProgressOverview> {
  final Set<String> _collapsed = {};

  /// 0 = 只看大項目, 1 = 到子類別, 2 = 全部展開
  int _viewDepth = 2;
  DateTimeRange? _focusRange;

  bool _taskOverlapsRange(ProjectTask task, DateTimeRange range) =>
      taskOverlapsDateRange(task, range);

  bool _subtreeTouchesRange(ProjectTask node, DateTimeRange range) {
    if (_taskOverlapsRange(node, range)) return true;
    for (final child in widget.project.childrenOf(node.id)) {
      if (_subtreeTouchesRange(child, range)) return true;
    }
    return false;
  }

  void _applyViewDepth(int depth) {
    setState(() {
      _viewDepth = depth;
      _focusRange = null;
      _collapsed
        ..clear()
        ..addAll({
          for (final task in widget.tasks)
            if (widget.project.hasChildren(task.id) &&
                widget.project.taskDepth(task) >= depth)
              task.id,
        });
    });
  }

  void _expandAll() {
    setState(() {
      _viewDepth = 2;
      _focusRange = null;
      _collapsed.clear();
    });
  }

  Future<void> _focusByDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _focusRange,
      helpText: context.l10n.rangeHelp,
      saveText: context.l10n.apply,
    );
    if (picked == null || !mounted) return;
    final collapse = <String>{};
    for (final task in widget.tasks) {
      if (!widget.project.hasChildren(task.id)) continue;
      // Expand ancestors that lead to a matching leaf/node; collapse the rest.
      if (!_subtreeTouchesRange(task, picked)) {
        collapse.add(task.id);
      }
    }
    setState(() {
      _focusRange = picked;
      _viewDepth = 2;
      _collapsed
        ..clear()
        ..addAll(collapse);
    });
  }

  void _clearDateFocus() {
    setState(() {
      _focusRange = null;
      _collapsed.clear();
      _viewDepth = 2;
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_collapsed.contains(id)) {
        _collapsed.remove(id);
      } else {
        _collapsed.add(id);
      }
      // Manual tweak leaves depth chips as "custom" feel → keep last depth.
    });
  }

  List<Widget> _buildBranch(
    ProjectTask node, {
    required int depth,
    required List<ProjectTask> siblings,
  }) {
    final range = _focusRange;
    if (range != null && !_subtreeTouchesRange(node, range)) {
      return const [];
    }

    final allKids = widget.project.childrenOf(node.id);
    final kids = range == null
        ? allKids
        : [
            for (final child in allKids)
              if (_subtreeTouchesRange(child, range)) child,
          ];
    final expanded = !_collapsed.contains(node.id);
    final index = siblings.indexWhere((item) => item.id == node.id);
    final rows = <Widget>[
      _ProgressRow(
        task: node,
        depth: depth,
        progress: widget.project.displayProgress(node),
        expanded: expanded,
        childCount: kids.length,
        canMoveUp: index > 0,
        canMoveDown: index >= 0 && index < siblings.length - 1,
        readOnly: widget.readOnly,
        onToggle: kids.isEmpty ? null : () => _toggle(node.id),
        onEdit: () => widget.onEdit(node),
        onAddChild: widget.project.canAddChild(node)
            ? () => widget.onAddChild(node)
            : null,
        onDelete: () => widget.onDelete(node),
        onMoveUp: () => widget.onMove(node, -1),
        onMoveDown: () => widget.onMove(node, 1),
      ),
    ];
    if (expanded) {
      for (final child in kids) {
        rows.addAll(_buildBranch(child, depth: depth + 1, siblings: kids));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phaseId = widget.tasks.isEmpty ? null : widget.tasks.first.phaseId;
    final roots = [
      for (final task in widget.project.rootTasksInPhase(phaseId))
        if (widget.tasks.any((item) => item.id == task.id)) task,
    ];
    final visibleRoots = _focusRange == null
        ? roots
        : [
            for (final root in roots)
              if (_subtreeTouchesRange(root, _focusRange!)) root,
          ];
    final l10n = context.l10n;
    final rangeLabel = _focusRange == null
        ? null
        : '${DateFormat('MM/dd').format(_focusRange!.start)}–${DateFormat('MM/dd').format(_focusRange!.end)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.showLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                FilterChip(
                  label: Text(l10n.filterMainItems),
                  selected: _focusRange == null && _viewDepth == 0,
                  onSelected: (_) => _applyViewDepth(0),
                ),
                FilterChip(
                  label: Text(l10n.filterSubcategories),
                  selected: _focusRange == null && _viewDepth == 1,
                  onSelected: (_) => _applyViewDepth(1),
                ),
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: _focusRange == null && _viewDepth == 2,
                  onSelected: (_) => _expandAll(),
                ),
                FilterChip(
                  avatar: Icon(
                    Icons.date_range,
                    size: 18,
                    color: _focusRange != null
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  label: Text(
                    rangeLabel == null
                        ? l10n.byDate
                        : l10n.dateFilter(rangeLabel),
                  ),
                  selected: _focusRange != null,
                  onSelected: (_) => _focusByDateRange(),
                ),
                if (_focusRange != null)
                  ActionChip(
                    avatar: const Icon(Icons.clear, size: 16),
                    label: Text(l10n.clearDateFilter),
                    onPressed: _clearDateFocus,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _focusRange == null
                  ? l10n.hierarchyHelp
                  : l10n.rangeIntersectionHelp(rangeLabel!),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (visibleRoots.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                _focusRange == null ? l10n.noItems : l10n.noItemsInRange,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var i = 0; i < visibleRoots.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ..._buildBranch(
                visibleRoots[i],
                depth: 0,
                siblings: visibleRoots,
              ),
            ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.task,
    required this.depth,
    required this.progress,
    required this.expanded,
    required this.childCount,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.readOnly,
    required this.onToggle,
    required this.onEdit,
    required this.onAddChild,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final ProjectTask task;
  final int depth;
  final int progress;
  final bool expanded;
  final int childCount;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool readOnly;
  final VoidCallback? onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onAddChild;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final role = projectTaskRoleLabel(depth);
    final isRecord = depth >= 2;
    final missingDate = task.startDate == null && task.endDate == null;
    final barHeight = isRecord ? 5.0 : (depth == 0 ? 8.0 : 6.0);
    final indent = 12.0 + depth * 18.0;

    return Material(
      color: depth == 0
          ? Colors.transparent
          : scheme.surfaceContainerHighest.withValues(
              alpha: isRecord ? 0.18 : 0.28,
            ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            indent,
            isRecord ? 8 : 10,
            8,
            isRecord ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: childCount > 0
                        ? IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: expanded ? l10n.collapse : l10n.expand,
                            onPressed: onToggle,
                            icon: Icon(
                              expanded
                                  ? Icons.expand_more
                                  : Icons.chevron_right,
                              size: 20,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 8, left: 10),
                            child: Icon(
                              isRecord
                                  ? Icons.circle
                                  : Icons.subdirectory_arrow_right,
                              size: isRecord ? 6 : 14,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(
                                  alpha: depth == 0
                                      ? 0.18
                                      : (isRecord ? 0.08 : 0.12),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                role,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          (isRecord
                                                  ? Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium
                                                  : Theme.of(
                                                      context,
                                                    ).textTheme.titleSmall)
                                              ?.copyWith(
                                                fontWeight: depth == 0
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                    ),
                                  ),
                                  if (missingDate) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: l10n.dateNotSetShort,
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: scheme.tertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '$progress%',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: barHeight,
                            backgroundColor: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                            color: _barColor(context, task.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!readOnly)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.moveUp,
                          visualDensity: VisualDensity.compact,
                          onPressed: canMoveUp ? onMoveUp : null,
                          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                        ),
                        IconButton(
                          tooltip: l10n.moveDown,
                          visualDensity: VisualDensity.compact,
                          onPressed: canMoveDown ? onMoveDown : null,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        ),
                        if (onAddChild != null)
                          IconButton(
                            tooltip: l10n.addChildRole(
                              projectTaskRoleLabel(depth + 1),
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: onAddChild,
                            icon: const Icon(Icons.add, size: 20),
                          ),
                        IconButton(
                          tooltip: l10n.delete,
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: scheme.error.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _barColor(BuildContext context, ProjectTaskStatus status) =>
    switch (status) {
      ProjectTaskStatus.done => const Color(0xFF3D9B7A),
      ProjectTaskStatus.blocked => Theme.of(context).colorScheme.error,
      ProjectTaskStatus.inProgress => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.outline,
    };
