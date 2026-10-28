/// A single turn in an AI conversation.
class AiTurn {
  const AiTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Error surfaced to the UI with a user-friendly message.
class AiException implements Exception {
  const AiException(this.message, {this.isQuota = false});

  final String message;

  /// True when the failure is a rate limit / quota exhaustion.
  final bool isQuota;

  @override
  String toString() => message;
}

/// Minimal text-generation contract so services can be tested without
/// network access.
abstract interface class AiTextClient {
  Future<String?> generate({
    required String model,
    required String systemInstruction,
    required List<AiTurn> turns,
    double temperature,
    int maxOutputTokens,
    bool lowLatency,
  });
}
