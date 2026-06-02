import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import 'backup_codec.dart';
import 'notification_scheduler.dart';
import 'petji_analytics.dart';

const _uuid = Uuid();

typedef SnapshotPersist = Future<void> Function(AppSnapshot snapshot);

final appSnapshotProvider = StateNotifierProvider<PetjiController, AppSnapshot>(
  (ref) => PetjiController(AppSnapshot.empty(now: DateTime.now())),
);

class PetjiController extends StateNotifier<AppSnapshot> {
  PetjiController(
    super.state, {
    NotificationScheduler notificationScheduler =
        const NoopNotificationScheduler(),
    this._persistSnapshot,
    DateTime Function()? clock,
  }) : _notificationScheduler = _scheduler(notificationScheduler),
       _clock = clock ?? DateTime.now;

  final NotificationScheduler _notificationScheduler;
  final SnapshotPersist? _persistSnapshot;
  final DateTime Function() _clock;

  PetProfile? get currentPet => state.currentPet;

  DateTime get _now => _clock();

  void switchActivePet(String petId) {
    final exists = state.pets.any(
      (pet) => pet.id == petId && pet.deletedAt == null,
    );
    if (!exists) {
      throw StateError('Pet profile does not exist: $petId');
    }
    _commit(state.copyWith(activePetId: petId));
  }

