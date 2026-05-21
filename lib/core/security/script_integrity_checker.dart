import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility for verifying the integrity of downloaded scripts
/// against a known SHA-256 hash stored in the gallery index.
///
/// Prevents MITM attacks from injecting malicious JS into
/// scripts downloaded from raw GitHub URLs.
class ScriptIntegrityChecker {
  /// Computes the SHA-256 hash of a script's content.
  ///
  /// @param content The raw string content of the JS script.
  /// @return String The hex-encoded SHA-256 hash.
  static String computeHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies that a script's content matches the expected hash.
  ///
  /// @param content The downloaded script content.
  /// @param expectedHash The SHA-256 hash from index.json.
  /// @return bool True if hashes match, false if tampered.
  static bool verify(String content, String? expectedHash) {
    if (expectedHash == null || expectedHash.isEmpty) {
      return false;
    }
    final actualHash = computeHash(content);
    return actualHash == expectedHash;
  }
}
