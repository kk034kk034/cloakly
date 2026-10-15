import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:flutter/material.dart';

/// Calendar-day inclusive end of [range.end].
DateTime dateRangeInclusiveEnd(DateTimeRange range) => DateTime(
  range.end.year,
  range.end.month,
  range.end.day,
  23,
  59,
  59,
);

DateTime _dayOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Effective task span: missing end/start falls back to the other side.
(DateTime, DateTime)? taskDateSpan(ProjectTask task) {
  final start = task.startDate ?? task.endDate;
  final end = task.endDate ?? task.startDate;
  if (start == null || end == null) return null;
  return (start, end);
}

/// Whether [task]'s date span overlaps [range] (inclusive calendar days).
bool taskOverlapsDateRange(ProjectTask task, DateTimeRange range) {
  final span = taskDateSpan(task);
  if (span == null) return false;
  final (start, end) = span;
  final rangeEnd = dateRangeInclusiveEnd(range);
  return !end.isBefore(range.start) && !start.isAfter(rangeEnd);
}

bool _isUndatedActive(ProjectTask task) {
  if (task.startDate != null || task.endDate != null) return false;
  return task.status == ProjectTaskStatus.inProgress ||
      task.status == ProjectTaskStatus.blocked;
}

/// Overdue: has dates, not done, and span ends before the start of [today].
bool taskIsOverdue(ProjectTask task, {required DateTime today}) {
  if (task.status == ProjectTaskStatus.done) return false;
  final span = taskDateSpan(task);
  if (span == null) return false;
  final day = _dayOnly(today);
  return span.$2.isBefore(day);
}

/// Board / home focus filter.
///
/// - [range] `null` → show all (no date filter).
/// - otherwise show if overlaps [range], or undated in-progress/blocked;
///   when [includeOverdue] is true, also show unfinished tasks past today.
bool taskMatchesBoardFocus(
  ProjectTask task, {
  required DateTimeRange? range,
  required bool includeOverdue,
  DateTime? today,
}) {
  if (range == null) return true;
  if (taskOverlapsDateRange(task, range)) return true;
  if (_isUndatedActive(task)) return true;
  if (includeOverdue && taskIsOverdue(task, today: today ?? DateTime.now())) {
    return true;
  }
  return false;
}

/// Single calendar day as a [DateTimeRange] starting at local midnight.
DateTimeRange todayDateRange([DateTime? now]) {
  final day = _dayOnly(now ?? DateTime.now());
  return DateTimeRange(start: day, end: day);
}