  PetProfile registerPet({
    required String name,
    required DateTime birthday,
    PetSpecies species = PetSpecies.cat,
    String breed = '',
    PetSex sex = PetSex.unknown,
    bool isNeutered = false,
    String? avatarPath,
    String? notes,
  }) {
    final now = _now;
    final pet = PetProfile(
      id: _uuid.v4(),
      name: name.trim(),
      species: species,
      breed: breed.trim(),
      birthday: birthday,
      sex: sex,
      isNeutered: isNeutered,
      avatarPath: avatarPath,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _commit(
      state.copyWith(
        activePetId: state.activePetId ?? pet.id,
        pets: [...state.pets, pet],
      ),
    );
    return pet;
  }

  WeightRecord addWeight({
    required int grams,
    DateTime? measuredAt,
    String? note,
  }) {
    final pet = _requireCurrentPet();
    final now = _now;
    final record = WeightRecord(
      id: _uuid.v4(),
      petId: pet.id,
      grams: grams,
      measuredAt: measuredAt ?? now,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    final event = TimelineEvent(
      id: _uuid.v5(Namespace.url.value, 'timeline:${record.id}'),
      petId: pet.id,
      type: TimelineEventType.weight,
      happenedAt: record.measuredAt,
      title: '体重 ${(record.grams / 1000).toStringAsFixed(1)}kg',
      sourceId: record.id,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    _commit(
      state.copyWith(
        weightRecords: [...state.weightRecords, record],
        timelineEvents: [...state.timelineEvents, event],
      ),
    );
    return record;
  }

  WeightRecord addWeightKg(double kilograms) {
    return addWeight(grams: (kilograms * 1000).round());
  }

  FeedingRecord addFeeding({
    required int amountGrams,
    DateTime? fedAt,
    String? foodName,
    String? note,
  }) {
    final pet = _requireCurrentPet();
    final now = _now;
    final record = FeedingRecord(
      id: _uuid.v4(),
      petId: pet.id,
      fedAt: fedAt ?? now,
      foodName: foodName ?? '快速喂食',
      amountGrams: amountGrams,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    _commit(state.copyWith(feedingRecords: [...state.feedingRecords, record]));
    return record;
  }

  CareRecord addCare(
    CareCategory category, {
    DateTime? date,
    String? title,
    String? note,
    String? filePath,
    String? mediaPath,
  }) {
    final pet = _requireCurrentPet();
    final now = _now;
    final record = CareRecord(
      id: _uuid.v4(),
      petId: pet.id,
      category: category,
      happenedAt: date ?? now,
      title: title ?? _careTitle(category),
      note: note,
      reportPath: filePath,
      mediaPath: mediaPath,
      createdAt: now,
      updatedAt: now,
    );
    final event = _timelineEventForCare(record, now);
    final newReminders = [
      for (final rule in state.reminderRules)
        if (rule.enabled && rule.category == category)
          createReminderFromRecord(
            record: record,
            petName: pet.name,
            rule: rule,
            createdAt: now,
          ),
    ];
    for (final reminder in newReminders) {
      _notificationScheduler.scheduleReminder(reminder);
    }
    _commit(
      state.copyWith(
        records: [...state.records, record],
        timelineEvents: [...state.timelineEvents, event],
        reminders: [...state.reminders, ...newReminders],
      ),
    );
    return record;
  }

  TimelineEvent addTimelineEvent({
    TimelineEventType? type,
    required DateTime happenedAt,
    required String title,
    String? note,
    String? filePath,
    String? mediaPath,
    String? sourceId,
  }) {
    final pet = _requireCurrentPet();
    final now = _now;
    final event = TimelineEvent(
      id: _uuid.v4(),
      petId: pet.id,
      type: type ?? inferTimelineEventType(mediaPath: mediaPath),
      happenedAt: happenedAt,
      title: title.trim(),
      sourceId: sourceId,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      filePath: filePath,
      mediaPath: mediaPath,
      createdAt: now,
      updatedAt: now,
    );
    _commit(state.copyWith(timelineEvents: [...state.timelineEvents, event]));
    return event;
  }

  TodoItem addTodo({required String title, DateTime? dueAt, String? note}) {
    final now = _now;
    final todo = TodoItem(
      id: _uuid.v4(),
      petId: currentPet?.id,
      title: title.trim(),
      status: TodoStatus.open,
      dueAt: dueAt,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _notificationScheduler.scheduleTodo(todo);
    _commit(state.copyWith(todos: [...state.todos, todo]));
    return todo;
  }

  void toggleTodo(String todoId) {
    final now = _now;
    _commit(
      state.copyWith(
        todos: [
          for (final todo in state.todos)
            if (todo.id == todoId) _toggleTodo(todo, now) else todo,
        ],
      ),
    );
  }

  ExpenseEntry addExpense({
    required String title,
    required int amountCents,
    DateTime? date,
    ExpenseCategory category = ExpenseCategory.supplies,
    bool shared = false,
    String? merchant,
    String? note,
  }) {
    final now = _now;
    final entry = ExpenseEntry(
      id: _uuid.v4(),
      petId: shared ? null : currentPet?.id,
      category: category,
      amountCents: amountCents,
      spentAt: date ?? now,
      title: title.trim(),
      merchant: merchant,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    _commit(state.copyWith(expenses: [...state.expenses, entry]));
    return entry;
  }

  void deletePetHard(String petId) {
    final petExists = state.pets.any((pet) => pet.id == petId);
    if (!petExists) {
      throw StateError('Pet profile does not exist: $petId');
    }
    final filePaths = <String>{
      for (final pet in state.pets)
        if (pet.id == petId && pet.avatarPath != null) pet.avatarPath!,
      for (final record in state.records)
        if (record.petId == petId) ...[
          if (record.reportPath != null) record.reportPath!,
          if (record.mediaPath != null) record.mediaPath!,
        ],
      for (final media in state.mediaAssets)
        if (media.petId == petId) media.localPath,
      for (final event in state.timelineEvents)
        if (event.petId == petId) ...[
          if (event.filePath != null) event.filePath!,
          if (event.mediaPath != null) event.mediaPath!,
        ],
    };
    for (final reminder in state.reminders) {
      if (reminder.petId == petId &&
          reminder.status == ReminderStatus.scheduled) {
        _notificationScheduler.cancelReminder(reminder.id);
      }
    }
    for (final todo in state.todos) {
      if (todo.petId == petId && todo.status == TodoStatus.open) {
        _notificationScheduler.cancelTodo(todo.id);
      }
    }
    final remainingPets = state.pets
        .where((pet) => pet.id != petId && pet.deletedAt == null)
        .toList();
    final nextActivePetId = state.activePetId == petId
        ? remainingPets.firstOrNull?.id
        : state.activePetId;
    _commit(
      state.copyWith(
        activePetId: nextActivePetId,
        pets: state.pets.where((pet) => pet.id != petId).toList(),
        weightRecords: state.weightRecords
            .where((record) => record.petId != petId)
            .toList(),
        feedingRecords: state.feedingRecords
            .where((record) => record.petId != petId)
            .toList(),
        records: state.records
            .where((record) => record.petId != petId)
            .toList(),
        reminders: state.reminders
            .where((reminder) => reminder.petId != petId)
            .toList(),
        mediaAssets: state.mediaAssets
            .where((media) => media.petId != petId)
            .toList(),
        expenses: state.expenses
            .where((expense) => expense.petId == null || expense.petId != petId)
            .toList(),
        todos: state.todos.where((todo) => todo.petId != petId).toList(),
        timelineEvents: state.timelineEvents
            .where((event) => event.petId != petId)
            .toList(),
      ),
    );
    for (final path in filePaths) {
      unawaited(_deleteManagedFile(path));
    }
  }

  void importSnapshot(AppSnapshot snapshot) {
    _cancelSnapshotNotifications(state);
    _commit(snapshot.copyWith(exportedAt: _now));
    _scheduleSnapshotNotifications(state);
  }

  void importSnapshotAsPetProfiles(AppSnapshot imported) {
    final sourcePets = imported.pets
        .where((pet) => pet.deletedAt == null)
        .toList();
    if (sourcePets.isEmpty) {
      throw const FormatException(
        'Petji bundle does not contain pet profiles.',
      );
    }
    final now = _now;
    final petIdMap = <String, String>{};
    final resourceIdMap = <String, String>{};
    final importedPets = <PetProfile>[];
    for (final pet in sourcePets) {
      final id = _uuid.v4();
      petIdMap[pet.id] = id;
      resourceIdMap[pet.id] = id;
      importedPets.add(
        PetProfile(
          id: id,
          name: pet.name,
          species: pet.species,
          breed: pet.breed,
          birthday: pet.birthday,
          sex: pet.sex,
          isNeutered: pet.isNeutered,
          avatarPath: pet.avatarPath,
          notes: pet.notes,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    final fallbackPetId = importedPets.first.id;

    final importedWeights = [
      for (final record in imported.weightRecords)
        if (record.deletedAt == null && petIdMap.containsKey(record.petId))
          _copyWeight(record, petIdMap[record.petId]!, now, resourceIdMap),
    ];
    final importedFeedings = [
      for (final record in imported.feedingRecords)
        if (record.deletedAt == null && petIdMap.containsKey(record.petId))
          _copyFeeding(record, petIdMap[record.petId]!, now, resourceIdMap),
    ];
    final importedRecords = [
      for (final record in imported.records)
        if (record.deletedAt == null && petIdMap.containsKey(record.petId))
          _copyCare(record, petIdMap[record.petId]!, now, resourceIdMap),
    ];
    final importedMedia = [
      for (final media in imported.mediaAssets)
        if (media.deletedAt == null && petIdMap.containsKey(media.petId))
          _copyMedia(media, petIdMap[media.petId]!, now, resourceIdMap),
    ];
    final importedReminders = [
      for (final reminder in imported.reminders)
        if (reminder.deletedAt == null && petIdMap.containsKey(reminder.petId))
          _copyReminder(
            reminder,
            petIdMap[reminder.petId]!,
            now,
            resourceIdMap,
          ),
    ];
    final importedTodos = [
      for (final todo in imported.todos)
        if (todo.deletedAt == null)
          _copyTodo(
            todo,
            petIdMap[todo.petId] ?? fallbackPetId,
            now,
            resourceIdMap,
          ),
    ];
    final importedExpenses = [
      for (final expense in imported.expenses)
        if (expense.deletedAt == null)
          _copyExpense(
            expense,
            petIdMap[expense.petId] ?? fallbackPetId,
            now,
            resourceIdMap,
          ),
    ];
    final importedTimeline = [
      for (final event in imported.timelineEvents)
        if (event.deletedAt == null &&
            event.petId != null &&
            petIdMap.containsKey(event.petId))
          _copyTimeline(event, petIdMap[event.petId]!, now, resourceIdMap),
    ];

    _commit(
      state.copyWith(
        activePetId: importedPets.first.id,
        pets: [...state.pets, ...importedPets],
        weightRecords: [...state.weightRecords, ...importedWeights],
        feedingRecords: [...state.feedingRecords, ...importedFeedings],
        records: [...state.records, ...importedRecords],
        mediaAssets: [...state.mediaAssets, ...importedMedia],
        reminders: [...state.reminders, ...importedReminders],
        expenses: [...state.expenses, ...importedExpenses],
        todos: [...state.todos, ...importedTodos],
        timelineEvents: [...state.timelineEvents, ...importedTimeline],
      ),
    );
    for (final reminder in importedReminders) {
      if (reminder.status == ReminderStatus.scheduled) {
        _notificationScheduler.scheduleReminder(reminder);
      }
    }
    for (final todo in importedTodos) {
      if (todo.status == TodoStatus.open) {
        _notificationScheduler.scheduleTodo(todo);
      }
    }
  }

  String exportBackupJson() => BackupCodec.encode(state);

  TodoItem _toggleTodo(TodoItem todo, DateTime now) {
    if (todo.status == TodoStatus.open) {
      _notificationScheduler.cancelTodo(todo.id);
      return todo.copyWith(
        status: TodoStatus.done,
        completedAt: now,
        updatedAt: now,
      );
    }
    final reopened = todo.copyWith(
      status: TodoStatus.open,
      completedAt: null,
      updatedAt: now,
    );
    _notificationScheduler.scheduleTodo(reopened);
    return reopened;
  }

  void _cancelSnapshotNotifications(AppSnapshot snapshot) {
    for (final reminder in snapshot.reminders) {
      if (reminder.status == ReminderStatus.scheduled) {
        _notificationScheduler.cancelReminder(reminder.id);
      }
    }
    for (final todo in snapshot.todos) {
      if (todo.status == TodoStatus.open) {
        _notificationScheduler.cancelTodo(todo.id);
      }
    }
  }

  void _scheduleSnapshotNotifications(AppSnapshot snapshot) {
    for (final reminder in snapshot.reminders) {
      if (reminder.status == ReminderStatus.scheduled) {
        _notificationScheduler.scheduleReminder(reminder);
      }
    }
    for (final todo in snapshot.todos) {
      if (todo.status == TodoStatus.open) {
        _notificationScheduler.scheduleTodo(todo);
      }
    }
  }

  void _commit(AppSnapshot next) {
    state = next.copyWith(exportedAt: _now);
    final persist = _persistSnapshot;
    if (persist != null) {
      unawaited(persist(state));
    }
  }

  PetProfile _requireCurrentPet() {
    final pet = currentPet;
    if (pet == null) {
      throw StateError('No active pet selected.');
    }
    return pet;
  }
}

WeightRecord _copyWeight(
  WeightRecord record,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[record.id] = id;
  return WeightRecord(
    id: id,
    petId: petId,
    grams: record.grams,
    measuredAt: record.measuredAt,
    note: record.note,
    createdAt: now,
    updatedAt: now,
  );
}

FeedingRecord _copyFeeding(
  FeedingRecord record,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[record.id] = id;
  return FeedingRecord(
    id: id,
    petId: petId,
    fedAt: record.fedAt,
    foodName: record.foodName,
    amountGrams: record.amountGrams,
    note: record.note,
    createdAt: now,
    updatedAt: now,
  );
}

CareRecord _copyCare(
  CareRecord record,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[record.id] = id;
  return CareRecord(
    id: id,
    petId: petId,
    category: record.category,
    happenedAt: record.happenedAt,
    title: record.title,
    note: record.note,
    reportPath: record.reportPath,
    mediaPath: record.mediaPath,
    createdAt: now,
    updatedAt: now,
  );
}

MediaAsset _copyMedia(
  MediaAsset media,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[media.id] = id;
  return MediaAsset(
    id: id,
    petId: petId,
    type: media.type,
    localPath: media.localPath,
    capturedAt: media.capturedAt,
    note: media.note,
    createdAt: now,
    updatedAt: now,
  );
}

Reminder _copyReminder(
  Reminder reminder,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[reminder.id] = id;
  return Reminder(
    id: id,
    petId: petId,
    title: reminder.title,
    dueAt: reminder.dueAt,
    status: reminder.status,
    sourceRecordId: _mappedNullable(reminder.sourceRecordId, resourceIdMap),
    createdAt: now,
    updatedAt: now,
  );
}

TodoItem _copyTodo(
  TodoItem todo,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[todo.id] = id;
  return TodoItem(
    id: id,
    petId: petId,
    title: todo.title,
    status: todo.status,
    dueAt: todo.dueAt,
    note: todo.note,
    completedAt: todo.completedAt,
    createdAt: now,
    updatedAt: now,
  );
}

ExpenseEntry _copyExpense(
  ExpenseEntry expense,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[expense.id] = id;
  return ExpenseEntry(
    id: id,
    petId: petId,
    category: expense.category,
    amountCents: expense.amountCents,
    spentAt: expense.spentAt,
    title: expense.title,
    merchant: expense.merchant,
    note: expense.note,
    createdAt: now,
    updatedAt: now,
  );
}

TimelineEvent _copyTimeline(
  TimelineEvent event,
  String petId,
  DateTime now,
  Map<String, String> resourceIdMap,
) {
  final id = _uuid.v4();
  resourceIdMap[event.id] = id;
  return TimelineEvent(
    id: id,
    petId: petId,
    type: event.type,
    happenedAt: event.happenedAt,
    title: event.title,
    sourceId: _mappedNullable(event.sourceId, resourceIdMap),
    note: event.note,
    filePath: event.filePath,
    mediaPath: event.mediaPath,
    createdAt: now,
    updatedAt: now,
  );
}

String? _mappedNullable(String? value, Map<String, String> resourceIdMap) {
  if (value == null) {
    return null;
  }
  return resourceIdMap[value] ?? value;
}

Future<void> _deleteManagedFile(String path) async {
  final parts = p.split(p.normalize(path));
  if (!parts.contains('petji')) {
    return;
  }
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

NotificationScheduler _scheduler(NotificationScheduler scheduler) => scheduler;

TimelineEvent _timelineEventForCare(CareRecord record, DateTime now) {
  return TimelineEvent(
    id: _uuid.v5(Namespace.url.value, 'timeline:${record.id}'),
    petId: record.petId,
    type: switch (record.category) {
      CareCategory.vaccine => TimelineEventType.vaccine,
      CareCategory.deworming => TimelineEventType.deworming,
      CareCategory.report || CareCategory.checkup => TimelineEventType.report,
      _ => TimelineEventType.record,
    },
    happenedAt: record.happenedAt,
    title: record.title,
    sourceId: record.id,
    note: record.note,
    filePath: record.reportPath,
    mediaPath: record.mediaPath,
    createdAt: now,
    updatedAt: now,
  );
}

String _careTitle(CareCategory category) => switch (category) {
  CareCategory.bath => '洗澡',
  CareCategory.vaccine => '疫苗',
  CareCategory.deworming => '驱虫',
  CareCategory.neuter => '绝育',
  CareCategory.checkup => '体检',
  CareCategory.feeding => '喂食',
  CareCategory.report => '体检报告',
};
