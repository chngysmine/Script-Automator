import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce/hive.dart';

/// Lightweight retry queue for failed Firestore sync operations.
///
/// When a sync operation fails (network error, Firestore timeout), it is
/// enqueued here. The queue monitors connectivity and retries with
/// exponential backoff when the device comes back online.
///
/// Retry metadata is persisted to a Hive box so pending operations survive
/// app restarts. Since closures are not serializable, the metadata signals
/// [AuthGate] to trigger a full sync on next launch instead of replaying
/// exact operations.
class SyncRetryQueue {
  static final SyncRetryQueue instance = SyncRetryQueue._();
  SyncRetryQueue._();

  final List<_RetryEntry> _queue = [];
  Timer? _retryTimer;
  StreamSubscription? _connectivitySub;
  bool _isRetrying = false;
  Box<Map>? _metaBox;

  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 2);
  static const String _boxName = 'sync_retry_metadata';

  /// Initialize the queue, open Hive persistence box, and start monitoring
  /// connectivity changes.
  Future<void> initialize() async {
    _metaBox = await Hive.openBox<Map>(_boxName);

    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && _queue.isNotEmpty) {
        debugPrint('[SyncRetryQueue] Connectivity restored — flushing ${_queue.length} pending operations');
        _flushQueue();
      }
    });
  }

  /// Whether there are persisted retry entries from a previous session.
  /// Used by [AuthGate] to decide between `syncBidirectional` vs `fullSync`.
  bool get hasPendingRetries => (_metaBox?.isNotEmpty ?? false) || _queue.isNotEmpty;

  /// Enqueue a failed sync operation for automatic retry.
  ///
  /// [label] is a human-readable description for logging.
  /// [operation] is the async function to retry.
  void enqueue(String label, Future<void> Function() operation) {
    _queue.add(_RetryEntry(label: label, operation: operation));
    _persistMeta(label);
    debugPrint('[SyncRetryQueue] Enqueued: "$label" (queue size: ${_queue.length})');
    _scheduleRetry();
  }

  /// Persist retry metadata to Hive for crash recovery.
  void _persistMeta(String label) {
    _metaBox?.add({
      'label': label,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Clear all persisted metadata (called after successful sync).
  void clearPersistedMeta() {
    _metaBox?.clear();
  }

  /// Schedule a retry attempt with exponential backoff.
  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(_baseDelay, _flushQueue);
  }

  /// Attempt to flush all queued operations.
  Future<void> _flushQueue() async {
    if (_isRetrying || _queue.isEmpty) return;
    _isRetrying = true;

    final toRetry = List<_RetryEntry>.from(_queue);
    _queue.clear();

    for (final entry in toRetry) {
      try {
        await entry.operation();
        debugPrint('[SyncRetryQueue] ✅ Success: "${entry.label}"');
      } catch (e) {
        entry.attempts++;
        if (entry.attempts < _maxRetries) {
          _queue.add(entry);
          debugPrint('[SyncRetryQueue] ⚠️ Retry ${entry.attempts}/$_maxRetries failed for "${entry.label}": $e');
        } else {
          debugPrint('[SyncRetryQueue] ❌ Gave up on "${entry.label}" after $_maxRetries attempts: $e');
        }
      }
    }

    _isRetrying = false;

    if (_queue.isEmpty) {
      clearPersistedMeta();
      debugPrint('[SyncRetryQueue] Queue fully drained — persisted metadata cleared');
    } else {
      final backoffDelay = _baseDelay * (1 << _queue.first.attempts.clamp(0, 4));
      _retryTimer = Timer(backoffDelay, _flushQueue);
      debugPrint('[SyncRetryQueue] Next retry in ${backoffDelay.inSeconds}s (${_queue.length} remaining)');
    }
  }

  /// Number of pending operations.
  int get pendingCount => _queue.length;

  /// Dispose the queue and cancel all timers.
  void dispose() {
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    _queue.clear();
  }
}

class _RetryEntry {
  final String label;
  final Future<void> Function() operation;
  int attempts = 0;

  _RetryEntry({required this.label, required this.operation});
}
