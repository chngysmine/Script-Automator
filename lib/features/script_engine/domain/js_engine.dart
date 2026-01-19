
abstract class JSEngine {
  /// Initialize the runtime environment
  void initialize();

  /// Evaluate a script and return the result.
  /// [script] The JavaScript code to execute.
  /// [filename] Optional filename for stack traces.
  dynamic evaluate(String script, {String? filename});

  /// Register a global function callable from JS.
  /// [name] The name of the function in JS global scope.
  /// [callback] The Dart function to be called.
  void registerGlobalFunction(String name, Function callback);

  /// Destroy the runtime and free resources.
  void destroy();
}
