import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/widgets/project_task_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('看板同一狀態先依日期再依名稱', () {
    final items = [
      _item('late', '收尾', start: DateTime(2026, 4, 20)),
      _item('early-b', 'beta', start: DateTime(2026, 4, 2)),
      _item('early-a', 'alpha', start: DateTime(2026, 4, 2)),
      _item('end-only', '驗收', end: DateTime(2026, 4, 8)),
      _item('undated-b', 'note'),
      _item('undated-a', 'memo'),
    ]..sort(compareBoardTasks);

    expect(items.map((item) => item.task.title).toList(), [
      'alpha',
      'beta',
      '驗收',
      '收尾',
      'memo',
      'note',
    ]);
  });
}

BoardTaskItem _item(String id, String title, {DateTime? start, DateTime? end}) {
  return BoardTaskItem(
    projectId: 'p',
    task: ProjectTask(
      id: id,
      title: title,
      status: ProjectTaskStatus.planned,
      updatedAt: DateTime(2026),
      startDate: start,
      endDate: end,
    ),
  );
}
