import 'dart:ffi';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:ffi/ffi.dart';
import '../../domain/js_engine.dart';
import '../../native_bridge/ffi_jsc_bindings.dart';
import '../../domain/host_object_registry.dart';
import '../../domain/js_engine_exception.dart';

/// JavaScriptCore on iOS. There is no equivalent to QuickJS
/// [JS_SetInterruptHandler]; a tight `while(true){}` can block
/// [evaluate] until the outer Dart timeout [Isolate.kill]s the engine isolate.
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
  Future<String?> checkSyntax(String script) async {
    final escaped = jsonEncode(script);
    final wrapper =
        '''
      (function() {
        try {
          new Function($escaped);
          return null;
        } catch (e) {
          return e.toString();
        }
      })()
    ''';
    try {
      final result = evaluate(wrapper);
      return result as String?;
    } catch (e) {
      return "Engine Error: $e";
    }
  }

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
      
      // Check if it's explicitly an Error object
      final isObject = _lib.JSValueIsObject(_ctx!, value);
      if (isObject == 1) {
        exceptionPtr.value = nullptr;
        // Try getting 'message' property
        final msgPropStr = 'message'.toNativeUtf8(allocator: arena).cast<Char>();
        final jsMsgProp = _lib.JSStringCreateWithUTF8CString(msgPropStr);
        final hasMsg = _lib.JSObjectHasProperty(_ctx!, value.cast(), jsMsgProp);
        
        if (hasMsg == 1) {
             final msgVal = _lib.JSObjectGetProperty(_ctx!, value.cast(), jsMsgProp, exceptionPtr);
             _lib.JSStringRelease(jsMsgProp);
             if (exceptionPtr.value == nullptr) {
                final jsString = _lib.JSValueToStringCopy(_ctx!, msgVal, exceptionPtr);
                if (jsString != nullptr) {
                    final maxBytes = _lib.JSStringGetMaximumUTF8CStringSize(jsString);
                    final buffer = arena<Char>(maxBytes);
                    _lib.JSStringGetUTF8CString(jsString, buffer, maxBytes);
                    final dartString = buffer.cast<Utf8>().toDartString();
                    _lib.JSStringRelease(jsString);
                    return dartString;
                }
             }
        } else {
             _lib.JSStringRelease(jsMsgProp);
        }

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

          // Only JSONDecode if we meant to parse it out, but for toString() just return it.
          // Wait, returning JSON is useful for objects. But we shouldn't fail if it's {}.
          if (jsonStr != "{}") {
             try {
               // If it's pure json, decoding and printing might not be what JS string does
               return jsonStr; 
             } catch (e) {
               return jsonStr;
             }
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
        dynamic result;
        if (arg0 != null) {
          result = callback(arg0);
        } else {
          result = callback();
        }

        if (result is String) {
          return using((Arena arena) {
            final jsStr = _lib.JSStringCreateWithUTF8CString(result.toNativeUtf8(allocator: arena).cast());
            final jsVal = _lib.JSValueMakeString(ctx, jsStr);
            _lib.JSStringRelease(jsStr);
            return jsVal;
          });
        }
        if (result is num) return _lib.JSValueMakeNumber(ctx, result.toDouble());
        if (result is bool) return _lib.JSValueMakeBoolean(ctx, result ? 1 : 0);
        if (result == null) return _lib.JSValueMakeUndefined(ctx);

        final str = result.toString();
        return using((Arena arena) {
          final jsStr = _lib.JSStringCreateWithUTF8CString(str.toNativeUtf8(allocator: arena).cast());
          final jsVal = _lib.JSValueMakeString(ctx, jsStr);
          _lib.JSStringRelease(jsStr);
          return jsVal;
        });
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

  // JSHandle createHandle removed as it relied on missing native symbols.
  // If needed in future, implement manual JSValueProtect/Unprotect.

  /// Destroys the engine context and releases all native resources.
  ///
  /// Detaches the [NativeFinalizer] first to prevent a double-free if the
  /// Dart GC collects this object after manual destruction.
  @override
  void destroy() {
    for (var cb in _keptAliveCallbacks) {
      cb.close();
    }
    _keptAliveCallbacks.clear();

    HostObjectRegistry().clear();

    if (_ctx != null && _ctx != nullptr) {
      _finalizer.detach(this);
      _lib.JSGlobalContextRelease(_ctx!);
      _ctx = nullptr;
    }
  }
}

// JSHandle Removed
