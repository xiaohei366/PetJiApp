import 'package:flutter_test/flutter_test.dart';
import 'package:petji/application/app_providers.dart';
import 'package:petji/application/notification_scheduler.dart';
import 'package:petji/domain/models.dart';

void main() {
  test('registerPet creates the first pet and makes it active', () {
    final controller = PetjiController(
      AppSnapshot.empty(now: DateTime(2026, 6, 1, 8)),
      clock: () => DateTime(2026, 6, 1, 8),
    );

    final pet = controller.registerPet(
      name: 'Momo',
      species: PetSpecies.cat,
      breed: 'British Shorthair',
      birthday: DateTime(2024, 1, 15),
      sex: PetSex.female,
      isNeutered: true,
    );

    expect(controller.currentPet, pet);
    expect(controller.state.activePetId, pet.id);
    expect(controller.state.pets.single.name, 'Momo');
  });

  test('records feeding, weight, todo, and expense for the active pet', () {
    final now = DateTime(2026, 6, 1, 8);
    final controller = PetjiController(
      AppSnapshot.empty(now: now),
      clock: () => now,
    );
    final pet = controller.registerPet(
      name: 'Momo',
      species: PetSpecies.cat,
      breed: '',
      birthday: DateTime(2024, 1, 15),
      sex: PetSex.unknown,
      isNeutered: false,
    );

    final feeding = controller.addFeeding(amountGrams: 42);
    final weight = controller.addWeight(grams: 4200);
    final todo = controller.addTodo(
      title: 'Book vaccine',
      dueAt: DateTime(2026, 6, 5),
    );
    final expense = controller.addExpense(
      title: 'Food',
      amountCents: 1200,
      date: DateTime(2026, 6, 2),
      category: ExpenseCategory.food,
    );
    controller.toggleTodo(todo.id);

    expect(feeding.petId, pet.id);
    expect(feeding.amountGrams, 42);
    expect(weight.grams, 4200);
    expect(expense.spentAt, DateTime(2026, 6, 2));
    expect(controller.state.todos.single.status, TodoStatus.done);
  });

  test(
    'addCare stores file and media paths, creates timeline event and reminder',
    () {
      final scheduler = FakeNotificationScheduler();
      final now = DateTime(2026, 6, 1, 8);
      final controller = PetjiController(
        AppSnapshot.empty(now: now),
        notificationScheduler: scheduler,
        clock: () => now,
      );
      final pet = controller.registerPet(
        name: 'Momo',
        species: PetSpecies.cat,
        breed: '',
        birthday: DateTime(2024, 1, 15),
        sex: PetSex.unknown,
        isNeutered: false,
      );

      final care = controller.addCare(
        CareCategory.vaccine,
        date: DateTime(2026, 6, 2, 10),
        title: 'Annual vaccine',
        note: 'Left shoulder',
        filePath: 'files/vaccine.pdf',
        mediaPath: 'media/vaccine.jpg',
      );

      expect(care.petId, pet.id);
      expect(care.reportPath, 'files/vaccine.pdf');
      expect(controller.state.timelineEvents.single.sourceId, care.id);
      expect(
        controller.state.timelineEvents.single.mediaPath,
        'media/vaccine.jpg',
      );
      expect(controller.state.reminders.single.sourceRecordId, care.id);
      expect(
        scheduler.scheduledReminders.single.id,
        controller.state.reminders.single.id,
      );
    },
  );

  test('importSnapshot replaces controller state', () {
    final controller = PetjiController(
      AppSnapshot.empty(now: DateTime(2026, 6, 1)),
      clock: () => DateTime(2026, 6, 2),
    );
    final imported = AppSnapshot.empty(
      now: DateTime(2026, 6, 2),
    ).copyWith(activePetId: 'pet-imported');

    controller.importSnapshot(imported);

    expect(controller.state.activePetId, imported.activePetId);
    expect(controller.state.exportedAt, DateTime(2026, 6, 2));
  });

  test(
    'importSnapshot cancels old notifications and schedules imported ones',
    () {
      final scheduler = FakeNotificationScheduler();
      final now = DateTime(2026, 6, 1, 8);
      final oldSnapshot = AppSnapshot.empty(now: now).copyWith(
        reminders: [
          Reminder(
            id: 'old-reminder',
            petId: 'pet-1',
            title: '旧提醒',
            dueAt: DateTime(2026, 6, 10),
            status: ReminderStatus.scheduled,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        todos: [
          TodoItem(
            id: 'old-todo',
            petId: 'pet-1',
            title: '旧待办',
            status: TodoStatus.open,
            dueAt: DateTime(2026, 6, 3),
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      final importedSnapshot = AppSnapshot.empty(now: now).copyWith(
        reminders: [
          Reminder(
            id: 'new-reminder',
            petId: 'pet-1',
            title: '新提醒',
            dueAt: DateTime(2026, 6, 12),
            status: ReminderStatus.scheduled,
            createdAt: now,
            updatedAt: now,
          ),
          Reminder(
            id: 'done-reminder',
            petId: 'pet-1',
            title: '已完成提醒',
            dueAt: DateTime(2026, 6, 12),
            status: ReminderStatus.done,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        todos: [
          TodoItem(
            id: 'new-todo',
            petId: 'pet-1',
            title: '新待办',
            status: TodoStatus.open,
            dueAt: DateTime(2026, 6, 5),
            createdAt: now,
            updatedAt: now,
          ),
          TodoItem(
            id: 'done-todo',
            petId: 'pet-1',
            title: '已完成待办',
            status: TodoStatus.done,
            dueAt: DateTime(2026, 6, 5),
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      final controller = PetjiController(
        oldSnapshot,
        notificationScheduler: scheduler,
        clock: () => now,
      );

      controller.importSnapshot(importedSnapshot);

      expect(scheduler.canceledReminderIds, ['old-reminder']);
      expect(scheduler.canceledTodoIds, ['old-todo']);
      expect(scheduler.scheduledReminders.map((item) => item.id), [
        'new-reminder',
      ]);
      expect(scheduler.scheduledTodos.map((item) => item.id), ['new-todo']);
    },
  );

  test('switches active pet and hard deletes all pet-owned data', () {
    final scheduler = FakeNotificationScheduler();
    final now = DateTime(2026, 6, 1, 8);
    final controller = PetjiController(
      AppSnapshot.empty(now: now),
      notificationScheduler: scheduler,
      clock: () => now,
    );
    final first = controller.registerPet(
      name: 'Momo',
      species: PetSpecies.cat,
      breed: '',
      birthday: DateTime(2024, 1, 15),
    );
    final second = controller.registerPet(
      name: 'Bao',
      species: PetSpecies.dog,
      breed: '',
      birthday: DateTime(2023, 2, 20),
    );

    controller.addWeight(grams: 4200);
    final todo = controller.addTodo(
      title: 'Book vaccine',
      dueAt: DateTime(2026, 6, 5),
    );
    controller.addCare(CareCategory.vaccine, title: 'Annual vaccine');
    controller.addExpense(
      title: 'Shared litter',
      amountCents: 5000,
      shared: true,
    );
    controller.switchActivePet(second.id);
    controller.addWeight(grams: 8500);
    controller.addExpense(title: 'Dog food', amountCents: 12000);

    controller.deletePetHard(first.id);

    expect(controller.state.currentPet?.id, second.id);
    expect(controller.state.pets.map((pet) => pet.id), [second.id]);
    expect(controller.state.weightRecords.map((item) => item.petId), [
      second.id,
    ]);
    expect(controller.state.todos.any((item) => item.id == todo.id), isFalse);
    expect(
      controller.state.records.any((item) => item.petId == first.id),
      isFalse,
    );
    expect(
      controller.state.timelineEvents.any((item) => item.petId == first.id),
      isFalse,
    );
    expect(controller.state.expenses.map((item) => item.title), [
      'Shared litter',
      'Dog food',
    ]);
    expect(scheduler.canceledTodoIds, contains(todo.id));
    expect(scheduler.canceledReminderIds, isNotEmpty);
  });

  test('imports petji bundle data as new pet profiles with rewritten ids', () {
    final now = DateTime(2026, 6, 1, 8);
    final controller = PetjiController(
      AppSnapshot.empty(now: now),
      clock: () => now,
    );
    final existing = controller.registerPet(
      name: 'Existing',
      species: PetSpecies.cat,
      breed: '',
      birthday: DateTime(2024, 1, 15),
    );
    final imported = AppSnapshot.empty(now: now).copyWith(
      activePetId: 'old-pet',
      pets: [
        PetProfile(
          id: 'old-pet',
          name: 'Imported',
          species: PetSpecies.dog,
          breed: '',
          birthday: DateTime(2023, 3, 1),
          sex: PetSex.unknown,
          isNeutered: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      records: [
        CareRecord(
          id: 'old-care',
          petId: 'old-pet',
          category: CareCategory.vaccine,
          happenedAt: now,
          title: 'Old vaccine',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      timelineEvents: [
        TimelineEvent(
          id: 'old-event',
          petId: 'old-pet',
          type: TimelineEventType.vaccine,
          happenedAt: now,
          title: 'Old vaccine',
          sourceId: 'old-care',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      expenses: [
        ExpenseEntry(
          id: 'old-shared-expense',
          petId: null,
          category: ExpenseCategory.food,
          amountCents: 3000,
          spentAt: now,
          title: 'Imported shared',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      todos: [
        TodoItem(
          id: 'old-todo',
          petId: null,
          title: 'Imported todo',
          status: TodoStatus.open,
          dueAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    controller.importSnapshotAsPetProfiles(imported);

    expect(controller.state.pets.length, 2);
    expect(controller.state.pets.first.id, existing.id);
    final importedPet = controller.state.currentPet!;
    expect(importedPet.name, 'Imported');
    expect(importedPet.id, isNot('old-pet'));
    expect(controller.state.records.single.petId, importedPet.id);
    expect(controller.state.records.single.id, isNot('old-care'));
    expect(controller.state.timelineEvents.single.petId, importedPet.id);
    expect(
      controller.state.timelineEvents.single.sourceId,
      controller.state.records.single.id,
    );
    expect(controller.state.expenses.single.petId, importedPet.id);
    expect(controller.state.todos.single.petId, importedPet.id);
  });
}
