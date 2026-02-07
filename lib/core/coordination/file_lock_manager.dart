import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

/// Manages cross-process file locking to prevent data corruption
/// when multiple concurrent processes (Main App, Widget Extension, Background Worker)
/// access shared resources (Shared Preferences, Database Files).
class FileLockManager {
  final _logger = Logger('FileLockManager');

  /// Executes [action] while holding a lock on [lockFile].
  ///
  /// [mode]:
  /// - [FileLock.shared] for READ operations (multiple readers allowed).
  /// - [FileLock.exclusive] for WRITE operations (one writer, no readers).
  ///
  /// Uses [RandomAccessFile.lock] which maps to flock(2) on Unix (iOS/Android).
  Future<T> runWithLock<T>(
    File lockFile,
    Future<T> Function() action, {
    FileLock mode = FileLock.exclusive,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    RandomAccessFile? raf;
    try {
      // Ensure file exists
      if (!await lockFile.exists()) {
        try {
          await lockFile.create(recursive: true);
        } catch (e) {
          // Race condition on creation possible? Catch and proceed if exists.
        }
      }

      raf = await lockFile.open(mode: FileMode.write);

      // Attempt Lock
      // dart:io lock is blocking or non-blocking?
      // lock() is Async but might block the isolate waiting for OS lock.
      // We implement a timeout mechanism.

      await raf
          .lock(mode)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                "Failed to acquire lock on ${lockFile.path} within $timeout",
              );
            },
          );

      _logger.fine("Lock acquired (${mode.toString()}) on ${lockFile.path}");

      // Run Accessor
      return await action();
    } catch (e) {
      _logger.severe("Lock Error: $e");
      rethrow;
    } finally {
      if (raf != null) {
        try {
          await raf.unlock();
          await raf.close();
          _logger.fine("Lock released on ${lockFile.path}");
        } catch (e) {
          _logger.warning("Error releasing lock: $e");
        }
      }
    }
  }
}
