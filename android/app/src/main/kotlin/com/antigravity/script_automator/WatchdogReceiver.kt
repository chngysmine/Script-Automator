/*
 * Background Watchdog Strategy for Script Automator (Android)
 *
 * Problem: WorkManager is reliable but can be deferred by Doze Mode or App Standby Buckets.
 * Solution: A "Watchdog" implementation using AlarmManager (setExactAndAllowWhileIdle).
 *
 * Components:
 * 1. WatchdogReceiver (BroadcastReceiver): Receives the alarm hint.
 * 2. WatchdogScheduler: Helper to schedule the next check.
 * 3. Integration in MainActivity: Start watchdog on app launch.
 */

package com.antigravity.script_automator

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager

class WatchdogReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.i("ScriptAutomator", "Watchdog: Waking up to check background tasks...")

        // 1. Enqueue the ScriptUpdateWorker IMMEDIATELY
        // We use OneTimeWorkRequest with KEEP policy to avoid duplicate spam,
        // but ensuring it IS in the queue.
        val workRequest = OneTimeWorkRequest.Builder(ScriptUpdateWorker::class.java)
            .addTag("watchdog_triggered_update")
            .build()
            
        WorkManager.getInstance(context).enqueueUniqueWork(
            "script_update_urgent",
            ExistingWorkPolicy.REPLACE, // Force run now
            workRequest
        )

        // 2. Reschedule Watchdog (Self-Healing Loop)
        // Schedule next check in 15 minutes (or user setting)
        WatchdogScheduler.schedule(context)
    }
}

object WatchdogScheduler {
    private const val INTERVAL_MS = 15 * 60 * 1000L // 15 Minutes
    private const val REQUEST_CODE = 777

    fun schedule(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WatchdogReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, 
            REQUEST_CODE, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerAt = SystemClock.elapsedRealtime() + INTERVAL_MS

        // Use setAndAllowWhileIdle to punch through Doze mode (within limits)
        try {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                triggerAt,
                pendingIntent
            )
            Log.i("ScriptAutomator", "Watchdog: Scheduled next check for +15min")
        } catch (e: SecurityException) {
            Log.e("ScriptAutomator", "Watchdog: Failed to schedule (Permission?)", e)
        }
    }
}
