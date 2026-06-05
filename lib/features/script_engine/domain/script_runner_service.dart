// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'dart:io';
import '../data/engines/quickjs_engine.dart';
import '../data/engines/jsc_engine.dart';
import 'js_engine.dart';

import 'package:logging/logging.dart';
import 'package:script_automator/features/script_engine/domain/system_api_polyfills.dart';
import 'package:flutter/services.dart';
import '../../widget_renderer/domain/services/headless_widget_rendering_service.dart';
import '../../script_management/data/services/virtual_file_system_service.dart';
import '../../dashboard/domain/services/notification_service.dart';
import '../../dashboard/data/services/user_stats_service.dart';

import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

import 'package:script_automator/features/script_engine/domain/system_api_handler.dart';
import 'package:script_automator/features/script_engine/native_bridge/script_engine_interrupt_ffi.dart';
import 'package:script_automator/core/services/telemetry_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  SystemAPIHandler? _apiHandler;

  /// Caches moderation check results for offline fail-closed fallback.
  /// Key: scriptId, Value: true if blocked, false if allowed.
  final Map<String, bool> _moderationCache = {};

  /// Stream of logs and results from the JS Engine.
  Stream<String> get logs => _logController.stream;

  /// Stream of SASUP JSON strings for live preview.
  Stream<String> get renderRequests => _renderController.stream;

  Completer<void>? _initCompleter;

  /// Completes when the engine isolate acknowledges native [JSEngine.destroy].
  Completer<void>? _engineShutdownCompleter;

  VirtualFileSystemService? _cachedVfs;

  static const _shutdownAckTimeout = Duration(seconds: 2);

  /// Initializes the service by spawning a background isolate.
  Future<void> initialize() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _apiHandler ??= SystemAPIHandler(); // Init handler on main isolate
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
      _engineShutdownCompleter = null;

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
  /// If the script does not complete within [_evalTimeout], native QuickJS
  /// interrupt is raised (Android), then a cooperative shutdown runs before
  /// any isolate [kill]. On iOS (JSC), interrupt is unavailable — see
  /// [signalQuickJsInterruptFromProcess].
  Future<void> runScript(String script, String scriptId) async {
    // Phase 4: Runtime Moderation Interceptor — FAIL-CLOSED with cache
    try {
      final moderationDoc = await FirebaseFirestore.instance
          .collection('script_moderation')
          .doc(scriptId)
          .get()
          .timeout(const Duration(seconds: 3));
      final isBlocked = moderationDoc.exists && moderationDoc.data()?['is_blocked'] == true;
      _moderationCache[scriptId] = isBlocked;
      if (isBlocked) {
        debugPrint("[SECURITY] Execution blocked: $scriptId is suppressed by Admin.");
        return;
      }
    } catch (e) {
      // Fail-closed: check cache, block if unknown
      final cachedStatus = _moderationCache[scriptId];
      if (cachedStatus == null) {
        debugPrint("[SECURITY] Moderation check failed & no cache — blocking $scriptId");
        return;
      }
      if (cachedStatus) {
        debugPrint("[SECURITY] Execution blocked (cached): $scriptId");
        return;
      }
      debugPrint("[SECURITY] Moderation check failed — using cached ALLOW for $scriptId");
    }

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
      if (GetIt.I.isRegistered<TelemetryService>()) {
        GetIt.I<TelemetryService>().captureEngineCrash(
          "Timeout/Infinite Loop in JS Engine", null,
        );
      }
      _logController.add(
        '[Error] Script evaluation timed out after ${_evalTimeout.inSeconds}s. Restarting engine...',
      );
      // Unblock QuickJS when stuck in JS_Eval (Dart ReceivePort cannot run until FFI returns).
      signalQuickJsInterruptFromProcess();
      await Future.delayed(const Duration(milliseconds: 400));
      // Cooperative shutdown: wait for native destroy() to finish before kill.
      _engineShutdownCompleter = Completer<void>();
      _toEnginePort?.send({'command': 'shutdown'});
      try {
        await _engineShutdownCompleter!.future.timeout(_shutdownAckTimeout);
      } on TimeoutException {
        _logController.add(
          '[Warning] Engine shutdown ack timed out; forcing isolate termination.',
        );
      }
      _engineShutdownCompleter = null;
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

        // Inject System API Polyfills before any scripts run
        engine.evaluate(SystemAPIPolyfills.allPolyfills);

        // --- BINDINGS ---
        // Binding 1: Console Namespace (__native_console)
        engine.registerGlobalFunction('__native_console', (argsJson) {
          final str = argsJson as String;
          final pipeIndex = str.indexOf('|');
          if (pipeIndex == -1) {
            logger.info("[JS stdout] $str");
            return "logged";
          }
          final level = str.substring(0, pipeIndex);
          final message = str.substring(pipeIndex + 1);
          
          switch (level) {
            case 'error':
              logger.severe("[JS stderr] $message");
            case 'warn':
              logger.warning("[JS warn] $message");
            case 'debug':
              logger.fine("[JS debug] $message");
            default:
              logger.info("[JS stdout] $message");
          }
          return "logged";
        });

        // Retain classic print purely as fallback/legacy alias
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
          String family = 'medium';
          try {
            family = engine.evaluate('Widget.getFamily()').toString();
          } catch (e) {
            // fallback gracefully
          }
          mainSendPort.send({
            'type': 'sys_render',
            'payload': jsonString,
            'family': family,
            'scriptId': currentScriptId,
          });
          return "queued_for_render";
        });

        // Binding 3: setTimeout / setInterval Polyfill (Improved)
        // Provides timer queue with IDs and deferred callback execution.
        // True async timers would require an FFI bridge round-trip which is
        // not feasible inside the single-threaded QuickJS sandbox. Instead:
        //   - ms <= 0: fire immediately (sync fast-path, zero overhead)
        //   - ms > 0: defer to end of script via a post-eval callback queue
        //   - setInterval: implemented as repeated setTimeout
        //   - clearTimeout/clearInterval: removes from pending queue
        engine.registerGlobalFunction('__flushTimers', (args) {
          // No-op on Dart side — timers are flushed in JS after eval
          return 'flushed';
        });

        // --- JS POLYFILLS ---
        // Injecting improved compatibility layer with timer queue
        engine.evaluate('''
          var __timerQueue = [];
          var __timerId = 0;

          var setTimeout = function(cb, ms) {
            var id = ++__timerId;
            if (!ms || ms <= 0) {
              // Fast path: execute immediately
              try { cb(); } catch(e) { console.log("[Timer Error] " + e); }
              return id;
            }
            // Queue for deferred execution after main script completes
            __timerQueue.push({ id: id, cb: cb, ms: ms, type: "timeout" });
            return id;
          };

          var setInterval = function(cb, ms) {
            var id = ++__timerId;
            var iterations = 0;
            var maxIterations = 100;
            var wrapped = function() {
              if (iterations++ < maxIterations) {
                try { cb(); } catch(e) { console.log("[Interval Error] " + e); }
                __timerQueue.push({ id: id, cb: wrapped, ms: ms, type: "interval" });
              }
            };
            __timerQueue.push({ id: id, cb: wrapped, ms: ms || 0, type: "interval" });
            return id;
          };

          var clearTimeout = function(id) {
            __timerQueue = __timerQueue.filter(function(t) { return t.id !== id; });
          };

          var clearInterval = clearTimeout;

          // Flush pending timers (called after main script evaluation)
          var __flushPendingTimers = function() {
            // Sort by ms ascending so shorter delays fire first
            __timerQueue.sort(function(a, b) { return a.ms - b.ms; });
            var queue = __timerQueue.slice();
            __timerQueue = [];
            for (var i = 0; i < queue.length; i++) {
              try { queue[i].cb(); } catch(e) { console.log("[Timer Error] " + e); }
            }
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
          return "error_invalid_args";
        });

        // Binding 4: Read File (Sync via VFS)
        engine.registerGlobalFunction('readFile', (argsJson) {
          try {
            final path = argsJson as String;
            logger.info("Reading file: $path");
            final content = vfs.readStringSync(path);
            return content;
          } catch (e) {
            logger.severe("ReadFile Error: $e");
            return "error_io"; // Usually FileSystemException if not exists or SecurityException
          }
        });

        // Binding 5: Async Fetch Bridge (JS will await the callback)
        engine.registerGlobalFunction('__native_fetch_start', (argsJson) {
           final requestStr = argsJson as String;
           final reqData = jsonDecode(requestStr);
           final reqId = reqData['__reqId'];
           mainSendPort.send({
             'type': 'sys_fetch', 'requestId': reqId, 'payload': requestStr, 'scriptId': currentScriptId,
           });
           return "pending";
        });

        // Binding 6: Async Device Info Bridge
        engine.registerGlobalFunction('__native_device_info_start', (argsJson) {
           final requestStr = argsJson as String;
           final reqData = jsonDecode(requestStr);
           final reqId = reqData['__reqId'];
           final property = reqData['property'];
           mainSendPort.send({
             'type': 'sys_device', 'requestId': reqId, 'property': property, 'scriptId': currentScriptId,
           });
           return "pending";
        });

        // Binding 7: Async Keychain Bridge
        engine.registerGlobalFunction('__native_keychain_start', (argsJson) {
           final requestStr = argsJson as String;
           final reqData = jsonDecode(requestStr);
           final reqId = reqData['__reqId'];
           mainSendPort.send({
             'type': 'sys_keychain', 'requestId': reqId, 'payload': requestStr, 'scriptId': currentScriptId,
           });
           return "pending";
        });

        // Binding 8: Async Notification Bridge
        engine.registerGlobalFunction('__native_notification_start', (argsJson) {
           final requestStr = argsJson as String;
           final reqData = jsonDecode(requestStr);
           final reqId = reqData['__reqId'];
           mainSendPort.send({
             'type': 'sys_notification', 'requestId': reqId, 'payload': requestStr, 'scriptId': currentScriptId,
           });
           return "pending";
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
            // Flush deferred setTimeout/setInterval callbacks
            engine.evaluate('if (typeof __flushPendingTimers === "function") __flushPendingTimers();');
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
        } else if (command == 'response') {
          // Handle asynchronous response from main isolate
          final requestId = message['requestId'];
          final responseString = message['response'] as String;
          logger.info("Injecting async response for reqId: $requestId");

          // Safely escape the JSON string for evaluation in JS
          final escapedJson = jsonEncode(responseString);
          
          try {
            engine.evaluate('__resolve_async_task($requestId, $escapedJson);');
          } catch (e) {
            logger.severe("Error resolving async promise: $e");
          }
        } else if (command == 'widget_action') {
          final scriptId = message['scriptId']?.toString();
          final actionId = message['actionId']?.toString();
          if (scriptId != null && actionId != null) {
            try {
              final callback = engine.evaluate("(function(){ return (Widget._actionHandlers && Widget._actionHandlers['$actionId']) || null; })();");
              if (callback != null && callback.toString() != 'null' && callback.toString() != 'undefined') {
                engine.evaluate("(function(){ var cb = Widget._actionHandlers['$actionId']; if (typeof cb === 'function') { cb(); } })();");
              }
            } catch (e) {
              logger.severe('Error handling widget action: $e');
            }
          }
        } else if (command == 'shutdown') {
          logger.info("Shutdown command received — destroying engine");
          try {
            engine.destroy();
          } finally {
            mainSendPort.send({'type': 'shutdown_ack'});
          }
        }
      }
    });
  } // End Isolate Entry Point

  // --- Main Isolate Handler ---
  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _toEnginePort = message;
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter?.complete();
      }
    } else if (message is String) {
      // Normal logs
      _logController.add(message);
      
      if (message.startsWith('[INFO] Result:')) {
        _pushNotification(
          NotificationType.scriptRun,
          'Script Completed',
          message.replaceFirst('[INFO] Result:', '').trim(),
        );
        if (GetIt.I.isRegistered<UserStatsService>()) {
          GetIt.I<UserStatsService>().recordRun(success: true);
        }
      } else if (message.startsWith('[Line ')) {
        // QuickJS errors typically start with "[Line "
        _pushNotification(
          NotificationType.system,
          'Script Error',
          message,
        );
      } else if (message.startsWith('[SEVERE]')) {
        _pushNotification(
          NotificationType.system,
          'Exception Caught',
          message.replaceFirst('[SEVERE]', '').trim(),
        );
        if (GetIt.I.isRegistered<UserStatsService>()) {
          GetIt.I<UserStatsService>().recordRun(success: false);
        }
      }
    } else if (message is Map) {
      final type = message['type'];
      if (type == 'shutdown_ack') {
        final c = _engineShutdownCompleter;
        if (c != null && !c.isCompleted) {
          c.complete();
        }
        return;
      }
      print("Main Isolate received sys_message: $type");
      if (type == 'sys_render') {
        _handleRenderRequest(message['payload'], message['family'], message['scriptId']);
      } else if (type == 'sys_fetch') {
        _handleFetchRequest(message);
      } else if (type == 'sys_device') {
        _handleDeviceRequest(message);
      } else if (type == 'sys_keychain') {
        _handleKeychainRequest(message);
      } else if (type == 'sys_notification') {
        _handleNotificationRequest(message);
      }
    }
  }

  void _handleFetchRequest(Map<dynamic, dynamic> message) async {
    final requestId = message['requestId'];
    final payload = message['payload'];
    final scriptId = message['scriptId'];
    
    if (_apiHandler != null) {
        final String result = await _apiHandler!.handleFetch(payload.toString());
        _toEnginePort?.send({
            'command': 'response', 'requestId': requestId, 'response': result, 'scriptId': scriptId,
        });
    }
  }

  void _handleDeviceRequest(Map<dynamic, dynamic> message) async {
    final requestId = message['requestId'];
    final property = message['property'];
    final scriptId = message['scriptId'];
    
    if (_apiHandler != null) {
        final String result = await _apiHandler!.handleDeviceInfo(property.toString());
        _toEnginePort?.send({
            'command': 'response', 'requestId': requestId, 'response': result, 'scriptId': scriptId,
        });
    }
  }

  void _handleKeychainRequest(Map<dynamic, dynamic> message) async {
    final requestId = message['requestId'];
    final payload = message['payload'];
    final scriptId = message['scriptId'];
    
    if (_apiHandler != null) {
        _apiHandler!.activeScriptId = scriptId;
        final String result = await _apiHandler!.handleKeychain(payload.toString());
        _toEnginePort?.send({
            'command': 'response', 'requestId': requestId, 'response': result, 'scriptId': scriptId,
        });
    }
  }

  void _handleNotificationRequest(Map<dynamic, dynamic> message) async {
    final requestId = message['requestId'];
    final payload = message['payload'];
    final scriptId = message['scriptId'];
    
    if (_apiHandler != null) {
        final String result = await _apiHandler!.handleNotification(payload.toString());
        _toEnginePort?.send({
            'command': 'response', 'requestId': requestId, 'response': result, 'scriptId': scriptId,
        });
    }
  }

  /// Handles render requests from the JS engine isolate.
  ///
  /// Uses **Native JSON Passthrough**: saves the raw SASUP JSON directly to
  /// shared storage so iOS SwiftUI and Android Glance render native components
  /// (text, gradients, icons) instead of a static PNG bitmap.
  Future<void> _handleRenderRequest(String jsonString, String? family, String? scriptId) async {
    try {
      print("Main Isolate: Received Render Request for $scriptId, family: $family");
      _renderController.add(jsonString); // Broadcast for Live Preview

      if (scriptId == null) throw Exception("Missing scriptId for render");

      final headlessService = GetIt.I<HeadlessWidgetRenderingService>();

      // Use Native JSON Passthrough (preferred) instead of PNG rasterization
      final path = await headlessService.renderNativeJson(jsonString, scriptId, family ?? 'medium');
      _logController.add("[System] Rendered Widget (Native JSON) to: $path");
      
      _pushNotification(
        NotificationType.widgetDeploy,
        'Widget Deployed',
        'Widget "$scriptId" rendered to Home Screen.',
      );
      
      if (GetIt.I.isRegistered<UserStatsService>()) {
        GetIt.I<UserStatsService>().recordWidgetDeploy();
      }

      await _pollPendingActions();

      // Trigger Widget Reload via MethodChannel
      try {
        const channel = MethodChannel(
          'com.js.scriptAutomator/widget',
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

  Future<void> _pollPendingActions() async {
    try {
      _cachedVfs ??= await VirtualFileSystemService.create();
      final vfs = _cachedVfs!;
      const pendingPath = 'shared/pending_action.json';
      if (!await vfs.exists(pendingPath)) return;
      final raw = await vfs.readString(pendingPath);
      await vfs.delete(pendingPath);
      final data = jsonDecode(raw);
      if (data is! Map) return;
      final scriptId = data['scriptId']?.toString();
      final actionId = data['actionId']?.toString();
      if (scriptId == null || actionId == null) return;
      _toEnginePort?.send({
        'command': 'widget_action',
        'scriptId': scriptId,
        'actionId': actionId,
      });
    } catch (e) {
      debugPrint('[WidgetAction] Pending action poll failed: $e');
    }
  }

  /// Disposes the service, gracefully shuts down the engine, and kills the isolate.
  void dispose() {
    _isDisposed = true;
    _cachedVfs = null;
    _apiHandler?.dispose();
    _engineShutdownCompleter = Completer<void>();
    _toEnginePort?.send({'command': 'shutdown'});
    unawaited(_disposeAfterShutdownAck());
  }

  Future<void> _disposeAfterShutdownAck() async {
    try {
      await _engineShutdownCompleter?.future.timeout(_shutdownAckTimeout);
    } on TimeoutException {
      // proceed to kill
    }
    _engineShutdownCompleter = null;
    _engineIsolate?.kill(priority: Isolate.immediate);
    _engineIsolate = null;
    _toEnginePort = null;

    if (!_logController.isClosed) {
      _logController.close();
    }
    if (!_renderController.isClosed) {
      _renderController.close();
    }
  }

  void _pushNotification(NotificationType type, String title, String body) {
    try {
      if (GetIt.I.isRegistered<NotificationService>()) {
        GetIt.I<NotificationService>().addNotification(
          type: type,
          title: title,
          body: body,
        );
      }
    } catch (_) {
      // Fail silently if GetIt isn't ready
    }
  }
}
