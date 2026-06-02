import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'petji_database.g.dart';

class SnapshotRows extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [SnapshotRows])
class PetjiDatabase extends _$PetjiDatabase {
  PetjiDatabase() : super(_openConnection());

  PetjiDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  Future<String?> readSnapshot(String key) async {
    final row = await (select(
      snapshotRows,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.payload;
  }

  Future<void> upsertSnapshot({
    required String key,
    required String payload,
    required DateTime updatedAt,
  }) {
    return into(snapshotRows).insertOnConflictUpdate(
      SnapshotRowsCompanion.insert(
        key: key,
        payload: payload,
        updatedAt: updatedAt,
      ),
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'petji',
    native: const DriftNativeOptions(databaseDirectory: _databaseDirectory),
  );
}

Future<String> _databaseDirectory() async {
  final directory = await getApplicationDocumentsDirectory();
  return p.join(directory.path, 'databases');
}
