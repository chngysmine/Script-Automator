// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';

// JavaScriptCore FFI Bindings for iOS

final class JSContextGroup extends Opaque {}

final class JSGlobalContext
    extends Opaque {} // JSGlobalContextRef is Pointer<JSGlobalContext>

final class JSString extends Opaque {}

final class JSValue extends Opaque {}

final class JSObject extends Opaque {}

final class JSClass extends Opaque {}

// JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass);
typedef JSGlobalContextCreate_C =
    Pointer<JSGlobalContext> Function(Pointer<JSClass>);
typedef JSGlobalContextCreate_Dart =
    Pointer<JSGlobalContext> Function(Pointer<JSClass>);

// void JSGlobalContextRelease(JSGlobalContextRef ctx);
typedef JSGlobalContextRelease_C = Void Function(Pointer<JSGlobalContext>);
typedef JSGlobalContextRelease_Dart = void Function(Pointer<JSGlobalContext>);

// JSValueRef JSEvaluateScript(JSContextRef ctx, JSStringRef script, JSObjectRef thisObject, JSStringRef sourceURL, int startingLineNumber, JSValueRef* exception);
// JSContextRef is compatible with JSGlobalContextRef
typedef JSEvaluateScript_C =
    Pointer<JSValue> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSString>,
      Pointer<JSObject>,
      Pointer<JSString>,
      Int,
      Pointer<Pointer<JSValue>>,
    );
typedef JSEvaluateScript_Dart =
    Pointer<JSValue> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSString>,
      Pointer<JSObject>,
      Pointer<JSString>,
      int,
      Pointer<Pointer<JSValue>>,
    );

// JSStringRef JSStringCreateWithUTF8CString(const char* string);
typedef JSStringCreateWithUTF8CString_C =
    Pointer<JSString> Function(Pointer<Char>);
typedef JSStringCreateWithUTF8CString_Dart =
    Pointer<JSString> Function(Pointer<Char>);

// void JSStringRelease(JSStringRef string);
typedef JSStringRelease_C = Void Function(Pointer<JSString>);
typedef JSStringRelease_Dart = void Function(Pointer<JSString>);

// size_t JSStringGetMaximumUTF8CStringSize(JSStringRef string);
typedef JSStringGetMaximumUTF8CStringSize_C =
    IntPtr Function(Pointer<JSString>);
typedef JSStringGetMaximumUTF8CStringSize_Dart =
    int Function(Pointer<JSString>);

// size_t JSStringGetUTF8CString(JSStringRef string, char* buffer, size_t bufferSize);
typedef JSStringGetUTF8CString_C =
    IntPtr Function(Pointer<JSString>, Pointer<Char>, IntPtr);
typedef JSStringGetUTF8CString_Dart =
    int Function(Pointer<JSString>, Pointer<Char>, int);

// JSValueRef JSValueMakeUndefined(JSContextRef ctx);
typedef JSValueMakeUndefined_C =
    Pointer<JSValue> Function(Pointer<JSGlobalContext>);
typedef JSValueMakeUndefined_Dart =
    Pointer<JSValue> Function(Pointer<JSGlobalContext>);

// JSStringRef JSValueToStringCopy(JSContextRef ctx, JSValueRef value, JSValueRef* exception);
typedef JSValueToStringCopy_C =
    Pointer<JSString> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSValue>,
      Pointer<Pointer<JSValue>>,
    );
typedef JSValueToStringCopy_Dart =
    Pointer<JSString> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSValue>,
      Pointer<Pointer<JSValue>>,
    );

// JSObjectRef JSObjectMakeFunctionWithCallback(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction);
// typedef JSValueRef (*JSObjectCallAsFunctionCallback) (JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);
typedef JSObjectCallAsFunctionCallback_C =
    Pointer<JSValue> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSObject>,
      Pointer<JSObject>,
      IntPtr,
      Pointer<Pointer<JSValue>>,
      Pointer<Pointer<JSValue>>,
    );

typedef JSObjectMakeFunctionWithCallback_C =
    Pointer<JSObject> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSString>,
      Pointer<NativeFunction<JSObjectCallAsFunctionCallback_C>>,
    );
typedef JSObjectMakeFunctionWithCallback_Dart =
    Pointer<JSObject> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSString>,
      Pointer<NativeFunction<JSObjectCallAsFunctionCallback_C>>,
    );

// JSObjectRef JSContextGetGlobalObject(JSContextRef ctx);
typedef JSContextGetGlobalObject_C =
    Pointer<JSObject> Function(Pointer<JSGlobalContext>);
typedef JSContextGetGlobalObject_Dart =
    Pointer<JSObject> Function(Pointer<JSGlobalContext>);

// void JSObjectSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef* exception);
typedef JSObjectSetProperty_C =
    Void Function(
      Pointer<JSGlobalContext>,
      Pointer<JSObject>,
      Pointer<JSString>,
      Pointer<JSValue>,
      Uint32,
      Pointer<Pointer<JSValue>>,
    );
typedef JSObjectSetProperty_Dart =
    void Function(
      Pointer<JSGlobalContext>,
      Pointer<JSObject>,
      Pointer<JSString>,
      Pointer<JSValue>,
      int,
      Pointer<Pointer<JSValue>>,
    );

// bool JSValueIsObject(JSContextRef ctx, JSValueRef value);
typedef JSValueIsObject_C =
    Int8 Function(Pointer<JSGlobalContext>, Pointer<JSValue>);
typedef JSValueIsObject_Dart =
    int Function(Pointer<JSGlobalContext>, Pointer<JSValue>);

