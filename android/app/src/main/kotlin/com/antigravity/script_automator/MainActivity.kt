package com.antigravity.script_automator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity/paths"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNativeFilesDir") {
                result.success(context.filesDir.absolutePath)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.antigravity.script_automator/widget").setMethodCallHandler { call, result ->
            if (call.method == "reloadTimelines") {
                // Trigger Widget Update
                try {
                    kotlinx.coroutines.MainScope().launch {
                       ScriptAutomatorWidget().updateAll(context)
                       result.success(true)
                    }
                } catch (e: Exception) {
                    result.error("UPDATE_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Start Background Watchdog for periodic widget updates
        WatchdogScheduler.schedule(context)
    }
}
