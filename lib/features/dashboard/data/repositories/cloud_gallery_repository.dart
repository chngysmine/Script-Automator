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
        'name': 'Hello World',
        'description': 'A simple starter script to test the engine.',
        'content':
            'print("Hello from Script Automator!");\nconsole.log("Engine is working!");',
      },
      {
        'name': '⛅ Weather Widget',
        'description': 'A beautiful weather widget with gradients and icons.',
        'content': '''
// Weather Widget — Premium UI Template
const widget = {
  type: "container",
  modifiers: {
    background: "linear-gradient(135deg, #667eea, #764ba2)",
    cornerRadius: 20,
    padding: { runtimeType: "all", value: 16 }
  },
  children: [
    { type: "text", content: "San Francisco", modifiers: { font: "title", color: "#FFFFFF" } },
    { type: "spacer", modifiers: { height: 4 } },
    { type: "text", content: "72°F — Partly Cloudy", modifiers: { font: "body", color: "#E0E0FF" } },
    { type: "spacer", modifiers: { height: 12 } },
    {
      type: "row",
      children: [
        { type: "icon", content: "cloud.sun.fill", modifiers: { fontSize: 40, color: "#FFD700" } },
        { type: "spacer", modifiers: { width: 12 } },
        { type: "text", content: "H:78° L:65°", modifiers: { color: "#FFFFFF" } }
      ]
    }
  ]
};
renderWidget(JSON.stringify(widget));
''',
      },
      {
        'name': '📝 Todo List',
        'description': 'A task list widget with checkmarks.',
        'content': '''
const tasks = ["Buy groceries", "Review PR #42", "Call dentist"];
const children = tasks.map(t => ({
  type: "row",
  children: [
    { type: "icon", content: "checkmark.circle.fill", modifiers: { fontSize: 18, color: "#34C759" } },
    { type: "spacer", modifiers: { width: 8 } },
    { type: "text", content: t, modifiers: { color: "#FFFFFF" } }
  ]
}));
const widget = {
  type: "container",
  modifiers: { background: "#1C1C1E", cornerRadius: 16, padding: { runtimeType: "all", value: 12 } },
  children: [
    { type: "text", content: "Today's Tasks", modifiers: { font: "title", color: "#FFFFFF" } },
    { type: "spacer", modifiers: { height: 8 } },
    ...children
  ]
};
renderWidget(JSON.stringify(widget));
''',
      },
      {
        'name': '⏱️ Pomodoro Timer',
        'description': 'A focus timer display widget.',
        'content': '''
const widget = {
  type: "container",
  modifiers: {
    background: "linear-gradient(180deg, #FF6B6B, #EE5A24)",
    cornerRadius: 20,
    padding: { runtimeType: "all", value: 20 }
  },
  children: [
    { type: "text", content: "Focus Time", modifiers: { font: "caption", color: "#FFE0E0" } },
    { type: "spacer", modifiers: { height: 8 } },
    { type: "text", content: "25:00", modifiers: { font: "largeTitle", color: "#FFFFFF" } },
    { type: "spacer", modifiers: { height: 4 } },
    { type: "text", content: "Stay focused!", modifiers: { font: "body", color: "#FFE0E0" } }
  ]
};
renderWidget(JSON.stringify(widget));
''',
      },
      {
        'name': '📊 System Info',
        'description': 'Display device and runtime information.',
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
    ];
  }
}
