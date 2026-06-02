import 'package:uuid/uuid.dart';

import '../domain/models.dart';

const _uuid = Uuid();

Reminder createReminderFromRecord({
  required CareRecord record,
  required String petName,
  required ReminderRule rule,
  required DateTime createdAt,
}) {
  final title = rule.titleTemplate.replaceAll('{name}', petName);
  return Reminder(
    id: _uuid.v5(Namespace.url.value, '${record.id}:${rule.id}'),
    petId: record.petId,
    title: title,
    dueAt: record.happenedAt.add(Duration(days: rule.intervalDays)),
    status: ReminderStatus.scheduled,
    sourceRecordId: record.id,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

MonthlyExpenseSummary summarizeMonthlyExpenses(
  Iterable<ExpenseEntry> entries, {
  required int year,
  required int month,
}) {
  final categoryTotals = <ExpenseCategory, int>{};
  var total = 0;
  var count = 0;
  for (final entry in entries) {
    if (entry.deletedAt != null ||
        entry.spentAt.year != year ||
        entry.spentAt.month != month) {
      continue;
    }
    total += entry.amountCents;
    count += 1;
    categoryTotals.update(
      entry.category,
      (value) => value + entry.amountCents,
      ifAbsent: () => entry.amountCents,
    );
  }
  return MonthlyExpenseSummary(
    year: year,
    month: month,
    totalCents: total,
    itemCount: count,
    categoryTotals: Map.unmodifiable(categoryTotals),
  );
}

Map<int, ExpensePeriodSummary> summarizeExpensesByMonthForPet(
  Iterable<ExpenseEntry> entries, {
  required String petId,
  required int year,
}) {
  final buckets = <int, List<ExpenseEntry>>{};
  for (final entry in entries.where(
    (item) =>
        item.deletedAt == null &&
        item.spentAt.year == year &&
        (item.petId == null || item.petId == petId),
  )) {
    buckets.putIfAbsent(entry.spentAt.month, () => []).add(entry);
  }
  return _expenseSummaryByBucket(buckets);
}

Map<int, ExpensePeriodSummary> summarizeExpensesByDayForPet(
  Iterable<ExpenseEntry> entries, {
  required String petId,
  required int year,
  required int month,
}) {
  final buckets = <int, List<ExpenseEntry>>{};
  for (final entry in entries.where(
    (item) =>
        item.deletedAt == null &&
        item.spentAt.year == year &&
        item.spentAt.month == month &&
        (item.petId == null || item.petId == petId),
  )) {
    buckets.putIfAbsent(entry.spentAt.day, () => []).add(entry);
  }
  return _expenseSummaryByBucket(buckets);
}

Map<int, TimelinePeriodSummary> summarizeTimelineByMonthForPet(
  Iterable<TimelineEvent> events, {
  required String petId,
  required int year,
}) {
  final buckets = <int, List<TimelineEvent>>{};
  for (final event in events.where(
    (item) =>
        item.deletedAt == null &&
        item.petId == petId &&
        item.happenedAt.year == year,
  )) {
    buckets.putIfAbsent(event.happenedAt.month, () => []).add(event);
  }
  return _timelineSummaryByBucket(buckets);
}

Map<int, TimelinePeriodSummary> summarizeTimelineByDayForPet(
  Iterable<TimelineEvent> events, {
  required String petId,
  required int year,
  required int month,
}) {
  final buckets = <int, List<TimelineEvent>>{};
  for (final event in events.where(
    (item) =>
        item.deletedAt == null &&
        item.petId == petId &&
        item.happenedAt.year == year &&
        item.happenedAt.month == month,
  )) {
    buckets.putIfAbsent(event.happenedAt.day, () => []).add(event);
  }
  return _timelineSummaryByBucket(buckets);
}

Map<int, TodoPeriodSummary> summarizeTodosByMonthForPet(
  Iterable<TodoItem> todos, {
  required String petId,
  required int year,
  required DateTime asOf,
}) {
  final buckets = <int, List<TodoItem>>{};
  for (final todo in todos.where(
    (item) =>
        item.deletedAt == null &&
        item.petId == petId &&
        (item.dueAt ?? item.createdAt).year == year,
  )) {
    buckets
        .putIfAbsent((todo.dueAt ?? todo.createdAt).month, () => [])
        .add(todo);
  }
  return _todoSummaryByBucket(buckets, asOf);
}

Map<int, TodoPeriodSummary> summarizeTodosByDayForPet(
  Iterable<TodoItem> todos, {
  required String petId,
  required int year,
  required int month,
  required DateTime asOf,
}) {
  final buckets = <int, List<TodoItem>>{};
  for (final todo in todos.where((item) {
    final date = item.dueAt ?? item.createdAt;
    return item.deletedAt == null &&
        item.petId == petId &&
        date.year == year &&
        date.month == month;
  })) {
    buckets.putIfAbsent((todo.dueAt ?? todo.createdAt).day, () => []).add(todo);
  }
  return _todoSummaryByBucket(buckets, asOf);
}

TimelineEventType inferTimelineEventType({String? mediaPath}) {
  if (mediaPath == null || mediaPath.isEmpty) {
    return TimelineEventType.record;
  }
  final lower = mediaPath.toLowerCase();
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.webm')) {
    return TimelineEventType.video;
  }
  return TimelineEventType.photo;
}

List<TimelineMonthGroup> groupTimelineByMonth(Iterable<MediaAsset> assets) {
  final buckets = <String, List<MediaAsset>>{};
  for (final asset in assets.where((item) => item.deletedAt == null)) {
    final key =
        '${asset.capturedAt.year.toString().padLeft(4, '0')}-'
        '${asset.capturedAt.month.toString().padLeft(2, '0')}';
    buckets.putIfAbsent(key, () => []).add(asset);
  }
  final groups = buckets.entries.map((entry) {
    final items = [...entry.value]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return TimelineMonthGroup(monthKey: entry.key, items: items);
  }).toList()..sort((a, b) => b.monthKey.compareTo(a.monthKey));
  return groups;
}

List<DateGroup<TimelineEvent>> groupTimelineEventsByDay(
  Iterable<TimelineEvent> events,
) {
  return _groupByDay(
    events.where((event) => event.deletedAt == null),
    (event) => event.happenedAt,
    descending: true,
  );
}

List<DateGroup<TodoItem>> groupTodosByDay(Iterable<TodoItem> todos) {
  return _groupByDay(
    todos.where((todo) => todo.deletedAt == null && todo.dueAt != null),
    (todo) => todo.dueAt!,
    descending: false,
  );
}

List<DateGroup<ExpenseEntry>> groupExpensesByDay(
  Iterable<ExpenseEntry> expenses,
) {
  return _groupByDay(
    expenses.where((expense) => expense.deletedAt == null),
    (expense) => expense.spentAt,
    descending: true,
  );
}

VaccineSummary summarizeVaccines(Iterable<CareRecord> records) {
  final monthCounts = <String, int>{};
  var totalCount = 0;
  for (final record in records) {
    if (record.deletedAt != null || record.category != CareCategory.vaccine) {
      continue;
    }
    totalCount += 1;
    final key = _monthKey(record.happenedAt);
    monthCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
  }
  return VaccineSummary(
    totalCount: totalCount,
    monthCounts: Map.unmodifiable(monthCounts),
  );
}

Map<int, ExpensePeriodSummary> _expenseSummaryByBucket(
  Map<int, List<ExpenseEntry>> buckets,
) {
  return {
    for (final entry in buckets.entries)
      entry.key: ExpensePeriodSummary.from(entry.value),
  };
}

Map<int, TimelinePeriodSummary> _timelineSummaryByBucket(
  Map<int, List<TimelineEvent>> buckets,
) {
  return {
    for (final entry in buckets.entries)
      entry.key: TimelinePeriodSummary.from(entry.value),
  };
}

Map<int, TodoPeriodSummary> _todoSummaryByBucket(
  Map<int, List<TodoItem>> buckets,
  DateTime asOf,
) {
  return {
    for (final entry in buckets.entries)
      entry.key: TodoPeriodSummary.from(entry.value, asOf: asOf),
  };
}

List<DateGroup<T>> _groupByDay<T>(
  Iterable<T> items,
  DateTime Function(T item) dateOf, {
  required bool descending,
}) {
  final buckets = <String, List<T>>{};
  final dates = <String, DateTime>{};
  for (final item in items) {
    final date = dateOf(item);
    final day = DateTime(date.year, date.month, date.day);
    final key = _dayKey(day);
    buckets.putIfAbsent(key, () => []).add(item);
    dates[key] = day;
  }
  final groups = buckets.entries.map((entry) {
    final day = dates[entry.key]!;
    final groupedItems = [...entry.value]
      ..sort((a, b) => dateOf(b).compareTo(dateOf(a)));
    return DateGroup<T>(
      key: entry.key,
      year: day.year,
      month: day.month,
      day: day.day,
      items: groupedItems,
    );
  }).toList();
  groups.sort(
    (a, b) => descending ? b.key.compareTo(a.key) : a.key.compareTo(b.key),
  );
  return groups;
}

String _monthKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}';

