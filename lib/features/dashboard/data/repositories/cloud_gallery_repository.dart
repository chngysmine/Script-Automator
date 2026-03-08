import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';

class CloudGalleryRepository implements GalleryRepository {
  // Can be configured via settings, default to a community repo or official one
  // For now using a placeholder that points to a raw JSON on GitHub
  static const String _kDefaultGalleryUrl =
      'https://raw.githubusercontent.com/script-automator-community/gallery/main/index.json';

  final http.Client _client;

  CloudGalleryRepository({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<Map<String, String>>> getTemplates() async {
    try {
      final response = await _client.get(Uri.parse(_kDefaultGalleryUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map<Map<String, String>>(
              (item) => {
                'name': item['name'] as String,
                'description': item['description'] as String,
                'content':
                    item['content'] as String, // Full code or URL to fetch code
              },
            )
            .toList();
      } else {
        // Fallback to local if network fails or repo not found yet
        return _getLocalFallback();
      }
    } catch (e) {
      // Offline mode
      return _getLocalFallback();
    }
  }

  Future<List<Map<String, String>>> _getLocalFallback() async {
    return [
      {
        'id': 'weather_pro_v1',
        'name': 'Weather Pro',
        'description':
            'Premium weather widget with live gradients and animations.',
        'author': 'Antigravity Team',
        'category': 'Featured',
        'version': '1.0.2',
        'isFeatured': 'true',
        'content': '''
// Weather Widget — Premium UI Template
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
''',
      },
      {
        'id': 'crypto_tracker',
        'name': 'Crypto Tracker',
        'description': 'Live Bitcoin and Ethereum prices.',
        'author': 'Satoshi',
        'category': 'Finance',
        'version': '2.1.0',
        'isFeatured': 'true',
        'content': '''
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
''',
      },
      {
        'id': 'todo_list',
        'name': 'Minimalist Tasks',
        'description': 'Keep track of your daily goals.',
        'author': 'ProductivityInc',
        'category': 'Productivity',
        'version': '1.0.0',
        'isFeatured': 'false',
        'content': '''
const tasks = ["Review Code", "Team Meeting", "Deploy to Prod"];
const children = tasks.map(t => ({
  type: "row",
  children: [
    { type: "icon", content: "checkmark.circle.fill", modifiers: { fontSize: 20, color: "#10B981" } },
    { type: "spacer", modifiers: { width: 12 } },
    { type: "text", content: t, modifiers: { color: "#F3F4F6", fontSize: 16 } }
  ]
}));
const widget = {
  type: "container",
  modifiers: { background: "#1F2937", cornerRadius: 16, padding: { runtimeType: "all", value: 12 } },
  children: [
    { type: "text", content: "TASKS", modifiers: { color: "#9CA3AF", fontSize: 12, fontWeight: "bold" } },
    { type: "spacer", modifiers: { height: 8 } },
    ...children
  ]
};
renderWidget(JSON.stringify(widget));
''',
      },
      {
        'id': 'system_info',
        'name': 'Device Stats',
        'description': 'Monitor your system performance.',
        'author': 'System',
        'category': 'Utilities',
        'version': '1.5',
        'isFeatured': 'false',
        'content': '''
const now = new Date();
const widget = {
  type: "container",
  modifiers: { background: "#2C2C2E", cornerRadius: 16, padding: { runtimeType: "all", value: 14 } },
  children: [
    { type: "text", content: "System Info", modifiers: { font: "title", color: "#8E8E93" } },
    { type: "spacer", modifiers: { height: 8 } },
    { type: "text", content: "Time: " + now.toLocaleTimeString(), modifiers: { color: "#FFFFFF" } },
    { type: "text", content: "Date: " + now.toLocaleDateString(), modifiers: { color: "#FFFFFF" } },
    { type: "text", content: "Engine: QuickJS/JSC", modifiers: { color: "#8E8E93" } }
  ]
};
renderWidget(JSON.stringify(widget));
''',
      },
      {
        'id': 'pomodoro',
        'name': 'Pomodoro Timer',
        'description': 'Focus timer with clean UI.',
        'author': 'Antigravity Team',
        'category': 'Productivity',
        'version': '1.0',
        'isFeatured': 'false',
        'content': '// Pomodoro script...',
      },
    ];
  }
}
