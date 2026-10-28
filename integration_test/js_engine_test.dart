// Exercises the native JS engines on a real device/emulator (the host test
// VM can't load libscript_engine.so or JavaScriptCore):
//   flutter test integration_test/js_engine_test.dart -d <device>
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:script_automator/features/script_engine/data/engines/jsc_engine.dart';
import 'package:script_automator/features/script_engine/data/engines/quickjs_engine.dart';
import 'package:script_automator/features/script_engine/domain/js_engine.dart';
import 'package:script_automator/features/script_engine/domain/js_engine_exception.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Same selection as ScriptRunnerService.
  JSEngine createEngine() => Platform.isIOS ? JSCEngine() : QuickJSEngine();

  late JSEngine engine;

  setUp(() {
    engine = createEngine()..initialize();
  });

  tearDown(() => engine.destroy());

  testWidgets('evaluates expressions and JSON', (tester) async {
    expect(engine.evaluate('1 + 2').toString(), '3');
    final json = engine.evaluate('JSON.stringify({a: [1, 2], b: "x"})');
    expect(json, '{"a":[1,2],"b":"x"}');
  });

  testWidgets('checkSyntax accepts valid code and reports SyntaxError', (tester) async {
    expect(await engine.checkSyntax('const a = 1; function f() { return a; }'), isNull);
    final error = await engine.checkSyntax('function broken( {');
    expect(error, isNotNull);
    expect(error, contains('SyntaxError'));
  });

  testWidgets('runtime errors surface as JSEngineException', (tester) async {
    for (final source in ['undefinedVariable + 1', 'null.prop', 'throw new Error("boom")']) {
      expect(() => engine.evaluate(source), throwsA(isA<JSEngineException>()), reason: source);
    }
    // The engine stays usable after an exception.
    expect(engine.evaluate('40 + 2').toString(), '42');
  });

  testWidgets('global Dart callbacks are callable from JS', (tester) async {
    final received = <Object?>[];
    engine.registerGlobalFunction('dartLog', (Object? value) {
      received.add(value);
      return null;
    });
    engine.evaluate('dartLog("hello from js")');
    expect(received.map((e) => e.toString()), contains(contains('hello from js')));
  });
}
