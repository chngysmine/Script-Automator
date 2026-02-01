package com.antigravity.script_automator

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

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        // 1. Good Citizen Policy (Battery & Network Constraints)
        // If system is stressed or we failed too many times, back off.
        if (runAttemptCount > 3) {
            return@withContext Result.failure()
        }

        return@withContext try {
            // 2. Trigger Widget Update
            // Ideally, this calls the JS Engine via MethodChannel or FFI.
            // For Phase 3 Scope (Renderer), we ensure the Renderer refreshes its UI.
            
            // Note: In a real Headless scenario, we would need to wake up Flutter Engine here.
            // Since we are in the Native Worker, we can trigger the Glance Update directly 
            // which will re-read the JSON file (Passive View).
            ScriptAutomatorWidget().updateAll(applicationContext)

            Result.success()
        } catch (e: Exception) {
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}
