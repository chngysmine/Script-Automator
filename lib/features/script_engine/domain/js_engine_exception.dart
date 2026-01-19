/// Exception thrown when a JavaScript Engine operation fails.
class JSEngineException implements Exception {
  final String message;
  final String? stackTrace;

  JSEngineException(this.message, [this.stackTrace]);

  @override
  String toString() => 'JSEngineException: $message';
}
