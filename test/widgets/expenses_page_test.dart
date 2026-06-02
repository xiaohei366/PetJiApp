import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';
import 'package:petji/presentation/petji_app.dart';

void main() {
  testWidgets('expense form captures category and date selector state', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('消费'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增消费'));
    await tester.pumpAndSettle();

    expect(find.text('类别'), findsOneWidget);
    expect(find.text('日期 2026-06-01'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('消费标题输入框'), '复查');
    await tester.enterText(find.bySemanticsLabel('消费金额输入框'), '20');
    await tester.tap(find.text('保存消费'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1号'));
    await tester.pumpAndSettle();
    expect(find.textContaining('复查'), findsOneWidget);
    expect(find.textContaining('用品'), findsWidgets);
    expect(find.text('¥20.00'), findsOneWidget);
  });

  testWidgets('expense day item can be deleted', (tester) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('消费'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除消费 猫粮'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(find.text('消费已删除'), findsOneWidget);
    expect(find.text('猫粮'), findsNothing);
  });

  testWidgets(
    'expense page shows colored legend and period grouping controls',
    (tester) async {
      await tester.pumpWidget(
        PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
      );

      await tester.tap(find.text('消费'));
      await tester.pumpAndSettle();

      expect(find.text('分类图例'), findsOneWidget);
      expect(find.textContaining('主粮零食'), findsWidgets);
      expect(find.textContaining('医疗体检'), findsWidgets);

      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();
      expect(find.text('2026 年消费报告'), findsOneWidget);

      await tester.tap(find.text('日'));
      await tester.pumpAndSettle();
      expect(find.text('2026-06-01 消费报告'), findsOneWidget);
      expect(find.text('猫粮'), findsOneWidget);
    },
  );

  testWidgets('expense report drills from year to month to day', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('消费'));
    await tester.pumpAndSettle();

    expect(find.text('消费报告'), findsOneWidget);
    await tester.tap(find.text('年'));
    await tester.pumpAndSettle();
    expect(find.text('2026 年消费报告'), findsOneWidget);
    expect(find.bySemanticsLabel('消费报告年度月历'), findsOneWidget);
    expect(find.text('6月'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6月'));
    await tester.pumpAndSettle();
    expect(find.text('2026-06 消费报告'), findsOneWidget);
    expect(find.bySemanticsLabel('消费报告月历格子'), findsOneWidget);
    for (final weekday in ['日', '一', '二', '三', '四', '五', '六']) {
      expect(find.text(weekday), findsWidgets);
    }
    expect(find.text('1号'), findsOneWidget);
    expect(find.text('1日'), findsNothing);

    await tester.ensureVisible(find.text('1号'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1号'));
    await tester.pumpAndSettle();
    expect(find.text('2026-06-01 消费报告'), findsOneWidget);
    expect(find.text('猫粮'), findsOneWidget);
  });

  testWidgets('expense report shows calendar navigator', (tester) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('消费'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('消费报告日历导航'), findsOneWidget);
    expect(find.text('日历'), findsOneWidget);
  });
}
