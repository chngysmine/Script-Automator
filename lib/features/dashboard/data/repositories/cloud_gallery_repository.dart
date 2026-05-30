import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/core/security/script_integrity_checker.dart';

/// Fetches community gallery scripts from the Firestore `gallery_published` collection.
///
/// Primary source: Firestore `gallery_published` (real-time, admin-managed).
/// Falls back to a minimal built-in set if offline.
///
/// Submissions are uploaded to Firebase Storage with metadata stored in
/// Firestore `gallery_submissions`.
class CloudGalleryRepository implements GalleryRepository {
  @override
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gallery_published')
          .orderBy('published_at', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final scripts = snapshot.docs.map<Map<String, dynamic>>((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'description': data['description'] ?? '',
            'author': data['author'] ?? '',
            'category': data['category'] ?? 'Utilities',
            'version': data['version'] ?? '1.0.0',
            'icon': data['icon'] ?? 'gear',
            'isFeatured': (data['isFeatured'] == true).toString(),
            'scriptUrl': data['file_url'] ?? '',
            'sha256': data['sha256'] ?? '',
            'coverUrl': '',
            'config': data['config'],
          };
        }).toList();
        return await _filterBlockedScripts(scripts);
      }

      debugPrint('[Gallery] No published scripts found, using offline fallback.');
      return _getOfflineFallback();
    } catch (e) {
      debugPrint('[Gallery] Fetch error: $e');
      return _getOfflineFallback();
    }
  }

  @override
  Future<void> submitScript(Map<String, dynamic> submission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User is not logged in.");

    final content = submission['content'] as String? ?? '';
    final scriptId = submission['script_id'] as String? ?? 'untitled';

    // 1. Upload JS content to Firebase Storage
    String fileUrl = '';
    int fileSize = 0;
    String sha256Hash = '';

    if (content.isNotEmpty) {
      final storageRef = FirebaseStorage.instance
          .ref('submissions/${user.uid}/$scriptId.js');
      await storageRef.putString(
        content,
        format: PutStringFormat.raw,
        metadata: SettableMetadata(contentType: 'text/javascript'),
      );
      fileUrl = await storageRef.getDownloadURL();
      fileSize = content.length;
      sha256Hash = ScriptIntegrityChecker.computeHash(content);
    }

    // 2. Write metadata to Firestore (content NOT stored in document)
    final metadata = <String, dynamic>{
      'user_id': user.uid,
      'script_id': scriptId,
      'name': submission['name'] ?? 'Untitled',
      'description': submission['description'] ?? '',
      'category': submission['category'] ?? 'Utilities',
      'author': user.displayName ?? user.email ?? 'Anonymous',
      'version': submission['version'] ?? '1.0.0',
      'status': 'pending',
      'file_url': fileUrl,
      'file_size': fileSize,
      'sha256': sha256Hash,
      'created_at': FieldValue.serverTimestamp(),
    };

    if (submission.containsKey('original_gallery_id')) {
      metadata['original_gallery_id'] = submission['original_gallery_id'];
    }

    await FirebaseFirestore.instance
        .collection('gallery_submissions')
        .add(metadata);
  }

  /// Queries the Firestore `script_moderation` collection and strips out blocked items.
  Future<List<Map<String, dynamic>>> _filterBlockedScripts(List<Map<String, dynamic>> rawScripts) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('script_moderation')
          .where('is_blocked', isEqualTo: true)
          .get();
          
      final blockedIds = snapshot.docs.map((doc) => doc.id).toSet();
      if (blockedIds.isEmpty) return rawScripts;

      final filtered = rawScripts.where((script) => !blockedIds.contains(script['id'])).toList();
      debugPrint("Moderation: Removed ${rawScripts.length - filtered.length} blocked scripts from gallery.");
      return filtered;
    } catch (e) {
      debugPrint('Moderation check failed (fail-closed): $e');
      return [];
    }
  }

  /// Minimal offline fallback with a single example per category.
  ///
  /// This ensures the Explore page is never entirely empty even without
  /// network connectivity. Scripts are simple, self-contained, and valid.
  List<Map<String, dynamic>> _getOfflineFallback() {
    return [
      {
        'id': 'weather_pro_v2',
        'name': 'Weather Pro',
        'description': 'Beautiful weather widget with live gradients.',
        'author': 'Script Automator Team',
        'category': 'Weather',
        'version': '2.0.1',
        'icon': 'cloud.sun.fill',
        'isFeatured': 'true',
        'content': _kWeatherScript,
        'scriptUrl': '',
        'coverUrl': '',
      },
      {
        'id': 'crypto_portfolio_tracker',
        'name': 'Crypto Portfolio',
        'description': 'Bitcoin and Ethereum price tracker.',
        'author': 'CryptoDevs',
        'category': 'Finance',
        'version': '1.0.0',
        'icon': 'bitcoinsign.circle.fill',
        'isFeatured': 'false',
        'content': _kCryptoScript,
        'scriptUrl': '',
        'coverUrl': '',
      },
      {
        'id': 'system_monitor',
        'name': 'System Monitor',
        'description': 'Display time, date, OS, and locale.',
        'author': 'Script Automator Team',
        'category': 'Utilities',
        'version': '1.5.0',
        'icon': 'gear',
        'isFeatured': 'false',
        'content': _kSystemScript,
        'scriptUrl': '',
        'coverUrl': '',
      },
    ];
  }

  // ---------------------------------------------------------------------------
  // Embedded fallback script content (minimal, production-valid).
  // ---------------------------------------------------------------------------

  static const String _kWeatherScript = '''
const widget = {
  type: "container",
  modifiers: {
    background: "linear-gradient(135deg, #667eea, #764ba2)",
    cornerRadius: 24,
    padding: { runtimeType: "all", value: 20 }
  },
  children: [
    {
      type: "row",
      modifiers: { alignment: "spaceBetween" },
      children: [
        {
          type: "column",
          children: [
            { type: "text", content: "San Francisco", modifiers: { font: "title", color: "#FFFFFF", fontSize: 22 } },
            { type: "text", content: "Partly Cloudy", modifiers: { font: "body", color: "#E0E0FF", fontSize: 16 } }
          ]
        },
        { type: "icon", content: "cloud.sun.fill", modifiers: { fontSize: 48, color: "#FFD700" } }
      ]
    },
    { type: "spacer", modifiers: { height: 24 } },
    { type: "text", content: "72°", modifiers: { font: "largeTitle", color: "#FFFFFF", fontSize: 56, fontWeight: "bold" } },
    { type: "spacer", modifiers: { height: 12 } },
    {
      type: "row",
      children: [
        { type: "icon", content: "drop.fill", modifiers: { fontSize: 16, color: "#A5F3FC" } },
        { type: "spacer", modifiers: { width: 4 } },
        { type: "text", content: "15%", modifiers: { color: "#A5F3FC" } },
        { type: "spacer", modifiers: { width: 16 } },
        { type: "icon", content: "wind", modifiers: { fontSize: 16, color: "#A5F3FC" } },
        { type: "spacer", modifiers: { width: 4 } },
        { type: "text", content: "8 mph", modifiers: { color: "#A5F3FC" } }
      ]
    }
  ]
};
renderWidget(JSON.stringify(widget));
''';

  static const String _kCryptoScript = '''
const widget = {
  type: "container",
  modifiers: { background: "#111827", cornerRadius: 20, padding: { runtimeType: "all", value: 16 } },
  children: [
    { type: "text", content: "MARKET", modifiers: { color: "#6B7280", fontSize: 12, fontWeight: "bold" } },
    { type: "spacer", modifiers: { height: 12 } },
    {
      type: "row",
      modifiers: { alignment: "spaceBetween" },
      children: [
        { type: "row", children: [
            { type: "icon", content: "bitcoinsign.circle.fill", modifiers: { color: "#F7931A", fontSize: 24 } },
            { type: "spacer", modifiers: { width: 8 } },
            { type: "text", content: "BTC", modifiers: { color: "white", fontSize: 18, fontWeight: "bold" } }
        ]},
        { type: "text", content: "\$42,500", modifiers: { color: "#10B981", fontSize: 18 } }
      ]
    },
    { type: "spacer", modifiers: { height: 12 } },
    {
      type: "row",
      modifiers: { alignment: "spaceBetween" },
      children: [
        { type: "row", children: [
            { type: "icon", content: "bolt.circle.fill", modifiers: { color: "#627EEA", fontSize: 24 } },
            { type: "spacer", modifiers: { width: 8 } },
            { type: "text", content: "ETH", modifiers: { color: "white", fontSize: 18, fontWeight: "bold" } }
        ]},
        { type: "text", content: "\$2,250", modifiers: { color: "#EF4444", fontSize: 18 } }
      ]
    }
  ]
};
renderWidget(JSON.stringify(widget));
''';

  static const String _kSystemScript = '''
const now = new Date();
const widget = {
  type: "container",
  modifiers: { background: "#1E1E2E", cornerRadius: 20, padding: { runtimeType: "all", value: 16 } },
  children: [
    { type: "text", content: "SYSTEM", modifiers: { color: "#6C7086", fontSize: 11, fontWeight: "bold" } },
    { type: "spacer", modifiers: { height: 12 } },
    { type: "text", content: now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }), modifiers: { color: "#CDD6F4", fontSize: 36, fontWeight: "bold" } },
    { type: "text", content: now.toLocaleDateString([], { weekday: "long", month: "short", day: "numeric" }), modifiers: { color: "#A6ADC8", fontSize: 14 } }
  ]
};
renderWidget(JSON.stringify(widget));
''';
}
