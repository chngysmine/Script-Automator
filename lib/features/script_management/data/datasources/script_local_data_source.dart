import 'package:hive_ce/hive.dart';
import 'package:meta/meta.dart';
import 'package:script_automator/features/script_management/data/models/script_model.dart';
import 'package:script_automator/features/script_management/data/services/encryption_service.dart';
import 'package:synchronized/synchronized.dart';

/// Exceptions for Data Layer
class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => "CacheException: $message";
}

/// Interface for Local Data Source
abstract class ScriptLocalDataSource {
  /// Returns a list of all script metadata (content empty/lazy).
  Future<List<ScriptModel>> getScriptsMetadata();

  /// Returns the full script details including content.
  Future<ScriptModel?> getScriptDetail(String id);

  /// Saves or updates a script (Metadata). Optional content update.
  Future<void> saveScript(ScriptModel script, {String? content});

  /// Get script content from separate storage.
  Future<String> getScriptContent(String id);

  /// Deletes a script by ID.
  Future<void> deleteScript(String id);
}

/// Implementation of [ScriptLocalDataSource] using Hive CE LazyBox.
///
/// Implements Dual-Store Architecture:
/// - Metadata Box: Stores lightweight [ScriptModel]s.
/// - Content Box: Stores raw script content strings.
class ScriptLocalDataSourceImpl implements ScriptLocalDataSource {
  LazyBox<ScriptModel>? _metadataBox;
  LazyBox<String>? _contentBox;
  final EncryptionService _encryptionService;
  final _saveLock = Lock();

  /// Setter for testing only: Allows injecting a mock metadata box.
  @visibleForTesting
  set testMetadataBox(LazyBox<ScriptModel> box) => _metadataBox = box;

  /// Setter for testing only: Allows injecting a mock content box.
  @visibleForTesting
  set testContentBox(LazyBox<String> box) => _contentBox = box;

  ScriptLocalDataSourceImpl(this._encryptionService);

  /// Initializes secure storage and opens Hive boxes.
  ///
  /// Throws [CacheException] if initialization fails.
  Future<void> init() async {
    if (_metadataBox != null &&
        _metadataBox!.isOpen &&
        _contentBox != null &&
        _contentBox!.isOpen) {
      return;
    }

    try {
      final key = await _encryptionService.getEncryptionKey();
      final cipher = HiveAesCipher(key);

      _metadataBox = await Hive.openLazyBox<ScriptModel>(
        'scripts_metadata_v2',
        encryptionCipher: cipher,
      );

      _contentBox = await Hive.openLazyBox<String>(
        'scripts_content_v2',
        encryptionCipher: cipher,
      );
    } catch (e) {
      throw CacheException("Failed to initialize secure storage: $e");
    }
  }

  /// Helper to ensure metadata box is initialized and open.
  Future<LazyBox<ScriptModel>> get _safeMetadataBox async {
    // If injected for test, skip init
    if (_metadataBox != null) return _metadataBox!;
    await init();
    return _metadataBox!;
  }

  /// Helper to ensure content box is initialized and open.
  Future<LazyBox<String>> get _safeContentBox async {
    if (_contentBox != null) return _contentBox!;
    await init();
    return _contentBox!;
  }

  @override
  Future<List<ScriptModel>> getScriptsMetadata() async {
    try {
      final box = await _safeMetadataBox;
      final keys = box.keys;

      // Parallel Read optimization (N+1 Solution)
      // Instead of awaiting sequentially, we fire all reads and wait for them.
      // For very large lists, we might batch this, but for <50k, Future.wait is fine.
      final futures = keys.map((key) => box.get(key));
      final results = await Future.wait(futures);

      return results.whereType<ScriptModel>().toList();
    } catch (e) {
      throw CacheException("Failed to fetch scripts metadata: $e");
    }
  }

  @override
  Future<String> getScriptContent(String id) async {
    try {
      final box = await _safeContentBox;
      final content = await box.get(id);
      return content ?? '';
    } catch (e) {
      throw CacheException("Failed to fetch script content: $e");
    }
  }

  @override
  Future<ScriptModel?> getScriptDetail(String id) async {
    try {
      final box = await _safeMetadataBox;
      return await box.get(id);
    } catch (e) {
      throw CacheException("Failed to fetch script detail: $e");
    }
  }

  @override
  Future<void> saveScript(ScriptModel script, {String? content}) async {
    // Race Condition Fix: Mutex Lock
    // Ensures that sequential saves to the same ID do not race.
    // T0: Save(A) -> locks
    // T1: Save(B) -> waits
    // T0: fails meta -> rollbacks -> releases
    // T1: Save(B) -> executes
    return _saveLock.synchronized(() async {
      try {
        // 1. Transaction Step A: Write Content (Potential Ghost Data if Step B fails)
        if (content != null) {
          final contentBox = await _safeContentBox;
          await contentBox.put(script.id, content);
        }

        // 2. Transaction Step B: Write Metadata
        try {
          final metaBox = await _safeMetadataBox;
          await metaBox.put(script.id, script);
        } catch (e) {
          // Rollback Strategy (Compensating Transaction):
          // If Metadata write fails, we must delete the orphaned content
          // to prevent "Bloatware" (Ghost Data).
          if (content != null) {
            try {
              final contentBox = await _safeContentBox;
              await contentBox.delete(script.id);
            } catch (rollbackError) {
              // Critical: Log this. We failed to rollback.
              // In a real app, report to Crashlytics.
              // ignore: avoid_print
              print(
                "CRITICAL: Failed to rollback orphaned content for ${script.id}: $rollbackError",
              );
            }
          }
          rethrow;
        }
      } catch (e) {
        throw CacheException("Failed to save script: $e");
      }
    });
  }

  @override
  Future<void> deleteScript(String id) async {
    try {
      final metaBox = await _safeMetadataBox;
      await metaBox.delete(id);

      final contentBox = await _safeContentBox;
      await contentBox.delete(id);
    } catch (e) {
      throw CacheException("Failed to delete script: $e");
    }
  }
}
