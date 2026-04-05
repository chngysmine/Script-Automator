import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:script_automator/core/security/app_secure_storage.dart';

class OllamaService {
  final FlutterSecureStorage _secureStorage;
  static const String _kBaseUrlKey = 'ollama_base_url';
  static const String _kModelKey = 'ollama_model';

  // Default to localhost emulator loopback or generic local IP
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost
  // Real Device: Need actual LAN IP (e.g., 192.168.1.X)
  String _baseUrl = "http://192.168.1.10:11434";
  String _model = "deepseek-coder:6.7b"; // Excellent coding model

  OllamaService(this._secureStorage);

  Future<void> initialize() async {
    final savedUrl = await AppSecureStorage.readMigratingLegacy(
      _secureStorage,
      _kBaseUrlKey,
    );
    final savedModel = await AppSecureStorage.readMigratingLegacy(
      _secureStorage,
      _kModelKey,
    );
    if (savedUrl != null) _baseUrl = savedUrl;
    if (savedModel != null) _model = savedModel;
  }

  Future<void> setConfig(String url, String model) async {
    _baseUrl = url;
    _model = model;
    await _secureStorage.write(key: _kBaseUrlKey, value: url);
    await _secureStorage.write(key: _kModelKey, value: model);
  }

  Future<String?> getConfiguredUrl() async =>
      await _secureStorage.read(key: _kBaseUrlKey);

  /// Completes code using Ollama Generate API
  Future<String?> completeCode(String codeContext) async {
    try {
      final uri = Uri.parse("$_baseUrl/api/generate");
      final prompt =
          "You are a JavaScript coding assistant. Complete the following code. DO NOT wrap in markdown. Just raw code.\n\n$codeContext";

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "model": _model,
          "prompt": prompt,
          "stream": false,
          "options": {
            "temperature": 0.2, // Low temp for code precision
            "stop": ["```"], // Stop if it tries to generate explanations
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String?;
      } else {
        debugPrint("Ollama Error: ${response.statusCode} - ${response.body}");
        return null; // // Error comment
      }
    } catch (e) {
      debugPrint("Ollama Connection Failed: $e");
      return null;
    }
  }
}
