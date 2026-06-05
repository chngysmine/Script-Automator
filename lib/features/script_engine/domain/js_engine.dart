abstract class JSEngine {
  /// Initialize the runtime environment
  void initialize();

  /// Evaluate a script and return the result.
  /// [script] The JavaScript code to execute.
  /// [filename] Optional filename for stack traces.
  dynamic evaluate(String script, {String? filename});

  /// Validates the syntax of a script without executing it.
  /// Returns null if valid, or an error message if invalid.
  Future<String?> checkSyntax(String script);

  /// Register a global function callable from JS.
  /// [name] The name of the function in JS global scope.
  /// [callback] The Dart function to be called.
  void registerGlobalFunction(String name, Function callback);

  /// Flush any pending microtasks/promises.
  void flushPendingJobs();

  /// Destroy the runtime and free resources.
  void destroy();
}
