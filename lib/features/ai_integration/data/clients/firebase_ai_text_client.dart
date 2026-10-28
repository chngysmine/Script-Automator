import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'package:script_automator/core/services/firebase_bootstrap.dart';
import '../../domain/ai_text_client.dart';

/// [AiTextClient] backed by Firebase AI Logic (Gemini Developer API).
///
/// No API key ships in the app: requests are authorized by the Firebase
/// project and protected by App Check (picked up automatically from the
/// default Firebase app when `firebase_app_check` is activated).
class FirebaseAiTextClient implements AiTextClient {
  FirebaseAiTextClient({FirebaseAI? ai, this.timeout = const Duration(seconds: 45)})
      : _aiOverride = ai;

  final FirebaseAI? _aiOverride;
  final Duration timeout;

  FirebaseAI get _ai => _aiOverride ?? FirebaseAI.googleAI(app: FirebaseBootstrap.aiApp);

  @override
  Future<String?> generate({
    required String model,
    required String systemInstruction,
    required List<AiTurn> turns,
    double temperature = 0.4,
    int maxOutputTokens = 2048,
    bool lowLatency = false,
  }) async {
    final generativeModel = _ai.generativeModel(
      model: model,
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
        thinkingConfig: lowLatency
            ? ThinkingConfig.withThinkingLevel(ThinkingLevel.low)
            : null,
      ),
    );

    try {
      final response = await generativeModel
          .generateContent(toContents(turns))
          .timeout(timeout);
      return response.text;
    } on TimeoutException {
      throw const AiException('Gemini took too long to respond. Please try again.');
    } on QuotaExceeded {
      throw const AiException(
        'The free Gemini quota is used up for now. Please try again in a minute.',
        isQuota: true,
      );
    } on ServiceApiNotEnabled {
      throw const AiException('Gemini is not enabled for this app yet.');
    } on UnsupportedUserLocation {
      throw const AiException('Gemini is not available in your region.');
    } on FirebaseAIException catch (e) {
      debugPrint('[FirebaseAi] ${e.runtimeType}: ${e.message}');
      throw AiException('Gemini request failed: ${e.message}');
    }
  }

  /// Gemini requires the conversation to start with a user turn and to
  /// alternate roles, so leading model turns are dropped and consecutive
  /// same-role turns are merged.
  @visibleForTesting
  static List<Content> toContents(List<AiTurn> turns) {
    final merged = <AiTurn>[];
    for (final turn in turns) {
      if (turn.text.trim().isEmpty) continue;
      if (merged.isEmpty && !turn.isUser) continue;
      if (merged.isNotEmpty && merged.last.isUser == turn.isUser) {
        final last = merged.removeLast();
        merged.add(AiTurn(isUser: last.isUser, text: '${last.text}\n\n${turn.text}'));
      } else {
        merged.add(turn);
      }
    }
    return merged
        .map((t) => t.isUser
            ? Content.text(t.text)
            : Content.model([TextPart(t.text)]))
        .toList();
  }
}
