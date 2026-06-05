package com.js.scriptAutomator

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.updateAll
import java.io.File
import org.json.JSONObject

class ScriptRunnerActionCallback : ActionCallback {
    companion object {
        val SCRIPT_ID = ActionParameters.Key<String>("scriptId")
        val ACTION_ID = ActionParameters.Key<String>("actionId")
    }

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val scriptId = parameters[SCRIPT_ID] ?: return
        val actionId = parameters[ACTION_ID] ?: return

        val payload = JSONObject().apply {
            put("scriptId", scriptId)
            put("actionId", actionId)
            put("timestamp", System.currentTimeMillis().toString())
        }

        val pendingFile = File(context.filesDir, "pending_action.json")
        pendingFile.writeText(payload.toString())

        ScriptAutomatorWidget().updateAll(context)
    }
}
