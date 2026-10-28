import 'dart:async';

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:script_automator/firebase_options.dart';

/// Boots Firebase plus App Check and Crashlytics.
///
/// Every step is isolated in try/catch: the app must still start offline or
/// when a Firebase service is misconfigured (offline-first rule).
abstract final class FirebaseBootstrap {
  static bool _initialized = false;

  /// Debug tokens can be pinned via `--dart-define=APP_CHECK_DEBUG_TOKEN=...`
  /// so the same token can be registered once in the Firebase console.
  static const String _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

  /// App Check is opt-in per build until providers (Play Integrity SHA-256,
  /// App Attest team ID, debug tokens) are registered in the console:
  /// once activated, Firebase AI Logic refuses to send requests whenever a
  /// token can't be minted — even with enforcement off.
  ///   flutter build ... --dart-define=ENABLE_APP_CHECK=true
  static const bool appCheckEnabled = bool.fromEnvironment('ENABLE_APP_CHECK');

  /// Offline demo fallback: point Auth/Firestore/Storage/Functions at the
  /// Firebase Emulator Suite (`functions/ npm run demo`). Debug builds only.
  ///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true \
  ///     [--dart-define=FIREBASE_EMULATOR_HOST=192.168.1.20]
  static const bool useEmulator =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR') && !kReleaseMode;
  static const String _emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');

  static FirebaseApp? _aiApp;

  /// App used for Firebase AI Logic. In emulator mode a secondary app keeps
  /// emulator-issued ID tokens (rejected by the real backend) off AI calls.
  static FirebaseApp get aiApp => _aiApp ?? Firebase.app();

  static Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('[BOOT] Firebase init failed (degraded mode): $e');
      return false;
    }
    _initialized = true;
    if (useEmulator) await _connectEmulators();
    await _activateAppCheck();
    _wireCrashlytics();
    return true;
  }

  static Future<void> _connectEmulators() async {
    // Android emulators reach the host machine through 10.0.2.2.
    final host = _emulatorHost.isNotEmpty
        ? _emulatorHost
        : (!kIsWeb && Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      _aiApp = await Firebase.initializeApp(
        name: 'ai',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[BOOT] ⚠️ Using Firebase emulators at $host (offline demo mode).');
    } catch (e) {
      debugPrint('[BOOT] Emulator connection failed: $e');
    }
  }

  static Future<void> _activateAppCheck() async {
    // Not touching FirebaseAppCheck.instance keeps the service unregistered,
    // so firebase_ai sends requests without an App Check header.
    if (!appCheckEnabled) {
      debugPrint('[BOOT] App Check disabled (build without ENABLE_APP_CHECK=true).');
      return;
    }
    try {
      final token = _debugToken.isEmpty ? null : _debugToken;
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : AndroidDebugProvider(debugToken: token),
        providerApple: kReleaseMode
            ? const AppleAppAttestWithDeviceCheckFallbackProvider()
            : AppleDebugProvider(debugToken: token),
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    } catch (e) {
      debugPrint('[BOOT] App Check activation failed: $e');
    }
  }

  static void _wireCrashlytics() {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      // Debug builds keep errors local so test crashes don't pollute the console.
      unawaited(crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode));

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (!kDebugMode) crashlytics.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('[UNCAUGHT] $error\n$stack');
        if (!kDebugMode) {
          crashlytics.recordError(error, stack, fatal: true);
        }
        return true;
      };
    } catch (e) {
      debugPrint('[BOOT] Crashlytics wiring failed: $e');
    }
  }

  /// Links crash reports to the signed-in user (uid only, no PII).
  static Future<void> setUser(String? uid) async {
    if (!_initialized) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '');
    } catch (_) {}
  }
}
