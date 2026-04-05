import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Raises QuickJS's cooperative interrupt flag ([ScriptEngine_RequestInterrupt]
/// in `quickjs_wrapper.c`). QuickJS polls this inside the bytecode loop, so it
/// still works when the engine isolate cannot process Dart [ReceivePort] messages
/// (e.g. stuck in `while(true){}` inside `JS_Eval`).
///
/// **Android only** (QuickJS). No-op on iOS/macOS/Web where the app uses JSC or
/// no native engine in this process.
void signalQuickJsInterruptFromProcess() {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    final lib = DynamicLibrary.open('libscript_engine.so');
    lib
        .lookupFunction<Void Function(), void Function()>(
          'ScriptEngine_RequestInterrupt',
        )();
  } catch (_) {
    // Tests / missing native library.
  }
}
