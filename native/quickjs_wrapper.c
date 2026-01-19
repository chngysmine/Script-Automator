#include "quickjs/quickjs.h"
#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "ScriptEngine"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#else
#include <stdio.h>
#define LOGD(...) printf(__VA_ARGS__)
#endif

#include <stdlib.h>
#include <string.h>

// Wrapper for inline functions that FFI cannot generate bindings for directly.

JSValue JS_NewInt32_Wrapper(JSContext *ctx, int32_t val) {
  return JS_NewInt32(ctx, val);
}

JSValue JS_NewFloat64_Wrapper(JSContext *ctx, double val) {
  return JS_NewFloat64(ctx, val);
}

JSValue JS_NewBool_Wrapper(JSContext *ctx, int32_t val) {
  return JS_NewBool(ctx, val);
}

JSValue JS_GetGlobalObject_Wrapper(JSContext *ctx) {
  return JS_GetGlobalObject(ctx);
}

JSValue JS_JSONStringify_Wrapper(JSContext *ctx, JSValue val) {
  return JS_JSONStringify(ctx, val, JS_UNDEFINED, JS_UNDEFINED);
}

const char *JS_ToCString_Wrapper(JSContext *ctx, JSValue val) {
  return JS_ToCString(ctx, val);
}

void JS_FreeValue_Wrapper(JSContext *ctx, JSValue v) { JS_FreeValue(ctx, v); }

// Wrapper for JS_NewCFunction (which is often a macro mapping to
// JS_NewCFunction2)
JSValue JS_NewCFunction_Wrapper(JSContext *ctx, JSCFunction *func,
                                const char *name, int length) {
  return JS_NewCFunction(ctx, func, name, length);
}

// Wrapper for JS_SetPropertyStr
int JS_SetPropertyStr_Wrapper(JSContext *ctx, JSValue this_obj,
                              const char *prop, JSValue val) {
  return JS_SetPropertyStr(ctx, this_obj, prop, val);
}

// Memory wrapper for NativeFinalizer
// NativeFinalizer expects void (*)(void*)
// We might need a struct to hold ctx and value if we want to free specific
// values associated with a context, but usually JSValue in QuickJS is by value
// (struct). Wait, JSValue is a struct (by value) but contains a ref count
// pointer if it's an object. JS_FreeValue requires 'ctx'. This is tricky for
// NativeFinalizer because NativeFinalizer only passes the 'token' (pointer). We
// might need to maintain a global context or pass a struct containing {ctx,
// val}.

typedef struct {
  JSContext *ctx;
  JSValue val;
} JSValueRef;

void FinalizeJSValue(void *ptr) {
  JSValueRef *ref = (JSValueRef *)ptr;
  if (ref) {
    JS_FreeValue(ref->ctx, ref->val);
    free(ref);
  }
}

JSValueRef *CreateJSValueRef(JSContext *ctx, JSValue val) {
  JSValueRef *ref = (JSValueRef *)malloc(sizeof(JSValueRef));
  ref->ctx = ctx;
  ref->val = val;
  // Note: We assume ownership is transferred or caller did JS_DupValue if
  // needed. Standard pattern: If coming from JS_Eval, we own it. If coming from
  // somewhere else, duplicate.
  return ref;
}
