import 'package:http/http.dart' as http;

/// Imports scripts from a raw URL ("Import from URL" in the Gallery).
///
/// Full Git clone/pull is planned for Phase 5 and intentionally not exposed.
class GitService {
  // Private field with a public named parameter, so no initializing formal.
  // ignore: prefer_initializing_formals
  GitService({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const Duration _timeout = Duration(seconds: 20);

  Future<String> downloadScript(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      throw const FormatException('Please enter a valid http(s) URL.');
    }
    try {
      final response = await (_client?.get(uri) ?? http.get(uri)).timeout(_timeout);
      if (response.statusCode == 200) return response.body;
      throw Exception('Failed to download script: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error downloading script: $e');
    }
  }
}
