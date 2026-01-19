#include <JavaScriptCore/JavaScriptCore.h>
#include <stdlib.h>

// Struct wrapper for NativeFinalizer to hold Context and Value
typedef struct {
  JSGlobalContextRef ctx;
  JSValueRef val;
} JSCValueRef;

// The Finalizer callback
void FinalizeJSCValue(void *ptr) {
  JSCValueRef *ref = (JSCValueRef *)ptr;
  if (ref) {
    // Unprotect the value, decrementing its refcount in JSC
    JSValueUnprotect(ref->ctx, ref->val);
    free(ref);
  }
}

// Helper to Create the Ref and Protect it
JSCValueRef *CreateJSCValueRef(JSGlobalContextRef ctx, JSValueRef val) {
  JSCValueRef *ref = (JSCValueRef *)malloc(sizeof(JSCValueRef));
  ref->ctx = ctx;
  ref->val = val;

  // Protect the value, ensuring it isn't GC'd by JSC while Dart holds this
  // Handle
  JSValueProtect(ctx, val);

  return ref;
}
