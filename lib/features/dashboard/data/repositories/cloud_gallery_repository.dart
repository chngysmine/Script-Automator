import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';

/// Fetches community gallery scripts from the GitHub-hosted index.
///
/// Primary source: `index.json` from the `script-automator-community-gallery`
/// repository on GitHub. Falls back to a minimal built-in set if the network
/// request fails (offline mode).
///
/// The HTTP client is injected for testability and is properly closed on
/// [dispose].
class CloudGalleryRepository implements GalleryRepository {
  /// Raw GitHub URL for the community gallery index.
  static const String _kGalleryIndexUrl =
      'https://raw.githubusercontent.com/chngysmine/script-automator-community-gallery/main/index.json';

  final http.Client _client;

  CloudGalleryRepository({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<List<Map<String, String>>> getTemplates() async {
    try {
      final response = await _client
          .get(Uri.parse(_kGalleryIndexUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return _parseIndex(data);
      }
      debugPrint('Gallery fetch failed with status: ${response.statusCode}');
      return _getOfflineFallback();
    } catch (e) {
      debugPrint('Gallery fetch error: $e');
      return _getOfflineFallback();
    }
  }

  /// Parses the raw JSON index into the flat map format expected by the UI.
  List<Map<String, String>> _parseIndex(List<dynamic> data) {
    return data.map<Map<String, String>>((item) {
      return {
        'id': (item['id'] ?? '') as String,
        'name': (item['name'] ?? '') as String,
        'description': (item['description'] ?? '') as String,
        'author': (item['author'] ?? '') as String,
        'category': (item['category'] ?? 'Utilities') as String,
        'version': (item['version'] ?? '1.0.0') as String,
        'icon': (item['icon'] ?? 'gear') as String,
        'isFeatured': (item['isFeatured'] == true).toString(),
        'scriptUrl': (item['scriptUrl'] ?? '') as String,
      };
    }).toList();
  }

  /// Minimal offline fallback with a single example per category.
  ///
  /// This ensures the Explore page is never entirely empty even without
  /// network connectivity. Scripts are simple, self-contained, and valid.
  List<Map<String, String>> _getOfflineFallback() {
    return [
      {
        'id': 'weather_pro_v2',
        'name': 'Weather Pro',
        'description': 'Beautiful weather widget with live gradients.',
        'author': 'Antigravity',
        'category': 'Weather',
        'version': '2.0.1',
        'isFeatured': 'true',
        'content': _kWeatherScript, // Embedded fallback
        'scriptUrl': '',
      },
      {
        'id': 'crypto_portfolio_tracker',
        'name': 'Crypto Portfolio',
        'description': 'Bitcoin and Ethereum price tracker.',
        'author': 'CryptoDevs',
        'category': 'Finance',
        'version': '1.0.0',
        'isFeatured': 'false',
        'content': _kCryptoScript, // Embedded fallback
        'scriptUrl': '',
      },
      {
        'id': 'system_monitor',
        'name': 'System Monitor',
        'description': 'Display time, date, OS, and locale.',
        'author': 'Antigravity',
        'category': 'Utilities',
        'version': '1.5.0',
        'isFeatured': 'false',
        'content': _kSystemScript, // Embedded fallback
        'scriptUrl': '',
      },
    ];
  }

  /// Releases the underlying HTTP client.
  void dispose() {
    _client.close();
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
