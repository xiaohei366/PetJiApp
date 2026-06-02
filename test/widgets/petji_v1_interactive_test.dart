import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';
import 'package:petji/presentation/petji_app.dart';

void main() {
  testWidgets(
    'dashboard care and report quick actions create timeline events',
    (tester) async {
      await tester.pumpWidget(
        PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
      );

      final careButton = find.widgetWithText(OutlinedButton, '疫苗/驱虫');
      await tester.ensureVisible(careButton);
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(careButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存护理'));
      await tester.pumpAndSettle();

      expect(find.text('护理记录已保存'), findsOneWidget);
      expect(find.text('疫苗'), findsWidgets);

      final reportButton = find.widgetWithText(OutlinedButton, '体检报告');
      await tester.ensureVisible(reportButton);
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(reportButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存报告'));
      await tester.pumpAndSettle();

      expect(find.text('已保存体检报告记录'), findsOneWidget);

      await tester.tap(find.text('成长线'));
      await tester.pumpAndSettle();

      expect(find.textContaining('体检报告'), findsWidgets);
    },
  );

  testWidgets(
    'timeline preview opens the timeline and focuses the tapped event',
    (tester) async {
      await tester.pumpWidget(
        PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
      );

      await tester.scrollUntilVisible(find.text('第一次到家'), 400);
      await tester.tap(find.text('第一次到家').first);
      await tester.pumpAndSettle();

      expect(find.text('成长线'), findsWidgets);
      expect(find.bySemanticsLabel('已聚焦成长记录 第一次到家'), findsOneWidget);
    },
  );

  testWidgets('timeline adds titled records and changes year month day views', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('成长线'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('成长线日历导航'), findsOneWidget);

    await tester.tap(find.text('日').first);
    await tester.pumpAndSettle();
    expect(find.text('2026-04-22'), findsOneWidget);

    await tester.tap(find.text('月').first);
    await tester.pumpAndSettle();
    expect(find.text('2026-04'), findsOneWidget);
    expect(find.bySemanticsLabel('成长线月历格子'), findsOneWidget);
    for (final weekday in ['日', '一', '二', '三', '四', '五', '六']) {
      expect(find.text(weekday), findsWidgets);
    }
    expect(find.text('22号'), findsOneWidget);
    expect(find.text('22日'), findsNothing);
    expect(find.text('1条事件'), findsOneWidget);
    expect(find.text('媒体1条，事件1条'), findsNothing);

    await tester.tap(find.text('年').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('成长线年度月历'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);

    await tester.tap(find.text('添加成长记录'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('成长记录标题输入框'), '第一次坐车');
    await tester.enterText(find.bySemanticsLabel('成长记录描述输入框'), '去医院复查');
    await tester.tap(find.text('保存成长记录'));
    await tester.pumpAndSettle();

    expect(find.text('第一次坐车'), findsOneWidget);
    expect(find.text('去医院复查'), findsOneWidget);
    expect(find.textContaining('assets/images/generated'), findsNothing);
  });

  testWidgets('timeline day events open details and add form infers type', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('成长线'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('第一次到家'));
    await tester.pumpAndSettle();

    expect(find.text('成长记录详情'), findsOneWidget);
    expect(find.text('第一次到家'), findsWidgets);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加成长记录'));
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<TimelineEventType>), findsNothing);
    expect(find.text('选择照片或视频'), findsOneWidget);
  });

  testWidgets('timeline day event can be deleted', (tester) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('成长线'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除成长记录 第一次到家'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(find.text('成长记录已删除'), findsOneWidget);
    expect(find.text('第一次到家'), findsNothing);
  });
}
