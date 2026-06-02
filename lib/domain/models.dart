enum PetSpecies { cat, dog, other }

enum PetSex { male, female, unknown }

enum CareCategory { bath, vaccine, deworming, neuter, checkup, feeding, report }

enum ReminderStatus { scheduled, done, canceled }

enum MediaType { photo, video }

enum TodoStatus { open, done }

enum TimelineEventType {
  record,
  photo,
  video,
  vaccine,
  deworming,
  report,
  weight,
  note,
  care,
  feeding,
  media,
  expense,
}

enum ExpenseCategory {
  food,
  medical,
  grooming,
  toy,
  supplies,
  insurance,
  other,
}

String _enumName(Enum value) => value.name;

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  return fallback;
}

DateTime _date(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw FormatException('Expected ISO date string, got $value');
}

DateTime? _nullableDate(Object? value) => value == null ? null : _date(value);

class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthday,
    required this.sex,
    required this.isNeutered,
    required this.createdAt,
    required this.updatedAt,
    this.avatarPath,
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String name;
  final PetSpecies species;
  final String breed;
  final DateTime birthday;
  final PetSex sex;
  final bool isNeutered;
  final String? avatarPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  String ageLabel(DateTime asOf) {
    var years = asOf.year - birthday.year;
    var months = asOf.month - birthday.month;
    if (asOf.day < birthday.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years <= 0) {
      return '${months.clamp(0, 11)}个月';
    }
    return '$years岁$months个月';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'species': _enumName(species),
    'breed': breed,
    'birthday': birthday.toIso8601String(),
    'sex': _enumName(sex),
    'isNeutered': isNeutered,
    'avatarPath': avatarPath,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory PetProfile.fromJson(Map<String, Object?> json) => PetProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    species: _enumValue(PetSpecies.values, json['species'], PetSpecies.other),
    breed: json['breed'] as String? ?? '',
    birthday: _date(json['birthday']),
    sex: _enumValue(PetSex.values, json['sex'], PetSex.unknown),
    isNeutered: json['isNeutered'] as bool? ?? false,
    avatarPath: json['avatarPath'] as String?,
    notes: json['notes'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.petId,
    required this.grams,
    required this.measuredAt,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String petId;
  final int grams;
  final DateTime measuredAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'grams': grams,
    'measuredAt': measuredAt.toIso8601String(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory WeightRecord.fromJson(Map<String, Object?> json) => WeightRecord(
    id: json['id'] as String,
    petId: json['petId'] as String,
    grams: json['grams'] as int,
    measuredAt: _date(json['measuredAt']),
    note: json['note'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class FeedingRecord {
  const FeedingRecord({
    required this.id,
    required this.petId,
    required this.fedAt,
    required this.createdAt,
    required this.updatedAt,
    this.foodName,
    this.amountGrams,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String petId;
  final DateTime fedAt;
  final String? foodName;
  final int? amountGrams;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'fedAt': fedAt.toIso8601String(),
    'foodName': foodName,
    'amountGrams': amountGrams,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory FeedingRecord.fromJson(Map<String, Object?> json) => FeedingRecord(
    id: json['id'] as String,
    petId: json['petId'] as String,
    fedAt: _date(json['fedAt']),
    foodName: json['foodName'] as String?,
    amountGrams: json['amountGrams'] as int?,
    note: json['note'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class CareRecord {
  const CareRecord({
    required this.id,
    required this.petId,
    required this.category,
    required this.happenedAt,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.reportPath,
    this.mediaPath,
    this.deletedAt,
  });

  final String id;
  final String petId;
  final CareCategory category;
  final DateTime happenedAt;
  final String title;
  final String? note;
  final String? reportPath;
  final String? mediaPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'category': _enumName(category),
    'happenedAt': happenedAt.toIso8601String(),
    'title': title,
    'note': note,
    'reportPath': reportPath,
    'mediaPath': mediaPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory CareRecord.fromJson(Map<String, Object?> json) => CareRecord(
    id: json['id'] as String,
    petId: json['petId'] as String,
    category: _enumValue(
      CareCategory.values,
      json['category'],
      CareCategory.checkup,
    ),
    happenedAt: _date(json['happenedAt']),
    title: json['title'] as String,
    note: json['note'] as String?,
    reportPath:
        (json['reportPath'] as String?) ?? (json['filePath'] as String?),
    mediaPath: json['mediaPath'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class ReminderRule {
  const ReminderRule({
    required this.id,
    required this.category,
    required this.intervalDays,
    required this.titleTemplate,
    this.enabled = true,
  });

  final String id;
  final CareCategory category;
  final int intervalDays;
  final String titleTemplate;
  final bool enabled;

  Map<String, Object?> toJson() => {
    'id': id,
    'category': _enumName(category),
    'intervalDays': intervalDays,
    'titleTemplate': titleTemplate,
    'enabled': enabled,
  };

  factory ReminderRule.fromJson(Map<String, Object?> json) => ReminderRule(
    id: json['id'] as String,
    category: _enumValue(
      CareCategory.values,
      json['category'],
      CareCategory.checkup,
    ),
    intervalDays: json['intervalDays'] as int,
    titleTemplate: json['titleTemplate'] as String,
    enabled: json['enabled'] as bool? ?? true,
  );
}

class Reminder {
  const Reminder({
    required this.id,
    required this.petId,
    required this.title,
    required this.dueAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourceRecordId,
    this.deletedAt,
  });

  final String id;
  final String petId;
  final String title;
  final DateTime dueAt;
  final ReminderStatus status;
  final String? sourceRecordId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'title': title,
    'dueAt': dueAt.toIso8601String(),
    'status': _enumName(status),
    'sourceRecordId': sourceRecordId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, Object?> json) => Reminder(
    id: json['id'] as String,
    petId: json['petId'] as String,
    title: json['title'] as String,
    dueAt: _date(json['dueAt']),
    status: _enumValue(
      ReminderStatus.values,
      json['status'],
      ReminderStatus.scheduled,
    ),
    sourceRecordId: json['sourceRecordId'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.petId,
    required this.type,
    required this.localPath,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String petId;
  final MediaType type;
  final String localPath;
  final DateTime capturedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'type': _enumName(type),
    'localPath': localPath,
    'capturedAt': capturedAt.toIso8601String(),
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory MediaAsset.fromJson(Map<String, Object?> json) => MediaAsset(
    id: json['id'] as String,
    petId: json['petId'] as String,
    type: _enumValue(MediaType.values, json['type'], MediaType.photo),
    localPath: json['localPath'] as String,
    capturedAt: _date(json['capturedAt']),
    note: json['note'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.petId,
    required this.category,
    required this.amountCents,
    required this.spentAt,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.merchant,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String? petId;
  final ExpenseCategory category;
  final int amountCents;
  final DateTime spentAt;
  final String title;
  final String? merchant;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'category': _enumName(category),
    'amountCents': amountCents,
    'spentAt': spentAt.toIso8601String(),
    'title': title,
    'merchant': merchant,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory ExpenseEntry.fromJson(Map<String, Object?> json) => ExpenseEntry(
    id: json['id'] as String,
    petId: json['petId'] as String?,
    category: _enumValue(
      ExpenseCategory.values,
      json['category'],
      ExpenseCategory.other,
    ),
    amountCents: json['amountCents'] as int,
    spentAt: _date(json['spentAt']),
    title: json['title'] as String,
    merchant: json['merchant'] as String?,
    note: json['note'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.petId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.note,
    this.completedAt,
    this.deletedAt,
  });

  final String id;
  final String? petId;
  final String title;
  final TodoStatus status;
  final DateTime? dueAt;
  final String? note;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  TodoItem copyWith({
    String? title,
    TodoStatus? status,
    DateTime? dueAt,
    String? note,
    Object? completedAt = _copyWithSentinel,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TodoItem(
      id: id,
      petId: petId,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      note: note ?? this.note,
      completedAt: completedAt == _copyWithSentinel
          ? this.completedAt
          : completedAt as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'title': title,
    'status': _enumName(status),
    'dueAt': dueAt?.toIso8601String(),
    'note': note,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory TodoItem.fromJson(Map<String, Object?> json) => TodoItem(
    id: json['id'] as String,
    petId: json['petId'] as String?,
    title: json['title'] as String,
    status: _enumValue(TodoStatus.values, json['status'], TodoStatus.open),
    dueAt: _nullableDate(json['dueAt']),
    note: json['note'] as String?,
    completedAt: _nullableDate(json['completedAt']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.petId,
    required this.type,
    required this.happenedAt,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.sourceId,
    this.note,
    this.filePath,
    this.mediaPath,
    this.deletedAt,
  });

  final String id;
  final String? petId;
  final TimelineEventType type;
  final DateTime happenedAt;
  final String title;
  final String? sourceId;
  final String? note;
  final String? filePath;
  final String? mediaPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'type': _enumName(type),
    'happenedAt': happenedAt.toIso8601String(),
    'title': title,
    'sourceId': sourceId,
    'note': note,
    'filePath': filePath,
    'mediaPath': mediaPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory TimelineEvent.fromJson(Map<String, Object?> json) => TimelineEvent(
    id: json['id'] as String,
    petId: json['petId'] as String?,
    type: _enumValue(
      TimelineEventType.values,
      json['type'],
      TimelineEventType.note,
    ),
    happenedAt: _date(json['happenedAt']),
    title: json['title'] as String,
    sourceId: json['sourceId'] as String?,
    note: json['note'] as String?,
    filePath: json['filePath'] as String?,
    mediaPath: json['mediaPath'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    deletedAt: _nullableDate(json['deletedAt']),
  );
}

class AppSnapshot {
  const AppSnapshot({
    required this.version,
    required this.exportedAt,
    required this.activePetId,
    required this.pets,
    required this.weightRecords,
    required this.feedingRecords,
    required this.records,
    required this.reminderRules,
    required this.reminders,
    required this.mediaAssets,
    required this.expenses,
    required this.todos,
    required this.timelineEvents,
  });

  final int version;
  final DateTime exportedAt;
  final String? activePetId;
  final List<PetProfile> pets;
  final List<WeightRecord> weightRecords;
  final List<FeedingRecord> feedingRecords;
  final List<CareRecord> records;
  final List<ReminderRule> reminderRules;
  final List<Reminder> reminders;
  final List<MediaAsset> mediaAssets;
  final List<ExpenseEntry> expenses;
  final List<TodoItem> todos;
  final List<TimelineEvent> timelineEvents;

  PetProfile? get currentPet {
    if (activePetId == null) {
      return null;
    }
    for (final pet in pets) {
      if (pet.id == activePetId && pet.deletedAt == null) {
        return pet;
      }
    }
    return null;
  }

  factory AppSnapshot.empty({required DateTime now}) => AppSnapshot(
    version: 2,
    exportedAt: now,
    activePetId: null,
    pets: const [],
    weightRecords: const [],
    feedingRecords: const [],
    records: const [],
    reminderRules: defaultReminderRules,
    reminders: const [],
    mediaAssets: const [],
    expenses: const [],
    todos: const [],
    timelineEvents: const [],
  );

  factory AppSnapshot.seed({required DateTime now}) {
    final pet = PetProfile(
      id: 'pet-seed-momo',
      name: 'Momo',
      species: PetSpecies.cat,
      breed: 'British Shorthair',
      birthday: DateTime(2024, 1, 15),
      sex: PetSex.female,
      isNeutered: true,
      notes: '温和，喜欢窗边晒太阳',
      createdAt: now,
      updatedAt: now,
    );
    return AppSnapshot(
      version: 2,
      exportedAt: now,
      activePetId: pet.id,
      pets: [pet],
      weightRecords: [
        WeightRecord(
          id: 'weight-seed-1',
          petId: pet.id,
          grams: 4200,
          measuredAt: now.subtract(const Duration(days: 7)),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      feedingRecords: [
        FeedingRecord(
          id: 'feeding-seed-1',
          petId: pet.id,
          fedAt: DateTime(now.year, now.month, now.day, 8, 30),
          foodName: '主粮',
          amountGrams: 45,
          createdAt: now,
          updatedAt: now,
        ),
        FeedingRecord(
          id: 'feeding-seed-2',
          petId: pet.id,
          fedAt: DateTime(now.year, now.month, now.day, 19),
          foodName: '主粮',
          amountGrams: 40,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      records: [
        CareRecord(
          id: 'care-seed-bath',
          petId: pet.id,
          category: CareCategory.bath,
          happenedAt: now.subtract(const Duration(days: 20)),
          title: '洗澡',
          createdAt: now,
          updatedAt: now,
        ),
        CareRecord(
          id: 'care-seed-vaccine',
          petId: pet.id,
          category: CareCategory.vaccine,
          happenedAt: now.subtract(const Duration(days: 120)),
          title: '年度疫苗',
          note: '下一针按兽医建议提前预约',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      reminderRules: defaultReminderRules,
      reminders: [
        Reminder(
          id: 'reminder-seed-bath',
          petId: pet.id,
          title: '该给Momo洗澡了',
          dueAt: now.add(const Duration(days: 10)),
          status: ReminderStatus.scheduled,
          sourceRecordId: 'care-seed-bath',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      mediaAssets: [
        MediaAsset(
          id: 'media-seed-1',
          petId: pet.id,
          type: MediaType.photo,
          localPath: 'assets/images/generated/empty_timeline.png',
          capturedAt: now.subtract(const Duration(days: 40)),
          note: '第一次到家',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      expenses: [
        ExpenseEntry(
          id: 'expense-seed-food',
          petId: pet.id,
          category: ExpenseCategory.food,
          amountCents: 12990,
          spentAt: DateTime(now.year, now.month, 1),
          title: '猫粮',
          createdAt: now,
          updatedAt: now,
        ),
        ExpenseEntry(
          id: 'expense-seed-medical',
          petId: pet.id,
          category: ExpenseCategory.medical,
          amountCents: 8600,
          spentAt: DateTime(now.year, now.month, 15),
          title: '体检',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      todos: const [],
      timelineEvents: [
        TimelineEvent(
          id: 'timeline-seed-home',
          petId: pet.id,
          type: TimelineEventType.photo,
          happenedAt: now.subtract(const Duration(days: 40)),
          title: '第一次到家',
          sourceId: 'media-seed-1',
          mediaPath: 'assets/images/generated/empty_timeline.png',
          createdAt: now,
          updatedAt: now,
        ),
        TimelineEvent(
          id: 'timeline-seed-vaccine',
          petId: pet.id,
          type: TimelineEventType.vaccine,
          happenedAt: now.subtract(const Duration(days: 120)),
          title: '年度疫苗',
          note: '下一针按兽医建议提前预约',
          sourceId: 'care-seed-vaccine',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  AppSnapshot copyWith({
    int? version,
    DateTime? exportedAt,
    Object? activePetId = _copyWithSentinel,
    List<PetProfile>? pets,
    List<WeightRecord>? weightRecords,
    List<FeedingRecord>? feedingRecords,
    List<CareRecord>? records,
    List<ReminderRule>? reminderRules,
    List<Reminder>? reminders,
    List<MediaAsset>? mediaAssets,
    List<ExpenseEntry>? expenses,
    List<TodoItem>? todos,
    List<TimelineEvent>? timelineEvents,
  }) {
    return AppSnapshot(
      version: version ?? this.version,
      exportedAt: exportedAt ?? this.exportedAt,
      activePetId: activePetId == _copyWithSentinel
          ? this.activePetId
          : activePetId as String?,
      pets: pets ?? this.pets,
      weightRecords: weightRecords ?? this.weightRecords,
      feedingRecords: feedingRecords ?? this.feedingRecords,
      records: records ?? this.records,
      reminderRules: reminderRules ?? this.reminderRules,
      reminders: reminders ?? this.reminders,
      mediaAssets: mediaAssets ?? this.mediaAssets,
      expenses: expenses ?? this.expenses,
      todos: todos ?? this.todos,
      timelineEvents: timelineEvents ?? this.timelineEvents,
    );
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'activePetId': activePetId,
    'pets': pets.map((item) => item.toJson()).toList(),
    'weightRecords': weightRecords.map((item) => item.toJson()).toList(),
    'feedingRecords': feedingRecords.map((item) => item.toJson()).toList(),
    'records': records.map((item) => item.toJson()).toList(),
    'reminderRules': reminderRules.map((item) => item.toJson()).toList(),
    'reminders': reminders.map((item) => item.toJson()).toList(),
    'mediaAssets': mediaAssets.map((item) => item.toJson()).toList(),
    'expenses': expenses.map((item) => item.toJson()).toList(),
    'todos': todos.map((item) => item.toJson()).toList(),
    'timelineEvents': timelineEvents.map((item) => item.toJson()).toList(),
  };

  factory AppSnapshot.fromJson(Map<String, Object?> json) => AppSnapshot(
    version: json['version'] as int? ?? 1,
    exportedAt: _date(json['exportedAt']),
    activePetId: json['activePetId'] as String?,
    pets: _list(json['pets'], PetProfile.fromJson),
    weightRecords: _list(json['weightRecords'], WeightRecord.fromJson),
    feedingRecords: _list(json['feedingRecords'], FeedingRecord.fromJson),
    records: _list(json['records'], CareRecord.fromJson),
    reminderRules: _list(json['reminderRules'], ReminderRule.fromJson),
    reminders: _list(json['reminders'], Reminder.fromJson),
    mediaAssets: _list(json['mediaAssets'], MediaAsset.fromJson),
    expenses: _list(json['expenses'], ExpenseEntry.fromJson),
    todos: _list(json['todos'], TodoItem.fromJson),
    timelineEvents: _list(json['timelineEvents'], TimelineEvent.fromJson),
  );
}

const _copyWithSentinel = Object();

List<T> _list<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
) {
  if (value is! List) {
    return const [];
  }
  return value
      .cast<Map>()
      .map((item) => item.cast<String, Object?>())
      .map(fromJson)
      .toList(growable: false);
}

const defaultReminderRules = [
  ReminderRule(
    id: 'rule-bath-30',
    category: CareCategory.bath,
    intervalDays: 30,
    titleTemplate: '该给{name}洗澡了',
  ),
  ReminderRule(
    id: 'rule-deworming-90',
    category: CareCategory.deworming,
    intervalDays: 90,
    titleTemplate: '该给{name}做驱虫了',
  ),
  ReminderRule(
    id: 'rule-vaccine-365',
    category: CareCategory.vaccine,
    intervalDays: 365,
    titleTemplate: '{name}的疫苗提醒',
  ),
  ReminderRule(
    id: 'rule-checkup-180',
    category: CareCategory.checkup,
    intervalDays: 180,
    titleTemplate: '建议安排{name}体检',
  ),
];
