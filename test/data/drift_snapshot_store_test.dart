import 'package:flutter_test/flutter_test.dart';
import 'package:petji/data/local/drift_snapshot_store.dart';
import 'package:petji/data/local/petji_database.dart';
import 'package:petji/domain/models.dart';

void main() {
  test('loads an empty v2 snapshot when no local snapshot exists', () async {
    final database = PetjiDatabase.inMemory();
    addTearDown(database.close);
    final store = DriftSnapshotStore(database);

    final restored = await store.load();

    expect(restored.version, 2);
    expect(restored.pets, isEmpty);
    expect(restored.activePetId, isNull);
  });

  test('persists and restores the current app snapshot with drift', () async {
    final database = PetjiDatabase.inMemory();
    addTearDown(database.close);
    final store = DriftSnapshotStore(database);
    final snapshot = AppSnapshot.seed(now: DateTime(2026, 6, 1));

    await store.save(snapshot);
    final restored = await store.load();

    expect(restored.pets.single.name, 'Momo');
    expect(restored.reminderRules.length, snapshot.reminderRules.length);
    expect(restored.expenses.map((entry) => entry.amountCents), [12990, 8600]);
  });
}
