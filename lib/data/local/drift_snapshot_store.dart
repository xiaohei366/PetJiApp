import '../../application/backup_codec.dart';
import '../../domain/models.dart';
import 'petji_database.dart';

class DriftSnapshotStore {
  DriftSnapshotStore(this._database);

  static const currentSnapshotKey = 'petji:v1:current-snapshot';

  final PetjiDatabase _database;

  Future<AppSnapshot> load() async {
    final payload = await _database.readSnapshot(currentSnapshotKey);
    if (payload == null) {
      return AppSnapshot.empty(now: DateTime.now());
    }
    return BackupCodec.decode(payload);
  }

  Future<void> save(AppSnapshot snapshot) {
    return _database.upsertSnapshot(
      key: currentSnapshotKey,
      payload: BackupCodec.encode(snapshot),
      updatedAt: DateTime.now(),
    );
  }
}
