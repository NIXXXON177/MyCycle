import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Хэширование PIN для хранения в SharedPreferences и резервной копии.
abstract final class PinHasher {
  static const _salt = 'mycycle.pin.v1';

  static String hash(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verify(String pin, String storedHash) => hash(pin) == storedHash;
}
