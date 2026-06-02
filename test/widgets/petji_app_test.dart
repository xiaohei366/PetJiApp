import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';
import 'package:petji/presentation/petji_app.dart';

void main() {
  testWidgets('empty app starts with pet onboarding instead of seed data', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.empty(now: DateTime(2026, 6, 1))),
    );

    expect(find.text('先登记你的宠物'), findsOneWidget);
    expect(find.text('Momo'), findsNothing);
    expect(find.text('首页'), findsNothing);

    await tester.enterText(find.bySemanticsLabel('宠物名称输入框'), '豆包');
    await tester.tap(find.text('保存宠物档案'));
    await tester.pumpAndSettle();

    expect(find.text('健康概览'), findsOneWidget);
    expect(find.text('豆包'), findsWidgets);
  });

  testWidgets('dashboard has four required metrics and no reminder card', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    expect(find.text('年龄'), findsOneWidget);
    expect(find.text('体重'), findsWidgets);
    expect(find.text('疫苗'), findsOneWidget);
    expect(find.text('本月消费'), findsOneWidget);
    expect(find.text('近期提醒'), findsNothing);
    expect(find.text('今日喂食'), findsNothing);
  });

  testWidgets('quick feeding and weight forms update the dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    final feedingButton = find.widgetWithText(OutlinedButton, '喂食');
    await tester.ensureVisible(feedingButton);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(feedingButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('喂食克数输入框'), '55');
    await tester.tap(find.text('保存喂食'));
    await tester.pumpAndSettle();

    expect(find.text('已记录55g喂食'), findsOneWidget);

    final weightButton = find.widgetWithText(OutlinedButton, '体重');
    await tester.ensureVisible(weightButton);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(weightButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('体重公斤输入框'), '4.6');
    await tester.tap(find.text('保存体重'));
    await tester.pumpAndSettle();

    expect(find.text('4.6kg'), findsOneWidget);
  });

  testWidgets('expense form changes the monthly total', (tester) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
    );

    await tester.tap(find.text('消费'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增消费'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('消费标题输入框'), '猫砂');
    await tester.enterText(find.bySemanticsLabel('消费金额输入框'), '10');
    await tester.tap(find.text('保存消费'));
    await tester.pumpAndSettle();

    expect(find.text('¥225.90'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1号'));
    await tester.pumpAndSettle();

    expect(find.textContaining('猫砂'), findsOneWidget);
    expect(find.text('¥10.00'), findsOneWidget);
  });

  testWidgets('dashboard avatar opens pet switcher and switches pets', (
    tester,
  ) async {
    final snapshot = _twoPetSnapshot();
    await tester.pumpWidget(PetjiApp(initialSnapshot: snapshot));

    await tester.tap(find.byTooltip('切换宠物 Momo'));
    await tester.pumpAndSettle();

    expect(find.text('切换宠物'), findsOneWidget);
    expect(find.text('新增宠物'), findsOneWidget);
    expect(find.text('删除档案'), findsOneWidget);

    await tester.tap(find.text('Bao'));
    await tester.pumpAndSettle();

    expect(find.text('Bao'), findsWidgets);
    expect(find.byTooltip('切换宠物 Bao'), findsOneWidget);
  });

  testWidgets('dashboard recent activity preview is capped and has view all', (
    tester,
  ) async {
    await tester.pumpWidget(
      PetjiApp(initialSnapshot: _timelineHeavySnapshot()),
    );

    await tester.scrollUntilVisible(find.text('最近动态'), 400);

    expect(find.text('最近动态'), findsOneWidget);
    expect(find.text('查看全部'), findsOneWidget);
    expect(find.text('成长事件 1'), findsOneWidget);
    expect(find.text('成长事件 5'), findsOneWidget);
    expect(find.text('成长事件 6'), findsNothing);
  });
}

AppSnapshot _twoPetSnapshot() {
  final now = DateTime(2026, 6, 1);
  final seed = AppSnapshot.seed(now: now);
  final second = PetProfile(
    id: 'pet-bao',
    name: 'Bao',
    species: PetSpecies.dog,
    breed: '',
    birthday: DateTime(2023, 2, 20),
    sex: PetSex.unknown,
    isNeutered: false,
    createdAt: now,
    updatedAt: now,
  );
  return seed.copyWith(pets: [...seed.pets, second]);
}

AppSnapshot _timelineHeavySnapshot() {
  final now = DateTime(2026, 6, 1);
  final seed = AppSnapshot.seed(now: now);
  final petId = seed.activePetId!;
  return seed.copyWith(
    timelineEvents: [
      for (var index = 1; index <= 6; index += 1)
        TimelineEvent(
          id: 'event-$index',
          petId: petId,
          type: TimelineEventType.record,
          happenedAt: now.subtract(Duration(days: index)),
          title: '成长事件 $index',
          createdAt: now,
          updatedAt: now,
        ),
    ],
  );
}
