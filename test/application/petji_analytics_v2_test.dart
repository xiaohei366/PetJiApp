import 'package:flutter_test/flutter_test.dart';
import 'package:petji/application/petji_analytics.dart';
import 'package:petji/domain/models.dart';

void main() {
  test('groups timeline events, todos, and expenses by year month day', () {
    final now = DateTime(2026, 6, 1);
    final timelineGroups = groupTimelineEventsByDay([
      TimelineEvent(
        id: 'timeline-1',
        petId: 'pet-1',
        type: TimelineEventType.care,
        happenedAt: DateTime(2026, 6, 1, 10),
        title: 'Bath',
        createdAt: now,
        updatedAt: now,
      ),
      TimelineEvent(
        id: 'timeline-2',
        petId: 'pet-1',
        type: TimelineEventType.note,
        happenedAt: DateTime(2026, 5, 30, 10),
        title: 'Note',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final todoGroups = groupTodosByDay([
      TodoItem(
        id: 'todo-1',
        petId: 'pet-1',
        title: 'Book vaccine',
        status: TodoStatus.open,
        dueAt: DateTime(2026, 6, 5, 9),
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final expenseGroups = groupExpensesByDay([
      ExpenseEntry(
        id: 'expense-1',
        petId: 'pet-1',
        category: ExpenseCategory.food,
        amountCents: 1000,
        spentAt: DateTime(2026, 6, 3, 12),
        title: 'Food',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(timelineGroups.map((group) => group.key), [
      '2026-06-01',
      '2026-05-30',
    ]);
    expect(todoGroups.single.key, '2026-06-05');
    expect(expenseGroups.single.year, 2026);
    expect(expenseGroups.single.month, 6);
    expect(expenseGroups.single.day, 3);
  });

  test('summarizes vaccine care records by count and month', () {
    final now = DateTime(2026, 6, 1);
    final summary = summarizeVaccines([
      CareRecord(
        id: 'care-1',
        petId: 'pet-1',
        category: CareCategory.vaccine,
        happenedAt: DateTime(2026, 6, 1),
        title: 'Vaccine',
        createdAt: now,
        updatedAt: now,
      ),
      CareRecord(
        id: 'care-2',
        petId: 'pet-1',
        category: CareCategory.vaccine,
        happenedAt: DateTime(2026, 6, 20),
        title: 'Vaccine',
        createdAt: now,
        updatedAt: now,
      ),
      CareRecord(
        id: 'care-3',
        petId: 'pet-1',
        category: CareCategory.bath,
        happenedAt: DateTime(2026, 6, 21),
        title: 'Bath',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(summary.totalCount, 2);
    expect(summary.monthCounts, {'2026-06': 2});
  });

  test(
    'summarizes pet expense report by year and month with shared expenses',
    () {
      final entries = [
        ExpenseEntry(
          id: 'pet-june-food',
          petId: 'pet-1',
          category: ExpenseCategory.food,
          amountCents: 1000,
          spentAt: DateTime(2026, 6, 1),
          title: 'Food',
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
        ExpenseEntry(
          id: 'shared-june-toy',
          petId: null,
          category: ExpenseCategory.toy,
          amountCents: 500,
          spentAt: DateTime(2026, 6, 2),
          title: 'Shared toy',
          createdAt: DateTime(2026, 6, 2),
          updatedAt: DateTime(2026, 6, 2),
        ),
        ExpenseEntry(
          id: 'other-pet-june',
          petId: 'pet-2',
          category: ExpenseCategory.medical,
          amountCents: 9000,
          spentAt: DateTime(2026, 6, 2),
          title: 'Other pet',
          createdAt: DateTime(2026, 6, 2),
          updatedAt: DateTime(2026, 6, 2),
        ),
        ExpenseEntry(
          id: 'pet-july',
          petId: 'pet-1',
          category: ExpenseCategory.medical,
          amountCents: 2000,
          spentAt: DateTime(2026, 7, 3),
          title: 'Medical',
          createdAt: DateTime(2026, 7, 3),
          updatedAt: DateTime(2026, 7, 3),
        ),
      ];

      final byMonth = summarizeExpensesByMonthForPet(
        entries,
        petId: 'pet-1',
        year: 2026,
      );
      final byDay = summarizeExpensesByDayForPet(
        entries,
        petId: 'pet-1',
        year: 2026,
        month: 6,
      );

      expect(byMonth[6]?.totalCents, 1500);
      expect(byMonth[6]?.itemCount, 2);
      expect(byMonth[7]?.totalCents, 2000);
      expect(byMonth.containsKey(5), isFalse);
      expect(byDay[2]?.categoryTotals[ExpenseCategory.toy], 500);
      expect(
        byDay[2]?.categoryTotals.containsKey(ExpenseCategory.medical),
        isFalse,
      );
    },
  );

  test('summarizes timeline and todo drilldown buckets for one pet', () {
    final now = DateTime(2026, 6, 10);
    final timeline = [
      TimelineEvent(
        id: 'photo',
        petId: 'pet-1',
        type: TimelineEventType.photo,
        happenedAt: DateTime(2026, 6, 1),
        title: 'Photo',
        createdAt: now,
        updatedAt: now,
      ),
      TimelineEvent(
        id: 'vaccine',
        petId: 'pet-1',
        type: TimelineEventType.vaccine,
        happenedAt: DateTime(2026, 6, 1),
        title: 'Vaccine',
        createdAt: now,
        updatedAt: now,
      ),
      TimelineEvent(
        id: 'other',
        petId: 'pet-2',
        type: TimelineEventType.video,
        happenedAt: DateTime(2026, 6, 1),
        title: 'Other',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final todos = [
      TodoItem(
        id: 'open',
        petId: 'pet-1',
        title: 'Open',
        status: TodoStatus.open,
        dueAt: DateTime(2026, 6, 2),
        createdAt: now,
        updatedAt: now,
      ),
      TodoItem(
        id: 'done',
        petId: 'pet-1',
        title: 'Done',
        status: TodoStatus.done,
        dueAt: DateTime(2026, 6, 2),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final timelineMonths = summarizeTimelineByMonthForPet(
      timeline,
      petId: 'pet-1',
      year: 2026,
    );
    final todoDays = summarizeTodosByDayForPet(
      todos,
      petId: 'pet-1',
      year: 2026,
      month: 6,
      asOf: now,
    );

    expect(timelineMonths[6]?.eventCount, 2);
    expect(timelineMonths[6]?.mediaCount, 1);
    expect(timelineMonths[6]?.careCount, 1);
    expect(todoDays[2]?.totalCount, 2);
    expect(todoDays[2]?.doneCount, 1);
  });

  test('infers timeline event type from selected media path', () {
    expect(inferTimelineEventType(mediaPath: null), TimelineEventType.record);
    expect(
      inferTimelineEventType(mediaPath: 'C:/petji/media/photo.JPG'),
      TimelineEventType.photo,
    );
    expect(
      inferTimelineEventType(mediaPath: 'C:/petji/media/movie.mp4'),
      TimelineEventType.video,
    );
  });
}