// JSStringRef JSValueCreateJSONString(JSContextRef ctx, JSValueRef value, unsigned indent, JSValueRef* exception);
typedef JSValueCreateJSONString_C =
    Pointer<JSString> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSValue>,
      Uint32,
      Pointer<Pointer<JSValue>>,
    );
typedef JSValueCreateJSONString_Dart =
    Pointer<JSString> Function(
      Pointer<JSGlobalContext>,
      Pointer<JSValue>,
      int,
      Pointer<Pointer<JSValue>>,
    );

class JSCBindings {
  final DynamicLibrary _dylib;

  late final JSGlobalContextCreate_Dart JSGlobalContextCreate;
  late final JSGlobalContextRelease_Dart JSGlobalContextRelease;
  late final JSEvaluateScript_Dart JSEvaluateScript;
  late final JSStringCreateWithUTF8CString_Dart JSStringCreateWithUTF8CString;
  late final JSStringRelease_Dart JSStringRelease;
  late final JSStringGetMaximumUTF8CStringSize_Dart
  JSStringGetMaximumUTF8CStringSize;
  late final JSStringGetUTF8CString_Dart JSStringGetUTF8CString;
  late final JSValueToStringCopy_Dart JSValueToStringCopy;
  late final JSObjectMakeFunctionWithCallback_Dart
  JSObjectMakeFunctionWithCallback;
  late final JSContextGetGlobalObject_Dart JSContextGetGlobalObject;
  late final JSObjectSetProperty_Dart JSObjectSetProperty;
  late final JSValueMakeUndefined_Dart JSValueMakeUndefined;
  late final JSValueIsObject_Dart JSValueIsObject;
  late final JSValueCreateJSONString_Dart JSValueCreateJSONString;
  late final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
  addresses_JSGlobalContextRelease;
  late final CreateJSCValueRef_Dart CreateJSCValueRef;
  late final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
  addresses_FinalizeJSCValue;

  JSCBindings(this._dylib) {
    JSGlobalContextCreate = _dylib
        .lookupFunction<JSGlobalContextCreate_C, JSGlobalContextCreate_Dart>(
          'JSGlobalContextCreate',
        );
    JSGlobalContextRelease = _dylib
        .lookupFunction<JSGlobalContextRelease_C, JSGlobalContextRelease_Dart>(
          'JSGlobalContextRelease',
        );
    JSEvaluateScript = _dylib
        .lookupFunction<JSEvaluateScript_C, JSEvaluateScript_Dart>(
          'JSEvaluateScript',
        );
    JSStringCreateWithUTF8CString = _dylib
        .lookupFunction<
          JSStringCreateWithUTF8CString_C,
          JSStringCreateWithUTF8CString_Dart
        >('JSStringCreateWithUTF8CString');
    JSStringRelease = _dylib
        .lookupFunction<JSStringRelease_C, JSStringRelease_Dart>(
          'JSStringRelease',
        );
    JSStringGetMaximumUTF8CStringSize = _dylib
        .lookupFunction<
          JSStringGetMaximumUTF8CStringSize_C,
          JSStringGetMaximumUTF8CStringSize_Dart
        >('JSStringGetMaximumUTF8CStringSize');
    JSStringGetUTF8CString = _dylib
        .lookupFunction<JSStringGetUTF8CString_C, JSStringGetUTF8CString_Dart>(
          'JSStringGetUTF8CString',
        );
    JSValueToStringCopy = _dylib
        .lookupFunction<JSValueToStringCopy_C, JSValueToStringCopy_Dart>(
          'JSValueToStringCopy',
        );

    JSObjectMakeFunctionWithCallback = _dylib
        .lookupFunction<
          JSObjectMakeFunctionWithCallback_C,
          JSObjectMakeFunctionWithCallback_Dart
        >('JSObjectMakeFunctionWithCallback');
    JSContextGetGlobalObject = _dylib
        .lookupFunction<
          JSContextGetGlobalObject_C,
          JSContextGetGlobalObject_Dart
        >('JSContextGetGlobalObject');
    JSObjectSetProperty = _dylib
        .lookupFunction<JSObjectSetProperty_C, JSObjectSetProperty_Dart>(
          'JSObjectSetProperty',
        );
    JSValueMakeUndefined = _dylib
        .lookupFunction<JSValueMakeUndefined_C, JSValueMakeUndefined_Dart>(
          'JSValueMakeUndefined',
        );
    JSValueIsObject = _dylib
        .lookupFunction<JSValueIsObject_C, JSValueIsObject_Dart>(
          'JSValueIsObject',
        );
    JSValueCreateJSONString = _dylib
        .lookupFunction<
          JSValueCreateJSONString_C,
          JSValueCreateJSONString_Dart
        >('JSValueCreateJSONString');

    addresses_JSGlobalContextRelease = _dylib.lookup('JSGlobalContextRelease');

    // Wrapper lookups (from Process)
    final process = DynamicLibrary.process();
    CreateJSCValueRef = process
        .lookupFunction<CreateJSCValueRef_C, CreateJSCValueRef_Dart>(
          'CreateJSCValueRef',
        );
    addresses_FinalizeJSCValue = process.lookup('FinalizeJSCValue');
  }
}

// Struct wrapper for NativeFinalizer
final class JSCValueRef extends Opaque {}

typedef CreateJSCValueRef_C =
    Pointer<JSCValueRef> Function(Pointer<JSGlobalContext>, Pointer<JSValue>);
typedef CreateJSCValueRef_Dart =
    Pointer<JSCValueRef> Function(Pointer<JSGlobalContext>, Pointer<JSValue>);
