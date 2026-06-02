import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/app_providers.dart';
import '../application/notification_scheduler.dart';
import '../domain/models.dart';
import 'screens/onboarding_page.dart';
import 'screens/petji_shell.dart';
import 'theme/petji_theme.dart';

class PetjiApp extends StatelessWidget {
  const PetjiApp({
    super.key,
    required this.initialSnapshot,
    this.persistSnapshot,
    this.notificationScheduler = const NoopNotificationScheduler(),
    this.clock,
  });

  final AppSnapshot initialSnapshot;
  final SnapshotPersist? persistSnapshot;
  final NotificationScheduler notificationScheduler;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appSnapshotProvider.overrideWith(
          (ref) => PetjiController(
            initialSnapshot,
            persistSnapshot: persistSnapshot,
            notificationScheduler: notificationScheduler,
            clock: clock ?? () => initialSnapshot.exportedAt,
          ),
        ),
      ],
      child: MaterialApp(
        title: '宠物记',
        debugShowCheckedModeBanner: false,
        theme: PetjiTheme.light(),
        darkTheme: PetjiTheme.dark(),
        home: const _PetjiEntry(),
      ),
    );
  }
}

class _PetjiEntry extends ConsumerWidget {
  const _PetjiEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appSnapshotProvider);
    return snapshot.currentPet == null
        ? const OnboardingPage()
        : const PetjiShell();
  }
}
