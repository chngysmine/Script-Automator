import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/adapters.dart';

/// Loads remote feature flags from Firestore.
class AppConfigService extends ChangeNotifier {
  static const String _boxName = 'app_config_cache';
  static const String _maintenanceKey = 'maintenance_mode';
  static const String _galleryKey = 'gallery_submissions_enabled';

  bool _maintenanceMode = true;
  bool _gallerySubmissionsEnabled = true;
  bool _loaded = false;
  Box<dynamic>? _cacheBox;
  StreamSubscription<DocumentSnapshot>? _subscription;

  bool get maintenanceMode => _maintenanceMode;
  bool get gallerySubmissionsEnabled => _gallerySubmissionsEnabled;
  bool get loaded => _loaded;

  Future<void> initialize() async {
    _cacheBox ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> fetch() async {
    await initialize();
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('app_config')
        .doc('global')
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists) {
          final data = doc.data()!;
          _maintenanceMode = data['maintenance_mode'] == true;
          _gallerySubmissionsEnabled =
              data['gallery_submissions_enabled'] != false;
          _cacheValues();
        }
        _loaded = true;
        notifyListeners();
      },
      onError: (e) async {
        debugPrint('[AppConfig] Stream error (fail-closed): $e');
        await _loadCachedValues();
        _loaded = true;
        notifyListeners();
      },
    );
  }

  Future<void> _cacheValues() async {
    final box = _cacheBox;
    if (box == null) {
      return;
    }
    await box.put(_maintenanceKey, _maintenanceMode);
    await box.put(_galleryKey, _gallerySubmissionsEnabled);
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
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
