import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../domain/models.dart';
import 'backup_codec.dart';

class BackupBundleService {
  const BackupBundleService();

  Future<void> exportBundle({
    required AppSnapshot snapshot,
    required String outputPath,
  }) async {
    final archive = Archive();
    final snapshotJson = snapshot.toJson();
    final bundledFiles = <Map<String, Object?>>[];

    final pets = snapshotJson['pets'] as List<Object?>;
    for (final item in pets.cast<Map<String, Object?>>()) {
      final avatarPath = await _addFileIfPresent(
        archive: archive,
        sourcePath: item['avatarPath'] as String?,
        directory: 'media',
        id: '${item['id']}_avatar',
      );
      if (avatarPath != null) {
        item['avatarPath'] = avatarPath;
        bundledFiles.add({'kind': 'media', 'path': avatarPath});
      }
    }

    final mediaAssets = snapshotJson['mediaAssets'] as List<Object?>;
    for (final item in mediaAssets.cast<Map<String, Object?>>()) {
      final source = item['localPath'] as String?;
      final archivePath = await _addFileIfPresent(
        archive: archive,
        sourcePath: source,
        directory: 'media',
        id: item['id'] as String,
      );
      if (archivePath != null) {
        item['localPath'] = archivePath;
        bundledFiles.add({'kind': 'media', 'path': archivePath});
      }
    }

    final records = snapshotJson['records'] as List<Object?>;
    for (final item in records.cast<Map<String, Object?>>()) {
      final reportPath = await _addFileIfPresent(
        archive: archive,
        sourcePath: item['reportPath'] as String?,
        directory: 'files',
        id: item['id'] as String,
      );
      if (reportPath != null) {
        item['reportPath'] = reportPath;
        bundledFiles.add({'kind': 'file', 'path': reportPath});
      }
      final mediaPath = await _addFileIfPresent(
        archive: archive,
        sourcePath: item['mediaPath'] as String?,
        directory: 'media',
        id: item['id'] as String,
      );
      if (mediaPath != null) {
        item['mediaPath'] = mediaPath;
        bundledFiles.add({'kind': 'media', 'path': mediaPath});
      }
    }

    final timelineEvents = snapshotJson['timelineEvents'] as List<Object?>;
    for (final item in timelineEvents.cast<Map<String, Object?>>()) {
      final filePath = await _addFileIfPresent(
        archive: archive,
        sourcePath: item['filePath'] as String?,
        directory: 'files',
        id: item['id'] as String,
      );
      if (filePath != null) {
        item['filePath'] = filePath;
        bundledFiles.add({'kind': 'file', 'path': filePath});
      }
      final mediaPath = await _addFileIfPresent(
        archive: archive,
        sourcePath: item['mediaPath'] as String?,
        directory: 'media',
        id: item['id'] as String,
      );
      if (mediaPath != null) {
        item['mediaPath'] = mediaPath;
        bundledFiles.add({'kind': 'media', 'path': mediaPath});
      }
    }

    archive.addFile(
      ArchiveFile.string(
        'manifest.json',
        jsonEncode({
          'format': 'petji.bundle',
          'version': 1,
          'snapshotVersion': snapshot.version,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'files': bundledFiles,
        }),
      ),
    );
    archive.addFile(
      ArchiveFile.string(
        'snapshot.json',
        const JsonEncoder.withIndent('  ').convert(snapshotJson),
      ),
    );

    final bytes = ZipEncoder().encodeBytes(archive);
    await File(outputPath).writeAsBytes(bytes);
  }

  Future<AppSnapshot> importBundle(
    String bundlePath, {
    String? destinationDirectory,
  }) async {
    final archive = ZipDecoder().decodeBytes(
      await File(bundlePath).readAsBytes(),
    );
    final allowedPaths = _manifestPaths(archive);
    final snapshotFile = archive.findFile('snapshot.json');
    if (snapshotFile == null) {
      throw const FormatException('Petji bundle is missing snapshot.json.');
    }
    final content = snapshotFile.content as List<int>;
    final decodedJson = jsonDecode(utf8.decode(content));
    if (decodedJson is! Map) {
      throw const FormatException(
        'Petji bundle snapshot root must be an object.',
      );
    }
    final snapshotJson = decodedJson.cast<String, Object?>();
    _validateBundlePaths(
      archive: archive,
      snapshotJson: snapshotJson,
      allowedPaths: allowedPaths,
    );
    if (destinationDirectory != null) {
      await _extractBundleFiles(
        archive: archive,
        snapshotJson: snapshotJson,
        destinationDirectory: destinationDirectory,
        allowedPaths: allowedPaths,
      );
    }
    return BackupCodec.decode(jsonEncode(snapshotJson));
  }

