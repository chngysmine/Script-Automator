package com.antigravity.script_automator

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.updateAll

class ScriptRunnerActionCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        // 1. Acknowledge Action
        // In Phase 4, we will read parameters to know WHICH script to run.
        // For now, we treat this as a "Refresh" intent.
        
        // 2. Trigger Update
        ScriptAutomatorWidget().updateAll(context)
    }
}
