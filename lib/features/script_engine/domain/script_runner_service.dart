// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:isolate';

import 'dart:io';
import '../data/engines/quickjs_engine.dart';
import '../data/engines/jsc_engine.dart';
import 'js_engine.dart';
import 'js_engine_exception.dart';

import 'package:logging/logging.dart';

/// Service responsible for managing the background Isolate and the JS Engine lifecycle.
class ScriptRunnerService {
  Isolate? _engineIsolate;
  SendPort? _toEnginePort;

  // Stream for results/logs from the engine
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  /// Stream of logs and results from the JS Engine.
  Stream<String> get logs => _logController.stream;

  Completer<void>? _initCompleter;

  /// Initializes the service by spawning a background isolate.
  Future<void> initialize() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    final receivePort = ReceivePort();
    _engineIsolate = await Isolate.spawn(
      _isolateEntryPoint,
      receivePort.sendPort,
      debugName: 'JSEngineIsolate',
    );

    // Listen for messages from the isolate (handshake + logs)
    receivePort.listen((message) {
      if (message is SendPort) {
        _toEnginePort = message;
        if (!_initCompleter!.isCompleted) _initCompleter!.complete();
      } else if (message is String) {
        _logController.add(message);
      }
    });

    return _initCompleter!.future;
  }

  /// Sends a script to the background isolate for evaluation.
  Future<void> runScript(String script) async {
    await _initCompleter!.future;
    if (_toEnginePort == null) throw Exception("Service not initialized");
    _toEnginePort!.send({'command': 'eval', 'script': script});
  }

  /// Entry point for the background isolate.
  static void _isolateEntryPoint(SendPort mainSendPort) {
    print("Isolate Entry Point Started");

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final msg = "[${record.level.name}] ${record.message}";
      print("Isolate Log: $msg");
      mainSendPort.send(msg);
    });
    final logger = Logger('JSEngineIsolate');

    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    print("Isolate Handshake Sent");

    JSEngine engine;
    if (Platform.isIOS) {
      engine = JSCEngine();
    } else {
      engine = QuickJSEngine();
    }

    try {
      print("Initializing Engine...");
      engine.initialize();
      logger.info(
        "JSEngine Initialized in Isolate: ${Isolate.current.debugName}",
      );
      print("Engine Initialize Success");

      engine.registerGlobalFunction('print', (message) {
        logger.info("[JS stdout] $message");
      });
    } catch (e, stack) {
      print("Fatal Error initializing engine: $e\n$stack");
      logger.severe("Fatal Error initializing engine: $e");
    }

    receivePort.listen((message) {
      print("Isolate received message: $message");
      if (message is Map) {
        final command = message['command'];
        if (command == 'eval') {
          final script = message['script'];
          try {
            print("Evaluating script: $script");
            final result = engine.evaluate(script);
            print("Evaluation Result: $result");
            logger.info("Result: $result");
          } on JSEngineException catch (e) {
            print("JS Engine Error: ${e.message}");
            logger.warning("JS Engine Error: ${e.message}");
            // Optionally send error back to main isolate if needed
          } catch (e) {
            print("Unknown Script Error: $e");
            logger.warning("Unknown Script Error: $e");
          }
        }
      }
    });
  }

  /// Disposes the service and kills the background isolate.
  void dispose() {
    _engineIsolate?.kill();
    _engineIsolate = null;
    _logController.close();
  }
}