  Future<void> _extractBundleFiles({
    required Archive archive,
    required Map<String, Object?> snapshotJson,
    required String destinationDirectory,
    required Set<String> allowedPaths,
  }) async {
    final root = p.normalize(p.absolute(destinationDirectory));
    for (final path in _bundlePaths(snapshotJson)) {
      final normalizedPath = _checkedBundlePath(path, allowedPaths);
      final file = archive.findFile(normalizedPath)!;
      final bytes = file.content as List<int>;
      final targetPath = p.normalize(p.absolute(p.join(root, normalizedPath)));
      if (!p.isWithin(root, targetPath)) {
        throw FormatException('Illegal bundle path target: $path');
      }
      final target = File(targetPath);
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes);
      _replaceBundlePath(snapshotJson, normalizedPath, targetPath);
    }
  }

  Set<String> _manifestPaths(Archive archive) {
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('Petji bundle is missing manifest.json.');
    }
    final decoded = jsonDecode(utf8.decode(manifestFile.content as List<int>));
    if (decoded is! Map) {
      throw const FormatException('Petji bundle manifest root must be object.');
    }
    if (decoded['format'] != 'petji.bundle') {
      throw const FormatException('Invalid Petji bundle manifest format.');
    }
    final files = decoded['files'];
    if (files is! List) {
      throw const FormatException('Petji bundle manifest files must be list.');
    }
    return {
      for (final item in files)
        if (item is Map && item['path'] is String)
          _checkedBundlePath(item['path'] as String, null),
    };
  }

  void _validateBundlePaths({
    required Archive archive,
    required Map<String, Object?> snapshotJson,
    required Set<String> allowedPaths,
  }) {
    for (final path in _bundlePaths(snapshotJson)) {
      final normalizedPath = _checkedBundlePath(path, allowedPaths);
      if (archive.findFile(normalizedPath) == null) {
        throw FormatException('Petji bundle is missing file: $normalizedPath');
      }
    }
  }

  Set<String> _bundlePaths(Map<String, Object?> snapshotJson) {
    final paths = <String>{};
    for (final item in (snapshotJson['pets'] as List<Object?>? ?? const [])) {
      _addRelativePath(paths, (item as Map)['avatarPath'] as String?);
    }
    for (final item
        in (snapshotJson['mediaAssets'] as List<Object?>? ?? const [])) {
      _addRelativePath(paths, (item as Map)['localPath'] as String?);
    }
    for (final item
        in (snapshotJson['records'] as List<Object?>? ?? const [])) {
      final map = item as Map;
      _addRelativePath(paths, map['reportPath'] as String?);
      _addRelativePath(paths, map['mediaPath'] as String?);
    }
    for (final item
        in (snapshotJson['timelineEvents'] as List<Object?>? ?? const [])) {
      final map = item as Map;
      _addRelativePath(paths, map['filePath'] as String?);
      _addRelativePath(paths, map['mediaPath'] as String?);
    }
    return paths;
  }

  void _addRelativePath(Set<String> paths, String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    if (!_isBundleRelative(value)) {
      throw FormatException(
        'External file path is not allowed in .petji: $value',
      );
    }
    paths.add(value);
  }

  void _replaceBundlePath(
    Map<String, Object?> snapshotJson,
    String oldPath,
    String newPath,
  ) {
    for (final item in (snapshotJson['pets'] as List<Object?>? ?? const [])) {
      final map = (item as Map).cast<String, Object?>();
      if (map['avatarPath'] == oldPath) {
        map['avatarPath'] = newPath;
      }
    }
    for (final item
        in (snapshotJson['mediaAssets'] as List<Object?>? ?? const [])) {
      final map = (item as Map).cast<String, Object?>();
      if (map['localPath'] == oldPath) {
        map['localPath'] = newPath;
      }
    }
    for (final item
        in (snapshotJson['records'] as List<Object?>? ?? const [])) {
      final map = (item as Map).cast<String, Object?>();
      if (map['reportPath'] == oldPath) {
        map['reportPath'] = newPath;
      }
      if (map['mediaPath'] == oldPath) {
        map['mediaPath'] = newPath;
      }
    }
    for (final item
        in (snapshotJson['timelineEvents'] as List<Object?>? ?? const [])) {
      final map = (item as Map).cast<String, Object?>();
      if (map['filePath'] == oldPath) {
        map['filePath'] = newPath;
      }
      if (map['mediaPath'] == oldPath) {
        map['mediaPath'] = newPath;
      }
    }
  }

  Future<String?> _addFileIfPresent({
    required Archive archive,
    required String? sourcePath,
    required String directory,
    required String id,
  }) async {
    if (sourcePath == null ||
        sourcePath.isEmpty ||
        _isBundleRelative(sourcePath)) {
      return sourcePath;
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      return null;
    }
    final archivePath = '$directory/${_safeArchiveName(id, sourcePath)}';
    archive.addFile(ArchiveFile.bytes(archivePath, await source.readAsBytes()));
    return archivePath;
  }

  bool _isBundleRelative(String path) {
    return path.startsWith('media/') || path.startsWith('files/');
  }

  String _checkedBundlePath(String path, Set<String>? allowedPaths) {
    if (path.contains(r'\') ||
        p.posix.isAbsolute(path) ||
        p.windows.isAbsolute(path)) {
      throw FormatException('Illegal bundle path: $path');
    }
    final normalized = p.posix.normalize(path);
    final segments = normalized.split('/');
    if (normalized != path ||
        segments.contains('..') ||
        segments.contains('.') ||
        !_isBundleRelative(normalized)) {
      throw FormatException('Illegal bundle path: $path');
    }
    if (allowedPaths != null && !allowedPaths.contains(normalized)) {
      throw FormatException('Bundle path is not declared in manifest: $path');
    }
    return normalized;
  }

  String _safeArchiveName(String id, String sourcePath) {
    final basename = p
        .basename(sourcePath)
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return '${id}_$basename';
  }
}
