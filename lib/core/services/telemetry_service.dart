import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Intercepts system events and tracks memory/performance.
///
/// Records telemetry to Firebase Firestore.
class TelemetryService {
  TelemetryService();

  Future<Box> _openBufferBox() async {
    return Hive.isBoxOpen('telemetry_buffer')
        ? Hive.box('telemetry_buffer')
        : await Hive.openBox('telemetry_buffer');
  }

  Map<String, dynamic> _buildTelemetryPayload({
    required String uid,
    required String scriptId,
    required String event,
    required String status,
    int? durationMs,
    String? errorTrace,
  }) {
    return {
      'user_id': uid,
      'script_id': scriptId,
      'event': event,
      'status': status,
      'duration_ms': durationMs,
      'error_trace': errorTrace,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  Future<void> flushBuffer() async {
    try {
      final box = await _openBufferBox();
      if (box.isEmpty) return;

      final entries = box.values.toList(growable: false);
      final firestore = FirebaseFirestore.instance;
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        if (entry is! String) continue;
        final data = jsonDecode(entry);
        if (data is! Map) continue;
        final payload = Map<String, dynamic>.from(data);
        await firestore.collection('telemetry_logs').add(payload);
      }
      await box.clear();
    } catch (e) {
      debugPrint('Telemetry Buffer Flush Error: $e');
    }
  }

  /// Registers or updates the user profile for the Admin Dashboard.
  Future<void> registerProfile() async {
    try {
      await flushBuffer();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (user.isAnonymous) return;

      final os = kIsWeb ? 'web' : Platform.operatingSystem;
      await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).set({
        'os': os,
        'app_version': '1.0.0+prod',
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("Telemetry: Profile registered/updated for $os");
    } catch (e) {
      debugPrint("Telemetry: Profile Register Error: $e");
    }
  }

  /// Tracks a successful widget deployment (Gallery → Device).
  Future<void> trackWidgetDeploy(String scriptId, {String family = 'medium'}) async {
    try {
      await FirebaseFirestore.instance.collection('widget_stats').add({
        'script_id': scriptId,
        'family': family,
        'timestamp': FieldValue.serverTimestamp(),
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
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final payload = _buildTelemetryPayload(
        uid: uid,
        scriptId: scriptId,
        event: event,
        status: status,
        durationMs: durationMs,
        errorTrace: errorTrace,
      );
      await FirebaseFirestore.instance.collection('telemetry_logs').add(payload);
    } catch (e) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final box = await _openBufferBox();
        final payload = _buildTelemetryPayload(
          uid: uid,
          scriptId: scriptId,
          event: event,
          status: status,
          durationMs: durationMs,
          errorTrace: errorTrace,
        );
        final encoded = jsonEncode(payload);
        while (box.length >= 100) {
          if (box.isNotEmpty) {
            await box.deleteAt(0);
          } else {
            break;
          }
        }
        await box.add(encoded);
      } catch (bufferError) {
        debugPrint('Telemetry Buffer Store Error: $bufferError');
      }
      debugPrint("Telemetry Insert Error: $e");
    }
  }

  void logMemoryUsage() {
    debugPrint("Telemetry: Memory Usage check initiated");
  }
}
