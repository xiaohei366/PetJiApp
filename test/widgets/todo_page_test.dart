import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';
import 'package:petji/presentation/petji_app.dart';

void main() {
  testWidgets('todo page adds a due task and toggles completion', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('待办'));
    await tester.pumpAndSettle();

    expect(find.text('待办'), findsWidgets);
    expect(find.bySemanticsLabel('待办日历导航'), findsOneWidget);
    expect(find.text('年'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('日'), findsWidgets);

    await tester.tap(find.text('新增待办'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('待办标题输入框'), '预约疫苗');
    await tester.tap(find.text('保存待办'));
    await tester.pumpAndSettle();

    expect(find.text('预约疫苗'), findsOneWidget);
    expect(find.text('距离今日还有 0 天'), findsOneWidget);
    expect(find.text('已创建待办，并准备本地通知提醒'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('完成待办 预约疫苗'));
    await tester.pumpAndSettle();

    expect(find.text('已完成'), findsOneWidget);
  });

  testWidgets('todo page switches year month and day views', (tester) async {
    await tester.pumpWidget(PetjiApp(initialSnapshot: _snapshotWithTodo()));

    await tester.tap(find.text('待办'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('年').first);
    await tester.pumpAndSettle();
    expect(find.text('2026 年待办图谱'), findsOneWidget);
    expect(find.bySemanticsLabel('待办年度月历'), findsOneWidget);

    await tester.tap(find.text('月').first);
    await tester.pumpAndSettle();
    expect(find.text('2026-06 待办日历'), findsOneWidget);
    expect(find.bySemanticsLabel('待办月历格子'), findsOneWidget);
    for (final weekday in ['日', '一', '二', '三', '四', '五', '六']) {
      expect(find.text(weekday), findsWidgets);
    }
    expect(find.text('1号'), findsOneWidget);
    expect(find.text('1日'), findsNothing);

    await tester.tap(find.text('日').first);
    await tester.pumpAndSettle();
    expect(find.text('2026-06-01 待办'), findsOneWidget);
  });
}

AppSnapshot _snapshotWithTodo() {
  final now = DateTime(2026, 6, 1);
  final snapshot = AppSnapshot.seed(now: now);
  return snapshot.copyWith(
    todos: [
      TodoItem(
        id: 'todo-june-1',
        petId: snapshot.activePetId,
        title: '预约疫苗',
        status: TodoStatus.open,
        dueAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}
