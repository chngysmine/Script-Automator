import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Fetches remote feature flags from Firestore `app_config/global`.
///
/// Provides reactive state for maintenance mode and gallery submissions
/// toggles set by admins via the Admin Dashboard. Falls back to permissive
/// defaults if the fetch fails (fail-open to avoid blocking app launch).
class AppConfigService extends ChangeNotifier {
  bool _maintenanceMode = false;
  bool _gallerySubmissionsEnabled = true;
  bool _loaded = false;

  bool get maintenanceMode => _maintenanceMode;
  bool get gallerySubmissionsEnabled => _gallerySubmissionsEnabled;
  bool get loaded => _loaded;

  Future<void> fetch() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('global')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _maintenanceMode = data['maintenance_mode'] == true;
        _gallerySubmissionsEnabled =
            data['gallery_submissions_enabled'] != false;
        _loaded = true;
        notifyListeners();
      } else {
        _loaded = true;
      }
    } catch (e) {
      debugPrint('[AppConfig] Fetch failed (fail-open): $e');
      _loaded = true;
    }
  }
}
