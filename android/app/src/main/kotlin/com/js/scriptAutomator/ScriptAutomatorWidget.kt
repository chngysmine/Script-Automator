package com.js.scriptAutomator

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.provideContent
import androidx.glance.text.Text
import java.io.File
import com.google.gson.JsonParser
import com.google.gson.JsonObject

class ScriptAutomatorWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        val scriptId = prefs.getString("widget_$appWidgetId", null)
        
        val filesDir = context.filesDir
        val jsonFile = if (scriptId != null) {
            val scriptFile = File(filesDir, "sasup_ui_${scriptId}_glance.json")
            if (scriptFile.exists()) {
                scriptFile
            } else {
                val normalFile = File(filesDir, "sasup_ui_$scriptId.json")
                if (normalFile.exists()) normalFile else File(filesDir, "sasup_ui_glance.json")
            }
        } else {
            val defaultGlance = File(filesDir, "sasup_ui_glance.json")
            if (defaultGlance.exists()) defaultGlance else File(filesDir, "sasup_ui.json")
        }
        
        var rootNode: JsonObject? = null
        var errorMessage: String? = null
        
        if (jsonFile.exists()) {
            try {
                val json = jsonFile.readText()
                val rootObject = JsonParser.parseString(json).asJsonObject
                rootNode = rootObject.getAsJsonObject("root")
            } catch (e: Exception) {
                errorMessage = e.message
            }
        }

        provideContent {
            GlanceTheme {
                when {
                    rootNode != null -> GlanceJsonParser.RenderNode(rootNode, isRoot = true)
                    errorMessage != null -> Text("Widget Error: ${errorMessage.take(50)}")
                    scriptId != null -> Text("Selected script hasn't run yet. Run it in the app!")
                    else -> Text("Run a script to see widget!")
                }
            }
        }
    }
}


