import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';

/// Loads remote feature flags and AI model selection from Firestore
/// (`app_config/global`), caching the last known values in Hive so the app
/// keeps working offline.
class AppConfigService extends ChangeNotifier {
  static const String defaultChatModel = 'gemini-3.8-flash';
  static const String defaultCompletionModel = 'gemini-3.5-flash-lite';
  static const int defaultReportAutoBlockThreshold = 5;

  static const String _boxName = 'app_config_cache';
  static const String _maintenanceKey = 'maintenance_mode';
  static const String _galleryKey = 'gallery_submissions_enabled';
  static const String _chatModelKey = 'ai_chat_model';
  static const String _completionModelKey = 'ai_completion_model';
  static const String _reportThresholdKey = 'report_auto_block_threshold';

  AppConfigService({FirebaseFirestore? firestore, this._cacheBox})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  bool _maintenanceMode = true;
  bool _gallerySubmissionsEnabled = true;
  String _aiChatModel = defaultChatModel;
  String _aiCompletionModel = defaultCompletionModel;
  int _reportAutoBlockThreshold = defaultReportAutoBlockThreshold;
  bool _loaded = false;
  Box<dynamic>? _cacheBox;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  bool get maintenanceMode => _maintenanceMode;
  bool get gallerySubmissionsEnabled => _gallerySubmissionsEnabled;
  String get aiChatModel => _aiChatModel;
  String get aiCompletionModel => _aiCompletionModel;
  int get reportAutoBlockThreshold => _reportAutoBlockThreshold;
  bool get loaded => _loaded;

  Future<void> initialize() async {
    _cacheBox ??= await Hive.openBox<dynamic>(_boxName);
    // Prime AI model names from cache so AI works before the first snapshot.
    final box = _cacheBox!;
    _aiChatModel = _readModel(box.get(_chatModelKey), defaultChatModel);
    _aiCompletionModel =
        _readModel(box.get(_completionModelKey), defaultCompletionModel);
  }

  Future<void> fetch() async {
    await initialize();
    await _subscription?.cancel();
    final firestore = _firestoreOverride ?? FirebaseFirestore.instance;
    _subscription = firestore
        .collection('app_config')
        .doc('global')
        .snapshots()
        .listen(
      (doc) {
        final data = doc.data();
        if (doc.exists && data != null) {
          applyRemoteData(data);
          unawaited(_cacheValues());
        }
        _loaded = true;
        notifyListeners();
      },
      onError: (Object e) async {
        debugPrint('[AppConfig] Stream error (fail-closed): $e');
        await _loadCachedValues();
        _loaded = true;
        notifyListeners();
      },
    );
  }

  /// Applies a raw `app_config/global` map. Exposed for tests.
  @visibleForTesting
  void applyRemoteData(Map<String, dynamic> data) {
    _maintenanceMode = data[_maintenanceKey] == true;
    _gallerySubmissionsEnabled = data[_galleryKey] != false;
    _aiChatModel = _readModel(data[_chatModelKey], defaultChatModel);
    _aiCompletionModel =
        _readModel(data[_completionModelKey], defaultCompletionModel);
    final threshold = data[_reportThresholdKey];
    _reportAutoBlockThreshold = threshold is num && threshold >= 1
        ? threshold.toInt()
        : defaultReportAutoBlockThreshold;
  }

  static String _readModel(Object? raw, String fallback) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return fallback;
  }

  Future<void> _cacheValues() async {
    final box = _cacheBox;
    if (box == null) return;
    await box.putAll({
      _maintenanceKey: _maintenanceMode,
      _galleryKey: _gallerySubmissionsEnabled,
      _chatModelKey: _aiChatModel,
      _completionModelKey: _aiCompletionModel,
      _reportThresholdKey: _reportAutoBlockThreshold,
    });
  }

  Future<void> _loadCachedValues() async {
    final box = _cacheBox;
    if (box == null || box.isEmpty) {
      _maintenanceMode = true;
      _gallerySubmissionsEnabled = true;
      return;
    }
    _maintenanceMode = box.get(_maintenanceKey, defaultValue: true) as bool;
    _gallerySubmissionsEnabled =
        box.get(_galleryKey, defaultValue: true) as bool;
    _aiChatModel = _readModel(box.get(_chatModelKey), defaultChatModel);
    _aiCompletionModel =
        _readModel(box.get(_completionModelKey), defaultCompletionModel);
    final threshold = box.get(_reportThresholdKey);
    _reportAutoBlockThreshold =
        threshold is int ? threshold : defaultReportAutoBlockThreshold;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
