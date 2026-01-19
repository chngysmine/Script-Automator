import 'dart:ffi';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../domain/js_engine.dart';
import '../../native_bridge/ffi_quickjs_bindings.dart';
import '../../domain/host_object_registry.dart';
import '../../domain/js_engine_exception.dart';

class QuickJSEngine implements JSEngine {
  late QuickJSBindings _lib;
  Pointer<JSRuntime>? _rt;
  Pointer<JSContext>? _ctx;
  late NativeFinalizer _finalizer;

  // We need to keep NativeCallables alive so they don't get GC'd.
  final List<NativeCallable> _keptAliveCallbacks = [];

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libscript_engine.so');
    }
    // iOS/macOS now uses JSCEngine directly, so we don't try to load QuickJS there.
    throw UnsupportedError('QuickJS not supported on this platform');
  }

  /// Initializes the QuickJS engine by loading the native library.
  ///
  /// Throws [JSEngineException] if the runtime or context cannot be created.
  @override
  void initialize() {
    final dylib = _loadLibrary();
    _lib = QuickJSBindings(dylib);

    _rt = _lib.JS_NewRuntime();
    if (_rt == nullptr) {
      throw JSEngineException('Failed to create QuickJS Runtime');
    }
    _ctx = _lib.JS_NewContext(_rt!);
    if (_ctx == nullptr) {
      throw JSEngineException('Failed to create QuickJS Context');
    }

    // Initialize NativeFinalizer with the address of FinalizeJSValue from C
    _finalizer = NativeFinalizer(_lib.addresses_FinalizeJSValue);
  }

  /// Evaluates a JavaScript code string.
  ///
  /// [script] The JavaScript source code to evaluate.
  /// [filename] Optional filename for stack traces.
  ///
  /// Returns the result of the evaluation as a [String].
  /// Throws [JSEngineException] if the engine is not initialized.
  @override
  dynamic evaluate(String script, {String? filename}) {
    if (_ctx == null || _ctx == nullptr) {
      throw JSEngineException('Engine not initialized');
    }

    return using((Arena arena) {
      final scriptPtr = script.toNativeUtf8(allocator: arena).cast<Char>();
      final filenamePtr = (filename ?? 'input.js')
          .toNativeUtf8(allocator: arena)
          .cast<Char>();
      final byteLen = (scriptPtr as Pointer<Utf8>).length;

      final val = _lib.JS_Eval(_ctx!, scriptPtr, byteLen, filenamePtr, 0);

      try {
        return _jsValueToDart(val);
      } finally {
        _lib.JS_FreeValue(_ctx!, val);
      }
    });
  }

  dynamic _jsValueToDart(JSValue val) {
    if (_ctx == null) return null;
    final tag = val.tag;

    // Check for Arrays/Objects: Tag > 0 (Objects) but safer to check IsArray/IsObject logic or just use JSON for potential objects.
    // QuickJS Tags: JS_TAG_OBJECT = -1 (Wait, no).
    // Let's rely on checking if it is an object/array via C API or simply attempt JSON stringify for everything except primitives?
    // Primitives: Int, Bool, Null, Undefined are fast.
    if (tag == -7) {
      // String
      // ... existing string logic ...
      final strPtr = _lib.JS_ToCString(_ctx!, val);
      if (strPtr != nullptr) return strPtr.cast<Utf8>().toDartString();
      return "";
    }
    if (tag == -1) return val.u; // Int (JS_TAG_INT is -1)
    if (tag == 6) return val.u == 1; // Bool (JS_TAG_BOOL=6)
    // Actually, tags are defined in quickjs.h.
    // Better strategy: Use JSON.stringify for everything that is "Complex".
    // Or just simple:

    // Check if it's an Array or Function or Object
    final isArray = _lib.JS_IsArray(_ctx!, val);
    // Note: JS_IsArray returns 1 if array.
    // JS_TAG_OBJECT is typically -1, but JS_TAG_INT is also -1.
    // We need to use JS_IsObject to differentiate.
    // Simplification: logic to detect object/array.
    // If not primitive types above, try JSON stringify.
    if (isArray == 1 || tag == -1 /* JS_TAG_OBJECT */ ) {
      // Fallback to JSON Marshalling for robustness
      // JS_JSONStringify_Wrapper takes 2 args: ctx, val
      final jsonVal = _lib.JS_JSONStringify(_ctx!, val);
      final strPtr = _lib.JS_ToCString(_ctx!, jsonVal);
      String? jsonStr;
      if (strPtr != nullptr) {
        jsonStr = strPtr.cast<Utf8>().toDartString();
      }
      _lib.JS_FreeValue(_ctx!, jsonVal);

      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr);
        } catch (e) {
          return jsonStr;
        }
      }
    }

    // Fallback string conversion
    final strPtr = _lib.JS_ToCString(_ctx!, val);
    if (strPtr != nullptr) {
      final str = strPtr.cast<Utf8>().toDartString();
      return str;
    }
    return null;
  }

  /// Registers a synchronous host function that can be called from JavaScript.
  ///
  /// [name] The name of the function in the JavaScript global scope.
  /// [callback] The Dart function to execute. Currently only supports accepting a single String argument.
  @override
  void registerGlobalFunction(String name, Function callback) {
    if (_ctx == nullptr) throw JSEngineException('Engine not initialized');

    JSValue nativeCallback(
      Pointer<JSContext> ctx,
      JSValue thisVal,
      int argc,
      Pointer<JSValue> argv,
    ) {
      String? arg0;
      if (argc > 0) {
        final val = argv[0];
        final strPtr = _lib.JS_ToCString(ctx, val);
        if (strPtr != nullptr) {
          arg0 = strPtr.cast<Utf8>().toDartString();
        }
      }

      try {
        if (arg0 != null) {
          callback(arg0);
        } else {
          callback();
        }
      } catch (e) {
        developer.log("Error in host function: $e", name: 'QuickJSEngine');
      }

      return _lib.JS_NewInt32(ctx, 0);
    }

    final nativeCallable = NativeCallable<JSCFunction_C>.isolateLocal(
      nativeCallback,
    );
    _keptAliveCallbacks.add(nativeCallable);

    final funcName = name.toNativeUtf8();

    final jsFunc = _lib.JS_NewCFunction(
      _ctx!,
      nativeCallable.nativeFunction,
      funcName.cast(),
      1,
    );

    final globalObj = _lib.JS_GetGlobalObject(_ctx!);
    _lib.JS_SetPropertyStr(_ctx!, globalObj, funcName.cast(), jsFunc);

    _lib.JS_FreeValue(_ctx!, globalObj);
    calloc.free(funcName);
  }

  // Finalizer for the engine (Phase 1 Deep Integration)
  // Note: Since Engine is a Service often kept alive, this is a safety net.
  // We cannot easily attach Finalizer to 'this' for freeing _ctx/_rt because callback needs pointer.
  // But we can finalize specific handles if we wrap them.
  // For the Engine itself, we rely on 'destroy()'.

  // --- NativeFinalizer Usage ---
  // Returns a handle that keeps the JSValue alive until Dart GCs the handle.
  JSHandle createHandle(JSValue val) {
    final ref = _lib.CreateJSValueRef(_ctx!, val);
    final handle = JSHandle(ref);
    _finalizer.attach(handle, ref.cast(), detach: handle);
    return handle;
  }

  // --- Host Object Registry Integration ---
  void registerHostObject(Object obj, String varName) {
    final id = HostObjectRegistry().register(obj);
    developer.log("Registered host object $obj with ID $id as $varName");
  }

  /// Destroys the engine context and releases resources.
  @override
  void destroy() {
    for (var cb in _keptAliveCallbacks) {
      cb.close();
    }
    _keptAliveCallbacks.clear();

    // Clear registry if needed (or scoped to engine)
    HostObjectRegistry().clear();

    if (_ctx != nullptr) {
      _lib.JS_FreeContext(_ctx!);
      _ctx = nullptr;
    }
    if (_rt != nullptr) {
      _lib.JS_FreeRuntime(_rt!);
      _rt = nullptr;
    }
  }
}

/// A wrapper class for a JSValue that is automatically properly finalized.
class JSHandle implements Finalizable {
  final Pointer<JSValueRef> _ref;
  JSHandle(this._ref);

  Pointer<JSValueRef> get ref => _ref;
}
