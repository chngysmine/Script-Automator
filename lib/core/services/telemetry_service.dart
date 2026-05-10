import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Intercepts system events and tracks memory/performance.
///
/// Gracefully degrades when Supabase is unavailable (offline, DNS failure,
/// or init timeout). Every public method is a no-op when [_client] is null.
class TelemetryService {
  final SupabaseClient? _client;

  TelemetryService() : _client = _resolveClient();

  static SupabaseClient? _resolveClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      debugPrint('[Telemetry] Supabase not available — telemetry disabled.');
      return null;
    }
  }

  /// Registers or updates the user profile for the Admin Dashboard.
  Future<void> registerProfile() async {
    if (_client == null) return;
    try {
      final os = kIsWeb ? 'web' : Platform.operatingSystem;
      await _client.from('user_profiles').upsert({
        'os': os,
        'app_version': '1.0.0+prod',
        'last_active': DateTime.now().toIso8601String(),
      });
      debugPrint("Telemetry: Profile registered/updated for $os");
    } catch (e) {
      debugPrint("Telemetry: Profile Register Error: $e");
    }
  }

  /// Tracks a successful widget deployment (Gallery → Device).
  Future<void> trackWidgetDeploy(String scriptId, {String family = 'medium'}) async {
    if (_client == null) return;
    try {
      await _client.from('widget_stats').insert({
        'script_id': scriptId,
        'family': family,
      });
      debugPrint("Telemetry: Widget deployment tracked for $scriptId");
    } catch (e) {
      debugPrint("Telemetry: Widget Track Error: $e");
    }
  }

  void recordScriptExecutionDuration(String scriptId, Duration duration) {
    debugPrint("Telemetry: Script $scriptId ran for ${duration.inMilliseconds}ms");
    _insertTelemetry(
      scriptId: scriptId,
      event: 'run',
      status: 'success',
      durationMs: duration.inMilliseconds,
    );
  }

  void captureEngineCrash(String cause, dynamic stackTrace, {String scriptId = 'unknown'}) {
    debugPrint("Telemetry: Capturing engine crash ($cause)");
    _insertTelemetry(
      scriptId: scriptId,
      event: 'crash',
      status: 'panic',
      errorTrace: 'Cause: $cause\n$stackTrace',
    );
  }

  void captureError(String scriptId, String error) {
    debugPrint("Telemetry: Script $scriptId encountered error: $error");
    _insertTelemetry(
      scriptId: scriptId,
      event: 'error',
      status: 'failed',
      errorTrace: error,
    );
  }

  Future<void> _insertTelemetry({
    required String scriptId,
    required String event,
    required String status,
    int? durationMs,
    String? errorTrace,
  }) async {
    if (_client == null) return;
    try {
      await _client.from('telemetry_logs').insert({
        'script_id': scriptId,
        'event': event,
        'status': status,
        'duration_ms': durationMs,
        'error_trace': errorTrace,
      });
    } catch (e) {
      debugPrint("Telemetry Insert Error: $e");
    }
  }

  void logMemoryUsage() {
    debugPrint("Telemetry: Memory Usage check initiated");
  }
}
