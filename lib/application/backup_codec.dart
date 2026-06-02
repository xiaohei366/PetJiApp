import 'dart:convert';

import '../domain/models.dart';

class BackupCodec {
  const BackupCodec._();

  static String encode(AppSnapshot snapshot) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(snapshot.toJson());
  }

  static AppSnapshot decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Backup JSON root must be an object.');
    }
    final snapshot = AppSnapshot.fromJson(decoded.cast<String, Object?>());
    if (snapshot.version != 1 && snapshot.version != 2) {
      throw FormatException('Unsupported backup version ${snapshot.version}.');
    }
    if (snapshot.version == 1) {
      final activePetId =
          snapshot.activePetId ??
          (snapshot.pets.isEmpty ? null : snapshot.pets.first.id);
      return snapshot.copyWith(version: 2, activePetId: activePetId);
    }
    return snapshot;
  }
}
