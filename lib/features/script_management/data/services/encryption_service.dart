import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service responsible for managing the Data Encryption Key (DEK).
/// Uses FlutterSecureStorage (Keychain/Keystore) to safely store the key.
class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'script_automator_db_key';

  /// Retrieves the existing key or generates a new one.
  /// Returns a list of integers suitable for Hive encryption (32 bytes).
  Future<List<int>> getEncryptionKey() async {
    // 1. Try to read existing key
    final base64Key = await _storage.read(key: _keyAlias);

    if (base64Key != null) {
      return base64Decode(base64Key);
    }

    // 2. Generate new 32-byte key
    final newKey = _generateRandomKey();

    // 3. Save to secure storage
    await _storage.write(key: _keyAlias, value: base64Encode(newKey));

    return newKey;
  }

  List<int> _generateRandomKey() {
    final random = Random.secure();
    return List<int>.generate(32, (i) => random.nextInt(256));
  }
}
