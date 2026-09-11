/// Small, dependency-free UUIDv4 generator (RFC 4122) for entity IDs.
library;

import 'dart:math';

final Random _rng = Random.secure();

String generateId() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  // Set version (4) and variant (10xx) bits.
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  String h(int part) => bytes[part].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-'
      '${h(4)}${h(5)}-'
      '${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-'
      '${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
