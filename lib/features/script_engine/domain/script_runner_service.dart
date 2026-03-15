// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:isolate';

import 'dart:io';
import '../data/engines/quickjs_engine.dart';
import '../data/engines/jsc_engine.dart';
import 'js_engine.dart';

import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import '../../widget_renderer/domain/services/headless_widget_rendering_service.dart';
import '../../script_management/data/services/virtual_file_system_service.dart';

import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

/// Service responsible for managing the background Isolate and the JS Engine lifecycle.
class ScriptRunnerService {
  Isolate? _engineIsolate;
  SendPort? _toEnginePort;

  // Stream for results/logs from the engine
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  // Stream for widget rendering requests (Live Preview)
  final StreamController<String> _renderController =
      StreamController<String>.broadcast();

  /// Stream of logs and results from the JS Engine.
  Stream<String> get logs => _logController.stream;

  /// Stream of SASUP JSON strings for live preview.
  Stream<String> get renderRequests => _renderController.stream;

  Completer<void>? _initCompleter;

  /// Initializes the service by spawning a background isolate.
  Future<void> initialize() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    final receivePort = ReceivePort();
    _engineIsolate = await Isolate.spawn(_isolateEntryPoint, (
      receivePort.sendPort,
      RootIsolateToken.instance!,
    ), debugName: 'JSEngineIsolate');
    _isDisposed = false;
    _setupSupervision();

    // Listen for messages from the isolate (handshake + logs + render requests)
    receivePort.listen(_handleIsolateMessage);

