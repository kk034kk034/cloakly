import 'dart:math' as math;

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 欄內排序：先看行程時間，再看名稱。
int compareBoardTasks(BoardTaskItem a, BoardTaskItem b) {
  final byTime = _boardTime(a.task).compareTo(_boardTime(b.task));
  if (byTime != 0) return byTime;
  final byTitle = a.task.title.toLowerCase().compareTo(
    b.task.title.toLowerCase(),
  );
  if (byTitle != 0) return byTitle;
  return a.task.id.compareTo(b.task.id);
}

DateTime _boardTime(ProjectTask task) =>
    task.startDate ?? task.endDate ?? DateTime(9999);

/// One card on a project (or cross-project) kanban board.
class BoardTaskItem {
  const BoardTaskItem({
    required this.task,
    required this.projectId,
    this.projectName = '',
  });

  final ProjectTask task;
  final String projectId;
  final String projectName;
}

/// Drag-and-drop columns: 待辦 / 進行中 / 阻塞 / 完成.
class ProjectTaskBoard extends StatelessWidget {
  const ProjectTaskBoard({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onStatusChanged,
  });

  final List<BoardTaskItem> items;
  final ValueChanged<BoardTaskItem> onEdit;
  final Future<void> Function(BoardTaskItem, ProjectTaskStatus) onStatusChanged;

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
    final columnItems =
        items
            .where((item) => column.statuses.contains(item.task.status))
            .toList()
          ..sort(compareBoardTasks);
    return DragTarget<BoardTaskItem>(
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
              '${column.title} · ${columnItems.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final item in columnItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Draggable<BoardTaskItem>(
                  data: item,
                  feedback: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 210, child: _card(context, item)),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _card(context, item),
                  ),
                  child: _card(context, item),
                ),
              ),
            if (columnItems.isEmpty)
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

  Widget _card(BuildContext context, BoardTaskItem item) {
    final task = item.task;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onEdit(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.projectName.isNotEmpty) ...[
                Text(
                  item.projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(task.title, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              if (task.owner.isNotEmpty)
                Text(task.owner, style: Theme.of(context).textTheme.bodySmall),
              Text(
                dateText(task),
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
  }

  static String dateText(ProjectTask task) {
    if (task.startDate == null && task.endDate == null) return '日期未設定';
    return '${task.startDate == null ? '?' : DateFormat('MM/dd').format(task.startDate!)} ～ ${task.endDate == null ? '?' : DateFormat('MM/dd').format(task.endDate!)}';
  }
}