String _dayKey(DateTime date) =>
    '${_monthKey(date)}-${date.day.toString().padLeft(2, '0')}';

class MonthlyExpenseSummary {
  const MonthlyExpenseSummary({
    required this.year,
    required this.month,
    required this.totalCents,
    required this.itemCount,
    required this.categoryTotals,
  });

  final int year;
  final int month;
  final int totalCents;
  final int itemCount;
  final Map<ExpenseCategory, int> categoryTotals;
}

class TimelineMonthGroup {
  const TimelineMonthGroup({required this.monthKey, required this.items});

  final String monthKey;
  final List<MediaAsset> items;
}

class DateGroup<T> {
  const DateGroup({
    required this.key,
    required this.year,
    required this.month,
    required this.day,
    required this.items,
  });

  final String key;
  final int year;
  final int month;
  final int day;
  final List<T> items;
}

class VaccineSummary {
  const VaccineSummary({required this.totalCount, required this.monthCounts});

  final int totalCount;
  final Map<String, int> monthCounts;
}

class ExpensePeriodSummary {
  const ExpensePeriodSummary({
    required this.totalCents,
    required this.itemCount,
    required this.categoryTotals,
  });

  final int totalCents;
  final int itemCount;
  final Map<ExpenseCategory, int> categoryTotals;

