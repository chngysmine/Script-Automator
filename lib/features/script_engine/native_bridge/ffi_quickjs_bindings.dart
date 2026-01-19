// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';

// Manual bindings for minimal QuickJS API.

final class JSRuntime extends Opaque {}

final class JSContext extends Opaque {}

/// Dart Native Struct representing JSValue.
base class JSValue extends Struct {
  @Int64()
  external int u;

  @Int64()
  external int tag;
}

// --- C Typedefs ---

typedef JS_NewRuntime_C = Pointer<JSRuntime> Function();
typedef JS_NewRuntime_Dart = Pointer<JSRuntime> Function();

typedef JS_FreeRuntime_C = Void Function(Pointer<JSRuntime>);
typedef JS_FreeRuntime_Dart = void Function(Pointer<JSRuntime>);

typedef JS_NewContext_C = Pointer<JSContext> Function(Pointer<JSRuntime>);
typedef JS_NewContext_Dart = Pointer<JSContext> Function(Pointer<JSRuntime>);

typedef JS_FreeContext_C = Void Function(Pointer<JSContext>);
typedef JS_FreeContext_Dart = void Function(Pointer<JSContext>);

typedef JS_Eval_C =
    JSValue Function(
      Pointer<JSContext>,
      Pointer<Char>,
      IntPtr,
      Pointer<Char>,
      Int32,
    );
typedef JS_Eval_Dart =
    JSValue Function(
      Pointer<JSContext>,
      Pointer<Char>,
      int,
      Pointer<Char>,
      int,
    );

// Wrappers

typedef JS_NewInt32_Wrapper_C = JSValue Function(Pointer<JSContext>, Int32);
typedef JS_NewInt32_Wrapper_Dart = JSValue Function(Pointer<JSContext>, int);

typedef JS_ToCString_Wrapper_C =
    Pointer<Char> Function(Pointer<JSContext>, JSValue);
typedef JS_ToCString_Wrapper_Dart =
    Pointer<Char> Function(Pointer<JSContext>, JSValue);

typedef JS_FreeValue_Wrapper_C = Void Function(Pointer<JSContext>, JSValue);
typedef JS_FreeValue_Wrapper_Dart = void Function(Pointer<JSContext>, JSValue);

typedef JSCFunction_C =
    JSValue Function(Pointer<JSContext>, JSValue, Int32, Pointer<JSValue>);
typedef JSCFunction_Dart =
    JSValue Function(Pointer<JSContext>, JSValue, int, Pointer<JSValue>);

typedef JS_NewCFunction_C =
    JSValue Function(
      Pointer<JSContext>,
      Pointer<NativeFunction<JSCFunction_C>>,
      Pointer<Char>,
      Int32,
    );
typedef JS_NewCFunction_Dart =
    JSValue Function(
      Pointer<JSContext>,
      Pointer<NativeFunction<JSCFunction_C>>,
      Pointer<Char>,
      int,
    );

typedef JS_GetGlobalObject_Wrapper_C = JSValue Function(Pointer<JSContext>);
typedef JS_GetGlobalObject_Wrapper_Dart = JSValue Function(Pointer<JSContext>);

typedef JS_SetPropertyStr_C =
    Int32 Function(Pointer<JSContext>, JSValue, Pointer<Char>, JSValue);
typedef JS_SetPropertyStr_Dart =
    int Function(Pointer<JSContext>, JSValue, Pointer<Char>, JSValue);

typedef JS_NewArray_C = JSValue Function(Pointer<JSContext>);
typedef JS_NewArray_Dart = JSValue Function(Pointer<JSContext>);

typedef JS_NewObject_C = JSValue Function(Pointer<JSContext>);
typedef JS_NewObject_Dart = JSValue Function(Pointer<JSContext>);

typedef JS_IsArray_C = Int32 Function(Pointer<JSContext>, JSValue);
typedef JS_IsArray_Dart = int Function(Pointer<JSContext>, JSValue);

typedef JS_GetPropertyStr_C =
    JSValue Function(Pointer<JSContext>, JSValue, Pointer<Char>);
typedef JS_GetPropertyStr_Dart =
    JSValue Function(Pointer<JSContext>, JSValue, Pointer<Char>);

typedef JS_GetPropertyUint32_C =
    JSValue Function(Pointer<JSContext>, JSValue, Uint32);
typedef JS_GetPropertyUint32_Dart =
    JSValue Function(Pointer<JSContext>, JSValue, int);

typedef JS_SetPropertyUint32_C =
    Int32 Function(Pointer<JSContext>, JSValue, Uint32, JSValue);
typedef JS_SetPropertyUint32_Dart =
    int Function(Pointer<JSContext>, JSValue, int, JSValue);

typedef JS_NewFloat64_Wrapper_C = JSValue Function(Pointer<JSContext>, Double);
typedef JS_NewFloat64_Wrapper_Dart =
    JSValue Function(Pointer<JSContext>, double);

typedef JS_NewBool_Wrapper_C = JSValue Function(Pointer<JSContext>, Int32);
typedef JS_NewBool_Wrapper_Dart = JSValue Function(Pointer<JSContext>, int);

typedef JS_JSONStringify_Wrapper_C =
    JSValue Function(Pointer<JSContext>, JSValue);
typedef JS_JSONStringify_Wrapper_Dart =
    JSValue Function(Pointer<JSContext>, JSValue);

// Struct wrapper for NativeFinalizer
final class JSValueRef extends Opaque {}

typedef CreateJSValueRef_C =
    Pointer<JSValueRef> Function(Pointer<JSContext>, JSValue);
typedef CreateJSValueRef_Dart =
    Pointer<JSValueRef> Function(Pointer<JSContext>, JSValue);

