int stableNotificationId({
  required String namespace,
  required String resourceId,
}) {
  var hash = 0x811c9dc5;
  for (final codeUnit in '$namespace:$resourceId'.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
