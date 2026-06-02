import 'package:flutter_test/flutter_test.dart';
import 'package:petji/application/notification_ids.dart';

void main() {
  test('stableNotificationId is deterministic and namespace separated', () {
    final reminderId = stableNotificationId(
      namespace: 'reminder',
      resourceId: 'same-id',
    );
    final sameReminderId = stableNotificationId(
      namespace: 'reminder',
      resourceId: 'same-id',
    );
    final todoId = stableNotificationId(
      namespace: 'todo',
      resourceId: 'same-id',
    );

    expect(reminderId, sameReminderId);
    expect(reminderId, isNot(todoId));
    expect(reminderId, greaterThan(0));
    expect(reminderId, lessThanOrEqualTo(0x7fffffff));
  });
}