/// FFI Bindings for the QuickJS Library.
class QuickJSBindings {
  final DynamicLibrary _dylib;

  late final JS_NewRuntime_Dart JS_NewRuntime;
  late final JS_FreeRuntime_Dart JS_FreeRuntime;
  late final JS_NewContext_Dart JS_NewContext;
  late final JS_FreeContext_Dart JS_FreeContext;
  late final JS_Eval_Dart JS_Eval;
  late final JS_NewInt32_Wrapper_Dart JS_NewInt32;
  late final JS_ToCString_Wrapper_Dart JS_ToCString;
  late final JS_FreeValue_Wrapper_Dart JS_FreeValue;
  late final JS_NewCFunction_Dart JS_NewCFunction;
  late final JS_GetGlobalObject_Wrapper_Dart JS_GetGlobalObject;
  late final JS_SetPropertyStr_Dart JS_SetPropertyStr;
  late final JS_NewArray_Dart JS_NewArray;
  late final JS_NewObject_Dart JS_NewObject;
  late final JS_IsArray_Dart JS_IsArray;
  late final JS_GetPropertyStr_Dart JS_GetPropertyStr;
  late final JS_GetPropertyUint32_Dart JS_GetPropertyUint32;
  late final JS_SetPropertyUint32_Dart JS_SetPropertyUint32;
  late final JS_NewFloat64_Wrapper_Dart JS_NewFloat64;
  late final JS_NewBool_Wrapper_Dart JS_NewBool;
  late final JS_JSONStringify_Wrapper_Dart JS_JSONStringify;
  late final CreateJSValueRef_Dart CreateJSValueRef;
  late final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
  addresses_FinalizeJSValue;

  QuickJSBindings(this._dylib) {
    JS_NewRuntime = _dylib.lookupFunction<JS_NewRuntime_C, JS_NewRuntime_Dart>(
      'JS_NewRuntime',
    );
    JS_FreeRuntime = _dylib
        .lookupFunction<JS_FreeRuntime_C, JS_FreeRuntime_Dart>(
          'JS_FreeRuntime',
        );
    JS_NewContext = _dylib.lookupFunction<JS_NewContext_C, JS_NewContext_Dart>(
      'JS_NewContext',
    );
    JS_FreeContext = _dylib
        .lookupFunction<JS_FreeContext_C, JS_FreeContext_Dart>(
          'JS_FreeContext',
        );
    JS_Eval = _dylib.lookupFunction<JS_Eval_C, JS_Eval_Dart>('JS_Eval');

    JS_NewInt32 = _dylib
        .lookupFunction<JS_NewInt32_Wrapper_C, JS_NewInt32_Wrapper_Dart>(
          'JS_NewInt32_Wrapper',
        );
    JS_ToCString = _dylib
        .lookupFunction<JS_ToCString_Wrapper_C, JS_ToCString_Wrapper_Dart>(
          'JS_ToCString_Wrapper',
        );
    JS_FreeValue = _dylib
        .lookupFunction<JS_FreeValue_Wrapper_C, JS_FreeValue_Wrapper_Dart>(
          'JS_FreeValue_Wrapper',
        );
    JS_GetGlobalObject = _dylib
        .lookupFunction<
          JS_GetGlobalObject_Wrapper_C,
          JS_GetGlobalObject_Wrapper_Dart
        >('JS_GetGlobalObject_Wrapper');

    JS_NewCFunction = _dylib
        .lookupFunction<JS_NewCFunction_C, JS_NewCFunction_Dart>(
          'JS_NewCFunction_Wrapper',
        );
    JS_SetPropertyStr = _dylib
        .lookupFunction<JS_SetPropertyStr_C, JS_SetPropertyStr_Dart>(
          'JS_SetPropertyStr',
        );
    JS_NewArray = _dylib.lookupFunction<JS_NewArray_C, JS_NewArray_Dart>(
      'JS_NewArray',
    );
    JS_NewObject = _dylib.lookupFunction<JS_NewObject_C, JS_NewObject_Dart>(
      'JS_NewObject',
    );
    JS_IsArray = _dylib.lookupFunction<JS_IsArray_C, JS_IsArray_Dart>(
      'JS_IsArray',
    );
    JS_GetPropertyStr = _dylib
        .lookupFunction<JS_GetPropertyStr_C, JS_GetPropertyStr_Dart>(
          'JS_GetPropertyStr',
        );
    JS_GetPropertyUint32 = _dylib
        .lookupFunction<JS_GetPropertyUint32_C, JS_GetPropertyUint32_Dart>(
          'JS_GetPropertyUint32',
        );
    JS_SetPropertyUint32 = _dylib
        .lookupFunction<JS_SetPropertyUint32_C, JS_SetPropertyUint32_Dart>(
          'JS_SetPropertyUint32',
        );
    JS_NewFloat64 = _dylib
        .lookupFunction<JS_NewFloat64_Wrapper_C, JS_NewFloat64_Wrapper_Dart>(
          'JS_NewFloat64_Wrapper',
        );
    JS_NewBool = _dylib
        .lookupFunction<JS_NewBool_Wrapper_C, JS_NewBool_Wrapper_Dart>(
          'JS_NewBool_Wrapper',
        );
    JS_JSONStringify = _dylib
        .lookupFunction<
          JS_JSONStringify_Wrapper_C,
          JS_JSONStringify_Wrapper_Dart
        >('JS_JSONStringify_Wrapper');
    CreateJSValueRef = _dylib
        .lookupFunction<CreateJSValueRef_C, CreateJSValueRef_Dart>(
          'CreateJSValueRef',
        );
    addresses_FinalizeJSValue = _dylib.lookup('FinalizeJSValue');
  }
}
