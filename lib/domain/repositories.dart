import 'models.dart';

abstract interface class PetRepository {
  Future<List<PetProfile>> watchPets();
  Future<void> savePet(PetProfile pet);
}

abstract interface class RecordRepository {
  Future<List<WeightRecord>> listWeights(String petId);
  Future<List<FeedingRecord>> listFeedings(String petId, DateTime day);
  Future<List<CareRecord>> listCareRecords(String petId);
  Future<void> saveWeight(WeightRecord record);
  Future<void> saveFeeding(FeedingRecord record);
  Future<void> saveCareRecord(CareRecord record);
}

abstract interface class ReminderRepository {
  Future<List<ReminderRule>> listRules();
  Future<List<Reminder>> listScheduled(String petId);
  Future<void> saveRule(ReminderRule rule);
  Future<void> saveReminder(Reminder reminder);
}

abstract interface class MediaRepository {
  Future<List<MediaAsset>> listTimeline(String petId);
  Future<void> saveMedia(MediaAsset asset);
}

abstract interface class TimelineRepository {
  Future<List<TimelineEvent>> listTimelineEvents(String petId);
  Future<void> saveTimelineEvent(TimelineEvent event);
}

abstract interface class TodoRepository {
  Future<List<TodoItem>> listTodos({String? petId, TodoStatus? status});
  Future<void> saveTodo(TodoItem todo);
}

abstract interface class ExpenseRepository {
  Future<List<ExpenseEntry>> listExpenses({int? year, int? month});
  Future<void> saveExpense(ExpenseEntry expense);
}

abstract interface class BackupRepository {
  Future<AppSnapshot> exportSnapshot();
  Future<void> importSnapshot(AppSnapshot snapshot);
}
