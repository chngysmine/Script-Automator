import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Fetches remote feature flags from Firestore `app_config/global`.
///
/// Provides reactive state for maintenance mode and gallery submissions
/// toggles set by admins via the Admin Dashboard. Uses a real-time
/// Firestore listener so admin changes take effect immediately on all
/// connected clients without requiring an app restart.
class AppConfigService extends ChangeNotifier {
  bool _maintenanceMode = false;
  bool _gallerySubmissionsEnabled = true;
  bool _loaded = false;
  StreamSubscription<DocumentSnapshot>? _subscription;

  bool get maintenanceMode => _maintenanceMode;
  bool get gallerySubmissionsEnabled => _gallerySubmissionsEnabled;
  bool get loaded => _loaded;

  Future<void> fetch() async {
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
        }
        _loaded = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[AppConfig] Stream error (fail-open): $e');
        _loaded = true;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