    return _initCompleter!.future;
  }

  bool _isDisposed = false;

  void _setupSupervision() {
    final exitPort = ReceivePort();
    _engineIsolate?.addOnExitListener(exitPort.sendPort);

    exitPort.listen((message) async {
      if (_isDisposed) return; // Expected exit

      const msg = "CRITICAL: JS Engine Isolate crashed unexpectedly!";
      print(msg);

      // Log to file
      try {
        final docs = await getApplicationDocumentsDirectory();
        final logFile = File('${docs.path}/vfs_root/logs/crash.log');
        if (!await logFile.exists()) {
          await logFile.create(recursive: true);
        }
        await logFile.writeAsString(
          "[${DateTime.now()}] $msg\n",
          mode: FileMode.append,
        );
      } catch (e) {
        print("Failed to write crash log: $e");
      }

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

  /// The maximum execution time for a single script evaluation.
  static const _evalTimeout = Duration(seconds: 30);

  /// Sends a script to the background isolate for evaluation.
  ///
  /// If the script does not complete within [_evalTimeout], the isolate
  /// is killed and the supervisor will automatically restart it.
  Future<void> runScript(String script, String scriptId) async {
    if (_engineIsolate == null) await initialize();

    await _initCompleter!.future;
    if (_toEnginePort == null) throw Exception("Service not initialized");

    // Create a per-script completion tracker for timeout detection
    final evalCompleter = Completer<void>();

    // Listen for the eval result or timeout
    late StreamSubscription<String> sub;
    sub = _logController.stream.listen((log) {
      if (log.contains('Result:') || log.contains('Script Error:')) {
        if (!evalCompleter.isCompleted) evalCompleter.complete();
        sub.cancel();
      }
    });

    _toEnginePort!.send({
      'command': 'eval',
      'script': script,
      'scriptId': scriptId,
    });

    try {
      await evalCompleter.future.timeout(_evalTimeout);
    } on TimeoutException {
      _logController.add(
        '[Error] Script evaluation timed out after ${_evalTimeout.inSeconds}s. Restarting engine...',
      );
      // Kill the hung isolate — supervisor will auto-restart
      _engineIsolate?.kill(priority: Isolate.immediate);
      _engineIsolate = null;
      _toEnginePort = null;
      _initCompleter = null;
    } finally {
      sub.cancel();
    }
  }

  /// Entry point for the background isolate.
  static void _isolateEntryPoint((SendPort, RootIsolateToken) args) {
    final mainSendPort = args.$1;
    final rootToken = args.$2;

    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);

    print("Isolate Entry Point Started");

    // 1. Setup Logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final msg = "[${record.level.name}] ${record.message}";
      print("Isolate Log: $msg");
      mainSendPort.send(msg);
    });
    final logger = Logger('JSEngineIsolate');

    // 2. Handshake (Moved to after init to prevent race condition)
    final receivePort = ReceivePort();
    // mainSendPort.send(receivePort.sendPort); // REMOVED from here

    // 3. Initialize Integration Services
    // Note: VFS is safe in Isolate (dart:io), but Headless is NOT (dart:ui).
    final vfsInitFuture = VirtualFileSystemService.create(); // Phase 2

    // 4. Setup Engine
    JSEngine engine;
    if (Platform.isIOS) {
      engine = JSCEngine();
    } else {
      engine = QuickJSEngine();
    }

    // Context for current execution
    String? currentScriptId;

    // 5. Initialize Sequence
    Future<void> initializeAll() async {
      try {
        final vfs = await vfsInitFuture;
        await vfs.initSharedDirectory(); // Pre-cache for Sync operations
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
          logger.info("JS requested renderWidget (Proxying to Main)");
          if (currentScriptId == null) {
            logger.warning(
              "renderWidget called without active scriptId context",
            );
            return "error_no_context";
          }
          mainSendPort.send({
            'type': 'sys_render',
            'payload': jsonString,
            'scriptId': currentScriptId,
          });
          return "queued_for_render";
        });

        // Binding 3: setTimeout Polyfill
        // Note: This is an isolate-local sync delay simulator if used with 0 or small values,
        // but for full async we use a Timer in Dart.
        engine.registerGlobalFunction('setTimeout', (args) {
          try {
            // Args come in as JSON string or array from bridge
            // QuickJSEngine bridge simplifies this to a single arg often
            // Simplified: we'll check if the JS can pass [callbackRef, ms]
            // For now, let's provide a basic 'wait' binding and polyfill setTimeout in JS
            return "setTimeout_registered";
          } catch (e) {
            return "error";
          }
        });

        // --- JS POLYFILLS ---
        // Injecting basic compatibility layer
        engine.evaluate('''
          var setTimeout = function(cb, ms) {
            // Native bridge doesn't support async callbacks yet, 
            // but we can simulate sync wait for small delays
            // OR we skip the delay and run immediately to prevent crashes.
            cb(); 
            return 0;
          };
        ''');

        // Binding 3: File System
        engine.registerGlobalFunction('writeFile', (args) {
          try {
            if (args is List && args.length >= 2) {
              final path = args[0] as String;
              final content = args[1] as String;
              logger.info("Writing file: $path");
              vfs.writeStringSync(path, content);
              logger.info("WriteFile Success via VFS: $path");
              return "success";
            }
          } catch (e) {
            logger.severe("WriteFile Error: $e");
            return "error_io";
          }
        });

        // --- HANDSHAKE: Initialization Complete ---
        // We only send the port when we are actually ready to receive commands.
        mainSendPort.send(receivePort.sendPort);
        print("Isolate Handshake Sent - Engine Ready");
      } catch (e) {
        print("Fatal Error initializing: $e");
        logger.severe("Fatal Error initializing: $e");
      }
    }

    // Run Init
    initializeAll();

    // 6. Message Loop
    receivePort.listen((message) async {
      // ... existing eval logic ...
      if (message is Map) {
        final command = message['command'];
        logger.info("Isolate received command: $command");

        if (command == 'eval') {
          final script = message['script'];
          logger.info("Evaluator received script (Length: ${script?.length})");
          // Optional: Log start of script to identify it
          if (script != null && script.length > 50) {
            logger.info("Script Start: ${script.substring(0, 50)}...");
          } else {
            logger.info("Script Content: $script");
          }

          currentScriptId = message['scriptId']; // Capture context
          try {
            // Wrap script in an IIFE so `const/let` declarations don't pollute the global scope 
            // and cause duplicate variable errors on subsequent runs.
            final wrappedScript = '''
              (function() {
                $script
              })();
            ''';
            final result = engine.evaluate(wrappedScript);
            logger.info("Result: $result");
          } catch (e) {
            String errorMsg = "Script Error: $e";
            if (e is Map) {
              errorMsg += " (Map content: ${e.toString()})";
            }
            logger.warning(errorMsg);
            // If it's an empty object {}, it might be an unhandled Promise rejection or non-Error throw
            if (e.toString() == '{}') {
              logger.warning(
                "Empty JS Error detected. This usually means a non-Error object was thrown or a Promise rejected with undefined.",
              );
            }
          } finally {
            currentScriptId = null; // Clear context
          }
        }
      }
    });
  } // End Isolate Entry Point

  // --- Main Isolate Handler ---
  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _toEnginePort = message;
      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    } else if (message is String) {
      _logController.add(message);
    } else if (message is Map && message['type'] == 'sys_render') {
      // Handle Render Request from Isolate
      _handleRenderRequest(message['payload'], message['scriptId']);
    }
  }

  /// Handles render requests from the JS engine isolate.
  ///
  /// Uses **Native JSON Passthrough**: saves the raw SASUP JSON directly to
  /// shared storage so iOS SwiftUI and Android Glance render native components
  /// (text, gradients, icons) instead of a static PNG bitmap.
  Future<void> _handleRenderRequest(String jsonString, String? scriptId) async {
    try {
      print("Main Isolate: Received Render Request for $scriptId");
      _renderController.add(jsonString); // Broadcast for Live Preview

      if (scriptId == null) throw Exception("Missing scriptId for render");

      final headlessService = GetIt.I<HeadlessWidgetRenderingService>();

      // Use Native JSON Passthrough (preferred) instead of PNG rasterization
      final path = await headlessService.renderNativeJson(jsonString, scriptId);
      _logController.add("[System] Rendered Widget (Native JSON) to: $path");

      // Trigger Widget Reload via MethodChannel
      try {
        const channel = MethodChannel(
          'com.antigravity.script_automator/widget',
        );
        await channel.invokeMethod('reloadTimelines');
        _logController.add("[System] Requested Widget Timeline Reload");
      } catch (e) {
        print("Failed to reload widget timelines: $e");
      }
    } catch (e) {
      print("Main Isolate Render Error: $e");
      _logController.add("[Error] Render Failed: $e");
    }
  }

  /// Disposes the service and kills the background isolate.
  void dispose() {
    _isDisposed = true;
    _engineIsolate?.kill();
    _engineIsolate = null;
    _isDisposed = true; // Duplicate assignment harmless, just ensuring.

    if (!_logController.isClosed) {
      _logController.close();
    }
  }
}
