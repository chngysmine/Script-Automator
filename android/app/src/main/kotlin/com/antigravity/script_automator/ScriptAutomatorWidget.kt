package com.antigravity.script_automator

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.text.Text
import java.io.File
import com.google.gson.JsonParser
import com.google.gson.JsonObject

class ScriptAutomatorWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // Strategy: Read from "sasup_ui.json" in app files directory.
        // The Flutter app writes the widget JSON to this location after running a script.
        
        val filesDir = context.filesDir
        val jsonFile = File(filesDir, "sasup_ui.json")
        
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
                    else -> Text("Run a script to see widget!")
                }
            }
        }
    }
}

