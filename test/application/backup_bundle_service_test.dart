import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:petji/application/backup_bundle_service.dart';
import 'package:petji/domain/models.dart';

void main() {
  test(
    'exports petji bundle with manifest, snapshot, media, and files',
    () async {
      final temp = await Directory.systemTemp.createTemp('petji_bundle_test_');
      addTearDown(() => temp.delete(recursive: true));
      final mediaSource = File(p.join(temp.path, 'camera photo.jpg'))
        ..writeAsStringSync('photo-bytes');
      final fileSource = File(p.join(temp.path, 'report.pdf'))
        ..writeAsStringSync('pdf-bytes');
      final snapshot = AppSnapshot.empty(now: DateTime(2026, 6, 1)).copyWith(
        mediaAssets: [
          MediaAsset(
            id: 'media-1',
            petId: 'pet-1',
            type: MediaType.photo,
            localPath: mediaSource.path,
            capturedAt: DateTime(2026, 6, 1),
            createdAt: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 6, 1),
          ),
        ],
        records: [
          CareRecord(
            id: 'care-1',
            petId: 'pet-1',
            category: CareCategory.report,
            happenedAt: DateTime(2026, 6, 1),
            title: 'Report',
            reportPath: fileSource.path,
            createdAt: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 6, 1),
          ),
        ],
      );

      final bundlePath = p.join(temp.path, 'backup.petji');
      await BackupBundleService().exportBundle(
        snapshot: snapshot,
        outputPath: bundlePath,
      );

      final archive = ZipDecoder().decodeBytes(
        File(bundlePath).readAsBytesSync(),
      );
      final names = archive.files.map((file) => file.name).toSet();
      final manifestFile = archive.findFile('manifest.json')!;
      final snapshotFile = archive.findFile('snapshot.json')!;

      expect(names, containsAll(['manifest.json', 'snapshot.json']));
      expect(names.any((name) => name.startsWith('media/')), isTrue);
      expect(names.any((name) => name.startsWith('files/')), isTrue);
      expect(
        jsonDecode(utf8.decode(manifestFile.content as List<int>))['format'],
        'petji.bundle',
      );
      expect(
        AppSnapshot.fromJson(
          jsonDecode(utf8.decode(snapshotFile.content as List<int>)),
        ).version,
        2,
      );
    },
  );

  test('imports petji bundle and rewrites bundled file paths', () async {
    final temp = await Directory.systemTemp.createTemp('petji_bundle_import_');
    addTearDown(() => temp.delete(recursive: true));
    final avatarSource = File(p.join(temp.path, 'avatar.jpg'))
      ..writeAsStringSync('avatar-bytes');
    final reportSource = File(p.join(temp.path, 'checkup.pdf'))
      ..writeAsStringSync('report-bytes');
    final now = DateTime(2026, 6, 1);
    final snapshot = AppSnapshot.empty(now: now).copyWith(
      activePetId: 'pet-1',
      pets: [
        PetProfile(
          id: 'pet-1',
          name: '奶糖',
          species: PetSpecies.cat,
          breed: '',
          birthday: DateTime(2024, 1, 1),
          sex: PetSex.unknown,
          isNeutered: false,
          avatarPath: avatarSource.path,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      timelineEvents: [
        TimelineEvent(
          id: 'event-1',
          petId: 'pet-1',
          type: TimelineEventType.report,
          happenedAt: now,
          title: '体检报告',
          filePath: reportSource.path,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final bundlePath = p.join(temp.path, 'backup.petji');
    await BackupBundleService().exportBundle(
      snapshot: snapshot,
      outputPath: bundlePath,
    );

    final preview = await BackupBundleService().importBundle(bundlePath);
    expect(preview.pets.single.avatarPath, startsWith('media/'));
    expect(preview.timelineEvents.single.filePath, startsWith('files/'));

    final destination = Directory(p.join(temp.path, 'restored'));
    final imported = await BackupBundleService().importBundle(
      bundlePath,
      destinationDirectory: destination.path,
    );

    final avatarPath = imported.pets.single.avatarPath!;
    final reportPath = imported.timelineEvents.single.filePath!;
    expect(p.isWithin(destination.path, avatarPath), isTrue);
    expect(p.isWithin(destination.path, reportPath), isTrue);
    expect(File(avatarPath).readAsStringSync(), 'avatar-bytes');
    expect(File(reportPath).readAsStringSync(), 'report-bytes');
  });

  test('rejects unsafe petji bundle paths', () async {
    final temp = await Directory.systemTemp.createTemp('petji_bundle_unsafe_');
    addTearDown(() => temp.delete(recursive: true));
    final now = DateTime(2026, 6, 1);
    final snapshot = AppSnapshot.empty(now: now).copyWith(
      activePetId: 'pet-1',
      pets: [
        PetProfile(
          id: 'pet-1',
          name: '奶糖',
          species: PetSpecies.cat,
          breed: '',
          birthday: DateTime(2024, 1, 1),
          sex: PetSex.unknown,
          isNeutered: false,
          avatarPath: 'media/../../escape.jpg',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({
            'format': 'petji.bundle',
            'version': 1,
            'snapshotVersion': 2,
            'files': [
              {'kind': 'media', 'path': 'media/../../escape.jpg'},
            ],
          }),
        ),
      )
      ..addFile(
        ArchiveFile.string('snapshot.json', jsonEncode(snapshot.toJson())),
      )
      ..addFile(ArchiveFile.string('media/../../escape.jpg', 'escape'));
    final bundlePath = p.join(temp.path, 'unsafe.petji');
    File(bundlePath).writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    await expectLater(
      BackupBundleService().importBundle(
        bundlePath,
        destinationDirectory: p.join(temp.path, 'restored'),
      ),
      throwsFormatException,
    );
    expect(File(p.join(temp.path, 'escape.jpg')).existsSync(), isFalse);
  });
}
