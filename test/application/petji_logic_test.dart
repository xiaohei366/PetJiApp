import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:petji/application/backup_codec.dart';
import 'package:petji/application/petji_analytics.dart';
import 'package:petji/domain/models.dart';

void main() {
  test('creates next reminder from an editable care rule', () {
    final record = CareRecord(
      id: 'record-1',
      petId: 'pet-1',
      category: CareCategory.bath,
      happenedAt: DateTime(2026, 5, 10, 18, 30),
      title: '洗澡',
      createdAt: DateTime(2026, 5, 10, 18, 40),
      updatedAt: DateTime(2026, 5, 10, 18, 40),
    );
    final rule = ReminderRule(
      id: 'rule-bath',
      category: CareCategory.bath,
      intervalDays: 30,
      titleTemplate: '该给{name}洗澡了',
    );

    final reminder = createReminderFromRecord(
      record: record,
      petName: 'Momo',
      rule: rule,
      createdAt: DateTime(2026, 5, 10, 18, 45),
    );

    expect(reminder.petId, 'pet-1');
    expect(reminder.title, '该给Momo洗澡了');
    expect(reminder.dueAt, DateTime(2026, 6, 9, 18, 30));
    expect(reminder.sourceRecordId, 'record-1');
  });

  test('summarizes pet expenses by month and category', () {
    final entries = [
      ExpenseEntry(
        id: 'expense-1',
        petId: 'pet-1',
        category: ExpenseCategory.food,
        amountCents: 12990,
        spentAt: DateTime(2026, 6, 1),
        title: '猫粮',
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      ),
      ExpenseEntry(
        id: 'expense-2',
        petId: null,
        category: ExpenseCategory.medical,
        amountCents: 8600,
        spentAt: DateTime(2026, 6, 15),
        title: '体检',
        createdAt: DateTime(2026, 6, 15),
        updatedAt: DateTime(2026, 6, 15),
      ),
      ExpenseEntry(
        id: 'expense-3',
        petId: 'pet-1',
        category: ExpenseCategory.toy,
        amountCents: 3500,
        spentAt: DateTime(2026, 5, 20),
        title: '玩具',
        createdAt: DateTime(2026, 5, 20),
        updatedAt: DateTime(2026, 5, 20),
      ),
    ];

    final summary = summarizeMonthlyExpenses(entries, year: 2026, month: 6);

    expect(summary.totalCents, 21590);
    expect(summary.itemCount, 2);
    expect(summary.categoryTotals[ExpenseCategory.food], 12990);
    expect(summary.categoryTotals[ExpenseCategory.medical], 8600);
    expect(summary.categoryTotals.containsKey(ExpenseCategory.toy), isFalse);
  });

  test('groups timeline media by newest month first', () {
    final assets = [
      MediaAsset(
        id: 'media-1',
        petId: 'pet-1',
        type: MediaType.photo,
        localPath: 'app://media/one.jpg',
        capturedAt: DateTime(2026, 5, 2),
        createdAt: DateTime(2026, 5, 2),
        updatedAt: DateTime(2026, 5, 2),
      ),
      MediaAsset(
        id: 'media-2',
        petId: 'pet-1',
        type: MediaType.video,
        localPath: 'app://media/two.mp4',
        capturedAt: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      ),
    ];

    final groups = groupTimelineByMonth(assets);

    expect(groups.map((group) => group.monthKey), ['2026-06', '2026-05']);
    expect(groups.first.items.single.id, 'media-2');
  });

  test('round trips backup snapshot through JSON', () {
    final snapshot = AppSnapshot.seed(now: DateTime(2026, 6, 1));

    final encoded = BackupCodec.encode(snapshot);
    final decoded = BackupCodec.decode(encoded);

    expect(decoded.version, 2);
    expect(decoded.pets.first.name, snapshot.pets.first.name);
    expect(decoded.records.length, snapshot.records.length);
    expect(decoded.expenses.length, snapshot.expenses.length);
  });

  test('migrates v1 backup json to v2 with an active first pet', () {
    final source = AppSnapshot.seed(now: DateTime(2026, 6, 1)).toJson()
      ..['version'] = 1
      ..remove('activePetId')
      ..remove('todos')
      ..remove('timelineEvents');

    final decoded = BackupCodec.decode(jsonEncode(source));

    expect(decoded.version, 2);
    expect(decoded.activePetId, decoded.pets.first.id);
    expect(decoded.currentPet?.name, 'Momo');
  });
}
