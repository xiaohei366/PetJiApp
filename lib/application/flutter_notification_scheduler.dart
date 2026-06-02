import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';
import 'notification_ids.dart';
import 'notification_scheduler.dart';

class FlutterNotificationScheduler implements NotificationScheduler {
  FlutterNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _ready = false;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initialization = InitializationSettings(android: android);
    await _plugin.initialize(initialization);
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    _ready = true;
  }

  @override
  void scheduleReminder(Reminder reminder) {
    if (!_ready) {
      return;
    }
    unawaited(
      _schedule(
        id: stableNotificationId(
          namespace: 'reminder',
          resourceId: reminder.id,
        ),
        title: reminder.title,
        body: '宠物记提醒',
        scheduledAt: reminder.dueAt,
        payload: 'reminder:${reminder.id}',
      ),
    );
  }

  @override
  void cancelReminder(String reminderId) {
    if (!_ready) {
      return;
    }
    unawaited(
      _plugin.cancel(
        stableNotificationId(namespace: 'reminder', resourceId: reminderId),
      ),
    );
  }

  @override
  void scheduleTodo(TodoItem todo) {
    final dueAt = todo.dueAt;
    if (!_ready || dueAt == null || todo.status != TodoStatus.open) {
      return;
    }
    final scheduledAt = DateTime(dueAt.year, dueAt.month, dueAt.day, 9);
    unawaited(
      _schedule(
        id: stableNotificationId(namespace: 'todo', resourceId: todo.id),
        title: todo.title,
        body: todo.note?.isEmpty == false ? todo.note : '今日待办',
        scheduledAt: scheduledAt,
        payload: 'todo:${todo.id}',
      ),
    );
  }

  @override
  void cancelTodo(String todoId) {
    if (!_ready) {
      return;
    }
    unawaited(
      _plugin.cancel(
        stableNotificationId(namespace: 'todo', resourceId: todoId),
      ),
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String? body,
    required DateTime scheduledAt,
    required String payload,
  }) {
    final target = tz.TZDateTime.from(scheduledAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      target.isAfter(now) ? target : now.add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'petji_todos',
          '宠物记提醒',
          channelDescription: '宠物记待办与护理提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
