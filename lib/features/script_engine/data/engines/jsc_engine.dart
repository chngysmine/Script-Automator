import 'dart:ffi';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ffi/ffi.dart';
import '../../domain/js_engine.dart';
import '../../native_bridge/ffi_jsc_bindings.dart';
import '../../domain/host_object_registry.dart';
import '../../domain/js_engine_exception.dart';

class JSCEngine implements JSEngine, Finalizable {
  late JSCBindings _lib;
  Pointer<JSGlobalContext>? _ctx;
  late NativeFinalizer _finalizer;
  final List<NativeCallable> _keptAliveCallbacks = [];

  /// Initializes the JavaScriptCore engine by loading the system framework.
  ///
  /// Throws [JSEngineException] if the global context cannot be created.
  @override
  void initialize() {
    final dylib = DynamicLibrary.open(
      '/System/Library/Frameworks/JavaScriptCore.framework/JavaScriptCore',
    );
    _lib = JSCBindings(dylib);

    _ctx = _lib.JSGlobalContextCreate(nullptr);
    if (_ctx == nullptr) {
      throw JSEngineException('Failed to create JSC Global Context');
    }

    // Attach NativeFinalizer to the context.
    // This allows dart VM to clean up the JSC context if the Engine object is GC'd unexpectedly.
    _finalizer = NativeFinalizer(_lib.addresses_JSGlobalContextRelease);
    _finalizer.attach(this, _ctx!.cast(), detach: this);
  }

  /// Evaluates a JavaScript code string.
  ///
  /// [script] The JavaScript source code to evaluate.
  /// [filename] Optional filename for stack traces.
  ///
  /// Returns the result of the evaluation as a [String].
  /// Throws [JSEngineException] if the engine is not initialized or if the script contains errors.
  @override
  dynamic evaluate(String script, {String? filename}) {
    if (_ctx == null) throw JSEngineException('Engine not initialized');

    return using((Arena arena) {
      final scriptPtr = _lib.JSStringCreateWithUTF8CString(
        script.toNativeUtf8(allocator: arena).cast(),
      );
      final sourceUrlPtr = filename != null
          ? _lib.JSStringCreateWithUTF8CString(
              filename.toNativeUtf8(allocator: arena).cast(),
            )
          : nullptr;

      final exceptionPtr = arena<Pointer<JSValue>>();
      exceptionPtr.value = nullptr;

      final result = _lib.JSEvaluateScript(
        _ctx!,
        scriptPtr,
        nullptr,
        sourceUrlPtr,
        1,
        exceptionPtr,
      );

      _lib.JSStringRelease(scriptPtr);
      if (sourceUrlPtr != nullptr) _lib.JSStringRelease(sourceUrlPtr);

      if (exceptionPtr.value != nullptr) {
        final exceptionValue = exceptionPtr.value;
        final errorString = _jsValueToString(exceptionValue);
        throw JSEngineException(errorString);
      }

      return _jsValueToString(result);
    });
  }

  /// Converts a [JSValue] pointer to a Dart [String].
  String _jsValueToString(Pointer<JSValue> value) {
    if (_ctx == null) return "";
    return using((Arena arena) {
      final exceptionPtr = arena<Pointer<JSValue>>();
      // Simplified check: If it's an object (including Array), try JSON stringify.
      final isObject = _lib.JSValueIsObject(_ctx!, value);
      if (isObject == 1) {
        exceptionPtr.value = nullptr; // Clear for new call
        final jsonStringRef = _lib.JSValueCreateJSONString(
          _ctx!,
          value,
          0,
          exceptionPtr,
        );

        if (exceptionPtr.value != nullptr) {
          // Exception during stringify (e.g. circular reference).
        } else if (jsonStringRef != nullptr) {
          final maxLen = _lib.JSStringGetMaximumUTF8CStringSize(jsonStringRef);
          final buffer = arena<Char>(maxLen);
          _lib.JSStringGetUTF8CString(jsonStringRef, buffer, maxLen);
          final jsonStr = buffer.cast<Utf8>().toDartString();
          _lib.JSStringRelease(jsonStringRef);

          try {
            return jsonDecode(jsonStr);
          } catch (e) {
            return jsonStr;
          }
        }
      }

      final jsString = _lib.JSValueToStringCopy(_ctx!, value, exceptionPtr);
      if (jsString == nullptr) return "";

      final maxBytes = _lib.JSStringGetMaximumUTF8CStringSize(jsString);
      final buffer = arena<Char>(maxBytes);
      _lib.JSStringGetUTF8CString(jsString, buffer, maxBytes);

      final dartString = buffer.cast<Utf8>().toDartString();
      _lib.JSStringRelease(jsString);
      return dartString;
    });
  }

