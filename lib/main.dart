import 'package:flutter/material.dart';

import 'application/flutter_notification_scheduler.dart';
import 'data/local/drift_snapshot_store.dart';
import 'data/local/petji_database.dart';
import 'presentation/petji_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = PetjiDatabase();
  final store = DriftSnapshotStore(database);
  final snapshot = await store.load();
  final scheduler = FlutterNotificationScheduler();
  await scheduler.initialize();
  runApp(
    PetjiApp(
      initialSnapshot: snapshot,
      persistSnapshot: store.save,
      notificationScheduler: scheduler,
      clock: DateTime.now,
    ),
  );
}
