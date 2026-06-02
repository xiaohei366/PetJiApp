import '../domain/models.dart';

abstract interface class NotificationScheduler {
  void scheduleReminder(Reminder reminder);
  void cancelReminder(String reminderId);
  void scheduleTodo(TodoItem todo);
  void cancelTodo(String todoId);
}

class NoopNotificationScheduler implements NotificationScheduler {
  const NoopNotificationScheduler();

  @override
  void scheduleReminder(Reminder reminder) {}

  @override
  void cancelReminder(String reminderId) {}

  @override
  void scheduleTodo(TodoItem todo) {}

  @override
  void cancelTodo(String todoId) {}
}

class FakeNotificationScheduler implements NotificationScheduler {
  final scheduledReminders = <Reminder>[];
  final canceledReminderIds = <String>[];
  final scheduledTodos = <TodoItem>[];
  final canceledTodoIds = <String>[];

  @override
  void scheduleReminder(Reminder reminder) {
    scheduledReminders.add(reminder);
  }

  @override
  void cancelReminder(String reminderId) {
    canceledReminderIds.add(reminderId);
  }

  @override
  void scheduleTodo(TodoItem todo) {
    scheduledTodos.add(todo);
  }

  @override
  void cancelTodo(String todoId) {
    canceledTodoIds.add(todoId);
  }
}
