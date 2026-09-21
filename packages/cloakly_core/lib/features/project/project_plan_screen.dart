import 'dart:math' as math;

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/state/project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ProjectPlanScreen extends ConsumerStatefulWidget {
  const ProjectPlanScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectPlanScreen> createState() => _ProjectPlanScreenState();
}

class _ProjectPlanScreenState extends ConsumerState<ProjectPlanScreen> {
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
    final project = pack;
    return Scaffold(
      appBar: AppBar(title: Text('${project.name} · 甘特圖')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editTask(project),
        icon: const Icon(Icons.add),
        label: const Text('新增工作'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const Text('工作項目由你手動維護，甘特圖呈現日期與進度；拖曳卡片可快速更新狀態。'),
          const SizedBox(height: 20),
          if (project.tasks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('尚無工作項目。按右下角「新增工作」開始建立你的專案進度。'),
              ),
            )
          else ...[
            Text('時間軸', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _GanttChart(tasks: project.tasks),
            const SizedBox(height: 4),
            Text(
              '左右滑動可查看完整日期範圍',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('工作看板', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _TaskBoard(
              tasks: project.tasks,
              onEdit: (task) => _editTask(project, task),
              onStatusChanged: (task, status) async {
                final next = [
                  for (final item in project.tasks)
                    item.id == task.id
                        ? item.copyWith(status: status, confirmed: true)
                        : item,
                ];
                await ref
                    .read(projectsProvider.notifier)
                    .updateTasks(project.id, next);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editTask(ProjectPack pack, [ProjectTask? task]) async {
    final title = TextEditingController(text: task?.title ?? '');
    final owner = TextEditingController(text: task?.owner ?? '');
    DateTime? start = task?.startDate;
    DateTime? end = task?.endDate;
    var status = task?.status ?? ProjectTaskStatus.planned;
    var remove = false;
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
    final next = [...pack.tasks];
    if (remove) {
      next.removeWhere((item) => item.id == task!.id);
    } else if (title.text.trim().isNotEmpty) {
      final updated = ProjectTask(
        id: task?.id ?? const Uuid().v4(),
        title: title.text.trim(),
        status: status,
        updatedAt: DateTime.now(),
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
    await ref.read(projectsProvider.notifier).updateTasks(pack.id, next);
  }
}

class _TaskBoard extends StatelessWidget {
  const _TaskBoard({
    required this.tasks,
    required this.onEdit,
    required this.onStatusChanged,
  });

  final List<ProjectTask> tasks;
  final ValueChanged<ProjectTask> onEdit;
  final Future<void> Function(ProjectTask, ProjectTaskStatus) onStatusChanged;

  static const columns = [
    (
      title: '待辦',
      statuses: [ProjectTaskStatus.planned, ProjectTaskStatus.uncertain],
    ),
    (title: '進行中', statuses: [ProjectTaskStatus.inProgress]),
    (title: '阻塞', statuses: [ProjectTaskStatus.blocked]),
    (title: '完成', statuses: [ProjectTaskStatus.done]),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 900.0;
        final columnWidth = math.max(220.0, (width - 24) / 4);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                SizedBox(
                  width: columnWidth,
                  child: _column(context, columns[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _column(
    BuildContext context,
    ({String title, List<ProjectTaskStatus> statuses}) column,
  ) {
    final items = tasks.where((task) => column.statuses.contains(task.status));
    return DragTarget<ProjectTask>(
      onAcceptWithDetails: (details) =>
          onStatusChanged(details.data, column.statuses.first),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
              : Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${column.title} · ${items.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final task in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Draggable<ProjectTask>(
                  data: task,
                  feedback: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 210, child: _card(context, task)),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _card(context, task),
                  ),
                  child: _card(context, task),
                ),
              ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  '拖曳工作到這裡',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, ProjectTask task) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onEdit(task),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            if (task.owner.isNotEmpty)
              Text(task.owner, style: Theme.of(context).textTheme.bodySmall),
            Text(_dateText(task), style: Theme.of(context).textTheme.bodySmall),
            if (task.confirmed)
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.verified_outlined, size: 16),
              ),
          ],
        ),
      ),
    ),
  );

  String _dateText(ProjectTask task) {
    if (task.startDate == null && task.endDate == null) return '日期未設定';
    return '${task.startDate == null ? '?' : DateFormat('MM/dd').format(task.startDate!)} ～ ${task.endDate == null ? '?' : DateFormat('MM/dd').format(task.endDate!)}';
  }
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
        // Keep the task labels useful on portrait screens while allowing the
        // date range to remain fully accessible through horizontal scrolling.
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
                              style: Theme.of(context).textTheme.labelSmall,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                              task.startDate ?? task.endDate!,
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
  const _TimelineGridPainter({required this.days, required this.dayWidth});
  final int days;
  final double dayWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x553F514C)
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
      oldDelegate.days != days || oldDelegate.dayWidth != dayWidth;
}
