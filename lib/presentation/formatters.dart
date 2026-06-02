import '../domain/models.dart';

String moneyLabel(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

String careCategoryLabel(CareCategory category) => switch (category) {
  CareCategory.bath => '洗澡',
  CareCategory.vaccine => '疫苗',
  CareCategory.deworming => '驱虫',
  CareCategory.neuter => '绝育',
  CareCategory.checkup => '体检',
  CareCategory.feeding => '喂食',
  CareCategory.report => '体检报告',
};

String expenseCategoryLabel(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => '主粮零食',
  ExpenseCategory.medical => '医疗体检',
  ExpenseCategory.grooming => '洗护美容',
  ExpenseCategory.toy => '玩具',
  ExpenseCategory.supplies => '用品',
  ExpenseCategory.insurance => '保险',
  ExpenseCategory.other => '其他',
};

String mediaTypeLabel(MediaType type) => switch (type) {
  MediaType.photo => '照片',
  MediaType.video => '视频',
};

String timelineEventTypeLabel(TimelineEventType type) => switch (type) {
  TimelineEventType.photo => '照片',
  TimelineEventType.video => '视频',
  TimelineEventType.vaccine => '疫苗',
  TimelineEventType.deworming => '驱虫',
  TimelineEventType.report => '记录',
  TimelineEventType.weight => '记录',
  TimelineEventType.record => '记录',
  TimelineEventType.note => '记录',
  TimelineEventType.care => '记录',
  TimelineEventType.feeding => '记录',
  TimelineEventType.media => '照片',
  TimelineEventType.expense => '记录',
};

String dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String dueOffsetLabel(DateTime dueAt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final days = due.difference(today).inDays;
  if (days < 0) {
    return '已过期 ${days.abs()} 天';
  }
  if (days == 0) {
    return '距离今日还有 0 天';
  }
  return '距离今日还有 $days 天';
}
