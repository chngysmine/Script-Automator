// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart'; // Needed for WidgetsBinding
import 'package:flutter/services.dart'; // MethodChannel
import 'package:logging/logging.dart';
import 'features/script_engine/domain/script_runner_service.dart';

/// The Entry Point for Background Execution.
/// This is called by Android WorkManager / iOS BackgroundFetch when the app is terminated.
@pragma('vm:entry-point')
void scriptRunnerMain() async {
  // 1. Initialize Flutter Bindings (Required for Platform Channels & Headless Rendering)
  WidgetsFlutterBinding.ensureInitialized();
  // DartDispatcher usually handles this, but for raw engine spawn, we ensure it.

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print("[BG-Dart] ${record.level.name}: ${record.message}");
  });
  final logger = Logger('ScriptRunnerMain');

  logger.info("Background Execution Started");

  try {
    // 2. Initialize the Service
    final service = ScriptRunnerService();
    await service.initialize();

    // 3. Run the "Update" Script
    // In a real scenario, this script content would be fetched from Shared Prefs or DB.
    // For Phase 3 Verification, we run a script that generates a UI file.
    logger.info("Running Background Update Script...");

    // Sample Script: Render a Clock/Status Update
    const bgScript = """
      print('Background Script Running...');
      
      const ui = {
        "root": {
          "type": "column",
          "modifiers": { 
             "background": "#121212",
             "padding": { "all": 16 }
          },
          "children": [
             { 
               "type": "text", 
               "content": "Updated via Background",
               "modifiers": { "color": "#00FF00", "font": "title" } 
             }
          ]
        }
      };
      
      renderWidget(JSON.stringify(ui));
      print('Background Render Request Sent');
    """;

    await service.runScript(bgScript);

    // Allow some time for async render (QuickJS is sync, but service might be async)
    await Future.delayed(const Duration(seconds: 2));

    service.dispose();
    logger.info("Background Execution Completed Successfully");

    // 4. Signal Completion to Native
    const channel = MethodChannel(
      'com.antigravity.script_automator/background',
    );
    await channel.invokeMethod('scriptCompleted');
  } catch (e, stack) {
    logger.severe("Background Execution Failed: $e\n$stack");
  } finally {
    // Native will destroy engine after receiving 'scriptCompleted' or timeout.
  }
}
