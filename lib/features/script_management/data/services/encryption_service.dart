import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';

/// Service responsible for managing the Data Encryption Key (DEK).
/// Uses FlutterSecureStorage (Keychain/Keystore) to safely store the key.
///
/// The [FlutterSecureStorage] instance is injectable for testability.
class EncryptionService {
  final FlutterSecureStorage _storage;
  static const _keyAlias = 'script_automator_db_key';

  /// Creates an [EncryptionService] with optional injectable [storage].
  EncryptionService({FlutterSecureStorage? storage})
    : _storage = storage ?? AppSecureStorage.create();

  /// Retrieves the existing key or generates a new one.
  /// Returns a list of integers suitable for Hive encryption (32 bytes).
  Future<List<int>> getEncryptionKey() async {
    final base64Key = await AppSecureStorage.readMigratingLegacy(
      _storage,
      _keyAlias,
    );

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