  /// Registers a synchronous host function that can be called from JavaScript.
  ///
  /// [name] The name of the function in the JavaScript global scope.
  /// [callback] The Dart function to execute. Currently only supports accepting a single String argument.
  @override
  void registerGlobalFunction(String name, Function callback) {
    if (_ctx == null) throw JSEngineException('Engine not initialized');

    Pointer<JSValue> nativeCallback(
      Pointer<JSGlobalContext> ctx,
      Pointer<JSObject> function,
      Pointer<JSObject> thisObject,
      int argumentCount,
      Pointer<Pointer<JSValue>> argumentsPtr,
      Pointer<Pointer<JSValue>> exception,
    ) {
      String? arg0;
      if (argumentCount > 0) {
        final argVal = argumentsPtr[0];
        arg0 = _jsValueToString(argVal);
      }

      try {
        if (arg0 != null) {
          callback(arg0);
        } else {
          callback();
        }
      } catch (e) {
        developer.log("Error in host function: $e", name: "JSCEngine");
      }

      return _lib.JSValueMakeUndefined(ctx);
    }

    final nativeCallable =
        NativeCallable<JSObjectCallAsFunctionCallback_C>.isolateLocal(
          nativeCallback,
        );
    _keptAliveCallbacks.add(nativeCallable);

    using((Arena arena) {
      final namePtr = _lib.JSStringCreateWithUTF8CString(
        name.toNativeUtf8(allocator: arena).cast(),
      );
      final jsFuncObj = _lib.JSObjectMakeFunctionWithCallback(
        _ctx!,
        namePtr,
        nativeCallable.nativeFunction,
      );

      final globalObj = _lib.JSContextGetGlobalObject(_ctx!);
      _lib.JSObjectSetProperty(
        _ctx!,
        globalObj,
        namePtr,
        jsFuncObj.cast<JSValue>(),
        0,
        nullptr,
      );

      _lib.JSStringRelease(namePtr);
    });
  }

  // --- Parity Features: Host Object Registry & Handle ---

  void registerHostObject(Object obj, String varName) {
    final id = HostObjectRegistry().register(obj);
    developer.log("Registered host object $obj with ID $id as $varName (JSC)");
  }

  // Use NativeFinalizer to protect JS Values until Dart GCs the Handle.
  JSHandle createHandle(Pointer<JSValue> val) {
    // 1. Create a stable Reference wrapper in C (calls JSValueProtect)
    final ref = _lib.CreateJSCValueRef(_ctx!, val);

    // 2. Create Dart Handle
    final handle = JSHandle(ref);

    // 3. Attach Finalizer: When 'handle' GC -> C calls FinalizeJSCValue -> JSValueUnprotect
    _finalizer.attach(handle, ref.cast(), detach: handle);

    return handle;
  }

  /// Destroys the engine context and releases resources.
  @override
  void destroy() {
    for (var cb in _keptAliveCallbacks) {
      cb.close();
    }
    _keptAliveCallbacks.clear();

    HostObjectRegistry().clear();

    if (_ctx != null && _ctx != nullptr) {
      _lib.JSGlobalContextRelease(_ctx!);
      _ctx = nullptr;
    }
  }
}

class JSHandle implements Finalizable {
  final Pointer<JSCValueRef> _ref;
  JSHandle(this._ref);

  Pointer<JSCValueRef> get ref => _ref;
}
