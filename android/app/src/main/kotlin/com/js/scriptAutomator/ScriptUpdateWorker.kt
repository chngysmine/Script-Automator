package com.js.scriptAutomator

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ScriptUpdateWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result = withContext(Dispatchers.Main) {
        // Switch to Main thread as FlutterEngine must be created on Main Looper
        
        // 1. Good Citizen Policy (Battery & Network Constraints)
        if (runAttemptCount > 3) {
            return@withContext Result.failure()
        }

        try {
            // 2. Initialize Flutter Engine (if needed)
            // We need to access the FlutterLoader to find the app bundle path
            val flutterLoader = io.flutter.embedding.engine.loader.FlutterLoader()
            flutterLoader.startInitialization(applicationContext)
            flutterLoader.ensureInitializationComplete(applicationContext, null)
            
            // 3. Create Engine
            val engine = io.flutter.embedding.engine.FlutterEngine(applicationContext)
            
            // 4. Define Entry Point
            // Must match @pragma('vm:entry-point') name in Dart
            val entryPoint = io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint(
                flutterLoader.findAppBundlePath(),
                "scriptRunnerMain"
            )
            
            // 5. Setup MethodChannel to wait for completion
            val channel = io.flutter.plugin.common.MethodChannel(
                engine.dartExecutor.binaryMessenger,
                "com.js.scriptAutomator/background"
            )

            val completionDeferred = kotlinx.coroutines.CompletableDeferred<Boolean>()

            channel.setMethodCallHandler { call, result ->
                if (call.method == "scriptCompleted") {
                    completionDeferred.complete(true)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

            // 6. Execute Entry Point
            engine.dartExecutor.executeDartEntrypoint(entryPoint)
            
            // 7. Wait for Completion (with Timeout)
            // We give it 30 seconds max to run the script.
            try {
                withContext(Dispatchers.IO) {
                    kotlinx.coroutines.withTimeout(30000L) {
                        completionDeferred.await()
                    }
                }
            } catch (e: kotlinx.coroutines.TimeoutCancellationException) {
                // Timeout happened, we proceed to cleanup but mark mainly as success/retry?
                // If it times out, it might be stuck.
                e.printStackTrace()
            }

            // 8. Native UI Update & Cleanup
            ScriptAutomatorWidget().updateAll(applicationContext)
            
            // Critical: Clean up the engine to free RAM.
            // Since we waited, it's safe now.
            engine.destroy()

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}
