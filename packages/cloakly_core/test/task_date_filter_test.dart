import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/utils/task_date_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 15);
  final todayRange = todayDateRange(today);

  ProjectTask task({
    String id = 't',
    ProjectTaskStatus status = ProjectTaskStatus.planned,
    DateTime? start,
    DateTime? end,
  }) => ProjectTask(
    id: id,
    title: id,
    status: status,
    updatedAt: today,
    startDate: start,
    endDate: end,
  );

  group('taskOverlapsDateRange', () {
    test('區間重疊今天會命中', () {
      final item = task(
        start: DateTime(2026, 10, 10),
        end: DateTime(2026, 10, 20),
      );
      expect(taskOverlapsDateRange(item, todayRange), isTrue);
    });

    test('僅一端有日期且為今天會命中', () {
      expect(
        taskOverlapsDateRange(task(start: today), todayRange),
        isTrue,
      );
      expect(
        taskOverlapsDateRange(task(end: today), todayRange),
        isTrue,
      );
    });

    test('完全在過去不重疊', () {
      final item = task(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );
      expect(taskOverlapsDateRange(item, todayRange), isFalse);
    });
  });

  group('taskMatchesBoardFocus · 今天', () {
    test('今天重疊會顯示', () {
      final item = task(
        start: DateTime(2026, 10, 14),
        end: DateTime(2026, 10, 16),
      );
      expect(
        taskMatchesBoardFocus(
          item,
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isTrue,
      );
    });

    test('逾期未完成會顯示', () {
      final item = task(
        status: ProjectTaskStatus.planned,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );
      expect(
        taskMatchesBoardFocus(
          item,
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isTrue,
      );
    });

    test('已完成逾期不顯示', () {
      final item = task(
        status: ProjectTaskStatus.done,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );
      expect(
        taskMatchesBoardFocus(
          item,
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isFalse,
      );
    });

    test('無日期僅進行中／阻塞顯示', () {
      expect(
        taskMatchesBoardFocus(
          task(status: ProjectTaskStatus.inProgress),
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isTrue,
      );
      expect(
        taskMatchesBoardFocus(
          task(status: ProjectTaskStatus.blocked),
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isTrue,
      );
      expect(
        taskMatchesBoardFocus(
          task(status: ProjectTaskStatus.planned),
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isFalse,
      );
      expect(
        taskMatchesBoardFocus(
          task(status: ProjectTaskStatus.done),
          range: todayRange,
          includeOverdue: true,
          today: today,
        ),
        isFalse,
      );
    });
  });

  group('taskMatchesBoardFocus · 自訂／全部', () {
    test('自訂區間重疊會顯示，不含逾期規則', () {
      final range = DateTimeRange(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 7),
      );
      final overlapping = task(
        start: DateTime(2026, 11, 3),
        end: DateTime(2026, 11, 5),
      );
      final overdueOnly = task(
        status: ProjectTaskStatus.planned,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );
      expect(
        taskMatchesBoardFocus(
          overlapping,
          range: range,
          includeOverdue: false,
          today: today,
        ),
        isTrue,
      );
      expect(
        taskMatchesBoardFocus(
          overdueOnly,
          range: range,
          includeOverdue: false,
          today: today,
        ),
        isFalse,
      );
    });

    test('自訂區間下無日期進行中仍顯示', () {
      final range = DateTimeRange(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 7),
      );
      expect(
        taskMatchesBoardFocus(
          task(status: ProjectTaskStatus.inProgress),
          range: range,
          includeOverdue: false,
          today: today,
        ),
        isTrue,
      );
    });

    test('全部模式不過濾', () {
      final undatedPlanned = task(status: ProjectTaskStatus.planned);
      final overdue = task(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 2),
      );
      expect(
        taskMatchesBoardFocus(
          undatedPlanned,
          range: null,
          includeOverdue: false,
        ),
        isTrue,
      );
      expect(
        taskMatchesBoardFocus(overdue, range: null, includeOverdue: false),
        isTrue,
      );
    });
  });
}
