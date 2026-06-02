import 'package:flutter_test/flutter_test.dart';
import 'package:petji/domain/models.dart';
import 'package:petji/presentation/petji_app.dart';

void main() {
  testWidgets(
    'settings exposes petji bundle import and export without cloud cards',
    (tester) async {
      await tester.pumpWidget(
        PetjiApp(initialSnapshot: AppSnapshot.seed(now: DateTime(2026, 6, 1))),
      );

      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      expect(find.text('云化预留'), findsNothing);
      expect(find.text('AI 资产'), findsNothing);
      expect(find.text('.petji 备份包'), findsOneWidget);
      expect(find.text('导出.petji包'), findsOneWidget);
      expect(find.text('导入.petji包'), findsOneWidget);
    },
  );
}