  factory ExpensePeriodSummary.from(Iterable<ExpenseEntry> entries) {
    final categoryTotals = <ExpenseCategory, int>{};
    var totalCents = 0;
    var itemCount = 0;
    for (final entry in entries) {
      totalCents += entry.amountCents;
      itemCount += 1;
      categoryTotals.update(
        entry.category,
        (value) => value + entry.amountCents,
        ifAbsent: () => entry.amountCents,
      );
    }
    return ExpensePeriodSummary(
      totalCents: totalCents,
      itemCount: itemCount,
      categoryTotals: Map.unmodifiable(categoryTotals),
    );
  }
}

class TimelinePeriodSummary {
  const TimelinePeriodSummary({
    required this.eventCount,
    required this.mediaCount,
    required this.careCount,
    required this.typeCounts,
    this.latestTitle,
  });

  final int eventCount;
  final int mediaCount;
  final int careCount;
  final Map<TimelineEventType, int> typeCounts;
  final String? latestTitle;

  factory TimelinePeriodSummary.from(Iterable<TimelineEvent> events) {
    final items = [...events]
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    final typeCounts = <TimelineEventType, int>{};
    var mediaCount = 0;
    var careCount = 0;
    for (final event in items) {
      typeCounts.update(event.type, (value) => value + 1, ifAbsent: () => 1);
      if (event.type == TimelineEventType.photo ||
          event.type == TimelineEventType.video ||
          event.type == TimelineEventType.media) {
        mediaCount += 1;
      }
      if (event.type == TimelineEventType.vaccine ||
          event.type == TimelineEventType.deworming ||
          event.type == TimelineEventType.report) {
        careCount += 1;
      }
    }
    return TimelinePeriodSummary(
      eventCount: items.length,
      mediaCount: mediaCount,
      careCount: careCount,
      typeCounts: Map.unmodifiable(typeCounts),
      latestTitle: items.isEmpty ? null : items.first.title,
    );
  }
}

class TodoPeriodSummary {
  const TodoPeriodSummary({
    required this.totalCount,
    required this.doneCount,
    required this.overdueCount,
  });

  final int totalCount;
  final int doneCount;
  final int overdueCount;

  factory TodoPeriodSummary.from(
    Iterable<TodoItem> todos, {
    required DateTime asOf,
  }) {
    var totalCount = 0;
    var doneCount = 0;
    var overdueCount = 0;
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    for (final todo in todos) {
      totalCount += 1;
      if (todo.status == TodoStatus.done) {
        doneCount += 1;
      }
      final dueAt = todo.dueAt;
      if (todo.status == TodoStatus.open && dueAt != null) {
        final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
        if (dueDay.isBefore(today)) {
          overdueCount += 1;
        }
      }
    }
    return TodoPeriodSummary(
      totalCount: totalCount,
      doneCount: doneCount,
      overdueCount: overdueCount,
    );
  }
}
