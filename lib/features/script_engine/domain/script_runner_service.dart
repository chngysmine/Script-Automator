// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:isolate';

import 'dart:io';
import '../data/engines/quickjs_engine.dart';
import '../data/engines/jsc_engine.dart';
import 'js_engine.dart';
import 'js_engine_exception.dart';

import 'dart:convert'; // JsonDecode
import 'package:logging/logging.dart';
import '../../widget_renderer/domain/services/headless_widget_rendering_service.dart';
import '../../script_management/data/services/virtual_file_system_service.dart';
import '../../widget_renderer/domain/entities/widget_node.dart';

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
    _isDisposed = false;
    _setupSupervision();

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

  bool _isDisposed = false;

  void _setupSupervision() {
    final exitPort = ReceivePort();
    _engineIsolate?.addOnExitListener(exitPort.sendPort);

    exitPort.listen((message) {
      if (_isDisposed) return; // Expected exit

      print("CRITICAL: JS Engine Isolate crashed unexpectedly!");
      // Self-healing: Restart
      _engineIsolate = null;
      _toEnginePort = null;
      _initCompleter = null;

      print("Supervisor: Attempting to restart service...");
      initialize()
          .then((_) {
            print("Supervisor: Service successfully recovered.");
          })
          .catchError((e) {
            print("Supervisor: Failed to recover service: $e");
          });
    });
  }

  /// Sends a script to the background isolate for evaluation.
  Future<void> runScript(String script) async {
    if (_engineIsolate == null) await initialize();

    await _initCompleter!.future;
    if (_toEnginePort == null) throw Exception("Service not initialized");
    _toEnginePort!.send({'command': 'eval', 'script': script});
  }

  /// Entry point for the background isolate.
  static void _isolateEntryPoint(SendPort mainSendPort) {
    print("Isolate Entry Point Started");

    // 1. Setup Logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final msg = "[${record.level.name}] ${record.message}";
      print("Isolate Log: $msg");
      mainSendPort.send(msg);
    });
    final logger = Logger('JSEngineIsolate');

    // 2. Handshake
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    print("Isolate Handshake Sent");

    // 3. Initialize Integration Services
    // Note: In Isolate, we create fresh instances.
    final headlessService = HeadlessWidgetRenderingService(); // Phase 3
    final vfsInitFuture = VirtualFileSystemService.create(); // Phase 2

    // 4. Setup Engine
    JSEngine engine;
    if (Platform.isIOS) {
      engine = JSCEngine();
    } else {
      engine = QuickJSEngine();
    }

    // 5. Initialize Sequence
    Future<void> initializeAll() async {
      try {
        final vfs = await vfsInitFuture;
        print("VFS Initialized in Isolate: ${vfs.rootDirectory}");

        print("Initializing Engine...");
        engine.initialize();
        logger.info(
          "JSEngine Initialized in Isolate: ${Isolate.current.debugName}",
        );

        // --- BINDINGS ---

        // Binding 1: Print
        engine.registerGlobalFunction('print', (message) {
          logger.info("[JS stdout] $message");
        });

        // Binding 2: Render Widget (Headless)
        engine.registerGlobalFunction('renderWidget', (jsonString) {
          logger.info("JS requested renderWidget");
          try {
            // Decode JSON to Map
            final jsonMap = jsonDecode(jsonString);
            // Convert to WidgetNode
            final node = WidgetNode.fromJson(jsonMap);
            // Render and Save
            // We use a 'fire and forget' or blocking approach?
            // Since we can't await inside this sync callback easily without Promise support,
            // we will use a blocking call if possible, or trigger async and log.
            // HEADLESS SERVICE 'renderAndSave' is ASYNC.
            // We cannot await it here in a sync callback.
            // WORKAROUND: Trigger it unawaited, and log result.
            // Real solution requires AsyncBinding in Phase 4.

            headlessService
                .renderAndSave(node, 'sasup_ui.json')
                .then((path) {
                  logger.info("Render Success: $path");
                })
                .catchError((e) {
                  logger.severe("Render Failed: $e");
                });

            return "rendering_started";
          } catch (e) {
            logger.severe("Render Request Invalid: $e");
            return "error";
          }
        });

        // Binding 3: File System
        engine.registerGlobalFunction('writeFile', (args) {
          // Mock Implementation for now
          logger.info("Write File Request: $args");
        });
      } catch (e, stack) {
        print("Fatal Error initializing: $e\n$stack");
        logger.severe("Fatal Error initializing: $e");
      }
    }

    // Run Init
    initializeAll();

    // 6. Message Loop
    receivePort.listen((message) async {
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
    _isDisposed = true;
    _engineIsolate?.kill();
    _engineIsolate = null;
    _logController.close();
  }
}
