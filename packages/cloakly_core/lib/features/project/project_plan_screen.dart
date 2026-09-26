import 'dart:math' as math;

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/llm/llm_service.dart';
import 'package:cloakly_core/services/project/project_retrieval.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:cloakly_core/state/providers.dart';
import 'package:cloakly_core/widgets/project_task_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

  @override
  Widget build(BuildContext context) {
    final projects =
        ref.watch(projectsProvider).valueOrNull?.projects ?? const [];
    ProjectPack? pack;
    for (final project in projects) {
      if (project.id == widget.projectId) pack = project;
    }
    if (pack == null) {
      return const Scaffold(body: Center(child: Text('找不到此專案。')));
    }
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
        title: Text('${project.name} · 甘特圖'),
        actions: [
          IconButton(
            tooltip: configured ? 'AI 建議時程' : '先設定 AI 才能建議時程',
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
              label: const Text('新增工作'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const Text(
            '以階段（phase）拆看板：每個階段建議維持少數可完成項目；全部移到「完成」後可封存，再開下一階段，避免完成欄過長。',
          ),
          if (!configured)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('設定 AI 服務後，即可依文件與會議建議分階段時程。'),
              trailing: TextButton(
                onPressed: () => context.push('/settings'),
                child: const Text('設定'),
              ),
            ),
          if (_lastSuggestUsage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '上次 AI 建議用量：${_lastSuggestUsage!.display}',
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
                    const Text('尚未建立階段。先新增一個階段，再放工作項目。'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _addPhase(project),
                      icon: const Icon(Icons.add),
                      label: const Text('新增階段'),
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
    return [
      if (peekingArchive)
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text('正在檢視已封存的「${phase.name}」'),
            subtitle: const Text('不佔用現行看板版面'),
            trailing: TextButton(
              onPressed: () => setState(() => _peekArchivedPhaseId = null),
              child: const Text('回到現行階段'),
            ),
          ),
        ),
      if (!peekingArchive && project.isPhaseComplete(phase.id))
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('此階段工作已全部完成'),
            subtitle: const Text('封存後完成欄會收合，可安心開下一階段。'),
            trailing: FilledButton(
              onPressed: () => _archivePhase(project, phase.id, confirm: false),
              child: const Text('封存階段'),
            ),
          ),
        ),
      const SizedBox(height: 8),
      Text(
        '${phase.name} · 時間軸',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      if (boardTasks.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('這個階段還沒有工作。可手動新增，或用 AI 建議時程。'),
          ),
        )
      else ...[
        _GanttChart(tasks: boardTasks),
        const SizedBox(height: 4),
        Text('左右滑動可查看完整日期範圍', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        Text(
          '${phase.name} · 工作看板',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ProjectTaskBoard(
          items: [
            for (final task in boardTasks)
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

  Future<void> _changeStatus(
    ProjectPack pack,
    ProjectTask task,
    ProjectTaskStatus status,
  ) async {
    final next = [
      for (final item in pack.tasks)
        item.id == task.id
            ? item.copyWith(status: status, confirmed: true)
            : item,
    ];
    await ref.read(projectsProvider.notifier).updateTasks(pack.id, next);
    final phaseId = task.phaseId;
    if (phaseId == null || !mounted) return;
    final updated = pack.copyWith(tasks: next);
    if (!updated.isPhaseComplete(phaseId)) return;
    final archive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('階段已全部完成'),
        content: const Text('要封存這個階段嗎？封存後不會佔用看板版面，之後仍可從「已封存」檢視。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍後'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('封存'),
          ),
        ],
      ),
    );
    if (archive == true && mounted) {
      await _archivePhase(updated, phaseId, confirm: false);
    }
  }

  Future<void> _addPhase(ProjectPack pack) async {
    final nameController = TextEditingController(text: pack.nextPhaseName());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增階段'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '階段名稱',
            hintText: '例如：MVP、上線準備',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('建立'),
          ),
        ],
      ),
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
      builder: (context) => AlertDialog(
        title: const Text('重新命名階段'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '階段名稱'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('儲存'),
          ),
        ],
      ),
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
        builder: (context) => AlertDialog(
          title: const Text('封存此階段？'),
          content: const Text('封存後看板只顯示其他未封存階段，已完成項目不會再佔版面。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('封存'),
            ),
          ],
        ),
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
        SnackBar(content: Text(remaining.isEmpty ? '已封存並開啟下一階段。' : '階段已封存。')),
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
    const question = '請依專案文件與會議資料整理可追蹤的工作、時程、期限與負責人，並拆成可陸續完成的階段。';
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
        setState(
          () => _suggestError = '目前沒有足夠的文件或會議資料可供建議。請先把時程、規格或會議紀錄放進專案資料夾。',
        );
        return;
      }
      final result = await ai.generateProjectPlan(
        evidence: evidence.context(pack.name, ProjectQuestionMode.overview),
      );
      if (!mounted) return;
      setState(() => _lastSuggestUsage = result.usage);
      if (result.tasks.isEmpty) {
        setState(() => _suggestError = 'AI 沒有從現有資料找出可追蹤工作。');
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
        SnackBar(content: Text('已加入 ${selected.length} 項建議工作，請再確認日期與狀態。')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _suggestError = '無法產生時程建議：$error');
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
    final tasks = [
      ...pack.tasks,
      for (final item in selected)
        ProjectTask(
          id: const Uuid().v4(),
          title: item.draft.title,
          status: projectTaskStatusFromName(item.draft.status),
          updatedAt: DateTime.now(),
          phaseId: resolvePhaseId(
            item.draft.phaseName.isEmpty ? fallback : item.draft.phaseName,
          ),
          startDate: item.draft.startDate,
          endDate: item.draft.endDate,
          owner: item.draft.owner,
          sources: item.sourceLabels,
          confirmed: false,
        ),
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
                      'AI 建議的分階段時程',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '工作會依階段名稱分組；完成一個階段後可封存再開下一階段。勾選要加入的項目。',
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
                                if (item.duplicate) '（同名工作已存在）',
                                if (item.sourceLabels.isNotEmpty)
                                  item.sourceLabels.join('、'),
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
                          child: const Text('取消'),
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
                          child: Text('加入所選（$selectedCount）'),
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

  Future<void> _editTask(
    ProjectPack pack, {
    ProjectTask? task,
    String? phaseId,
  }) async {
    final title = TextEditingController(text: task?.title ?? '');
    final owner = TextEditingController(text: task?.owner ?? '');
    DateTime? start = task?.startDate;
    DateTime? end = task?.endDate;
    var status = task?.status ?? ProjectTaskStatus.planned;
    var selectedPhaseId = task?.phaseId ?? phaseId ?? pack.activePhase?.id;
    var remove = false;
    final openPhases = pack.openPhases;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? '新增工作' : '編輯工作'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: '工作名稱'),
                ),
                TextField(
                  controller: owner,
                  decoration: const InputDecoration(labelText: '負責人（選填）'),
                ),
                if (openPhases.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue:
                        selectedPhaseId != null &&
                            openPhases.any(
                              (phase) => phase.id == selectedPhaseId,
                            )
                        ? selectedPhaseId
                        : openPhases.first.id,
                    decoration: const InputDecoration(labelText: '所屬階段'),
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
                DropdownButtonFormField<ProjectTaskStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: '狀態'),
                  items: [
                    for (final value in ProjectTaskStatus.values)
                      DropdownMenuItem(value: value, child: Text(value.label)),
                  ],
                  onChanged: (value) => status = value ?? status,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('開始日期'),
                  subtitle: Text(
                    start == null
                        ? '未設定'
                        : DateFormat('yyyy/MM/dd').format(start!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: start ?? DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => start = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('結束日期'),
                  subtitle: Text(
                    end == null ? '未設定' : DateFormat('yyyy/MM/dd').format(end!),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: end ?? start ?? DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => end = picked);
                  },
                ),
                if (task?.sources.isNotEmpty ?? false)
                  ExpansionTile(
                    title: const Text('資料依據'),
                    children: [
                      for (final source in task!.sources)
                        ListTile(dense: true, title: Text(source)),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            if (task != null)
              TextButton(
                onPressed: () {
                  remove = true;
                  Navigator.pop(context, true);
                },
                child: const Text('刪除'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('儲存並確認'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    var phases = pack.phases;
    var activePhaseId = pack.activePhaseId;
    if (selectedPhaseId == null && title.text.trim().isNotEmpty && !remove) {
      final phase = ProjectPhase(
        id: const Uuid().v4(),
        name: pack.nextPhaseName(),
        sortOrder: 0,
      );
      phases = [...phases, phase];
      selectedPhaseId = phase.id;
      activePhaseId = phase.id;
    }
    final next = [...pack.tasks];
    if (remove) {
      next.removeWhere((item) => item.id == task!.id);
    } else if (title.text.trim().isNotEmpty) {
      final updated = ProjectTask(
        id: task?.id ?? const Uuid().v4(),
        title: title.text.trim(),
        status: status,
        updatedAt: DateTime.now(),
        phaseId: selectedPhaseId,
        startDate: start,
        endDate: end,
        owner: owner.text.trim(),
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
    if (!remove &&
        completedPhaseId != null &&
        status == ProjectTaskStatus.done &&
        pack
            .copyWith(tasks: next, phases: phases)
            .isPhaseComplete(completedPhaseId) &&
        mounted) {
      final archive = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('階段已全部完成'),
          content: const Text('要封存這個階段嗎？封存後不會佔用看板版面。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('稍後'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('封存'),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final open = project.openPhases;
    final archived = project.archivedPhases;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('階段', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final phase in open)
              ChoiceChip(
                label: Text(
                  '${phase.name} · ${project.tasksInPhase(phase.id).length}',
                ),
                selected: !peekingArchive && phase.id == viewingPhaseId,
                onSelected: (_) => onSelectOpen(phase.id),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('新增階段'),
              onPressed: onAddPhase,
            ),
            if (onRenamePhase != null)
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('重新命名'),
                onPressed: onRenamePhase,
              ),
            if (onArchivePhase != null)
              ActionChip(
                avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('封存目前階段'),
                onPressed: onArchivePhase,
              ),
            if (peekingArchive)
              ActionChip(
                avatar: const Icon(Icons.undo, size: 18),
                label: const Text('離開封存檢視'),
                onPressed: onExitPeek,
              ),
          ],
        ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('已封存階段 · ${archived.length}'),
            subtitle: const Text('不佔看板版面；需要時可檢視或解除封存'),
            children: [
              for (final phase in archived)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(phase.name),
                  subtitle: Text(
                    [
                      '${project.tasksInPhase(phase.id).length} 項工作',
                      if (phase.archivedAt != null)
                        '封存於 ${DateFormat('yyyy/MM/dd').format(phase.archivedAt!)}',
                    ].join(' · '),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => onPeekArchived(phase.id),
                        child: const Text('檢視'),
                      ),
                      TextButton(
                        onPressed: () => onUnarchive(phase),
                        child: const Text('解除封存'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
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

class _GanttChart extends StatefulWidget {
  const _GanttChart({required this.tasks});
  final List<ProjectTask> tasks;

  @override
  State<_GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<_GanttChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduled = widget.tasks
        .where((task) => task.startDate != null || task.endDate != null)
        .toList();
    if (scheduled.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('目前沒有具體日期，先列為待確認工作。'),
        ),
      );
    }
    final starts = scheduled
        .map((task) => task.startDate ?? task.endDate!)
        .toList();
    final ends = scheduled
        .map((task) => task.endDate ?? task.startDate!)
        .toList();
    final minDate = starts.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = ends.reduce((a, b) => a.isAfter(b) ? a : b);
    final days = math.max(1, maxDate.difference(minDate).inDays + 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 720.0;
        final labelWidth = math.min(220.0, math.max(140.0, viewportWidth * .3));
        final dayWidth = viewportWidth < 600 ? 22.0 : 28.0;
        final timelineWidth = math.max(
          math.max(520.0, viewportWidth - labelWidth),
          days * dayWidth,
        );
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: labelWidth + timelineWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: labelWidth),
                        SizedBox(
                          width: timelineWidth,
                          height: 48,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _TimelineGridPainter(
                                    days: days,
                                    dayWidth: dayWidth,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              for (var day = 0; day <= days; day += 7)
                                Positioned(
                                  left: day * dayWidth + 4,
                                  top: 6,
                                  child: Text(
                                    DateFormat(
                                      'MM/dd',
                                    ).format(minDate.add(Duration(days: day))),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    for (final task in scheduled)
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            SizedBox(
                              width: labelWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: timelineWidth,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _TimelineGridPainter(
                                        days: days,
                                        dayWidth: dayWidth,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left:
                                        (task.startDate ?? task.endDate!)
                                            .difference(minDate)
                                            .inDays *
                                        dayWidth,
                                    width: math.max(
                                      dayWidth,
                                      ((task.endDate ?? task.startDate!)
                                                  .difference(
                                                    task.startDate ??
                                                        task.endDate!,
                                                  )
                                                  .inDays +
                                              1) *
                                          dayWidth,
                                    ),
                                    height: 22,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _barColor(context, task.status),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _barColor(BuildContext context, ProjectTaskStatus status) =>
    switch (status) {
      ProjectTaskStatus.done => Colors.green.shade600,
      ProjectTaskStatus.blocked => Theme.of(context).colorScheme.error,
      ProjectTaskStatus.inProgress => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.secondary,
    };

class _TimelineGridPainter extends CustomPainter {
  const _TimelineGridPainter({
    required this.days,
    required this.dayWidth,
    required this.color,
  });
  final int days;
  final double dayWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var day = 0; day <= days; day += 7) {
      final x = day * dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineGridPainter oldDelegate) =>
      oldDelegate.days != days ||
      oldDelegate.dayWidth != dayWidth ||
      oldDelegate.color != color;
}
