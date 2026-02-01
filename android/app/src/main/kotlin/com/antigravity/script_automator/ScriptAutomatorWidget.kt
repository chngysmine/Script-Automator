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
        // Strategy: Read from "sasup_ui.json" in root files dir.
        // In real implementations, mapping GlanceId to specific file ID is needed.
        // We stick to a single file for the "Universal Engine" MVP.
        
        val file = File(context.filesDir, "sasup_ui.json")
        
        val rootNode: JsonObject? = try {
            if (file.exists()) {
                val content = file.readText()
                val json = JsonParser.parseString(content).asJsonObject
                if (json.has("root")) {
                    json.getAsJsonObject("root")
                } else {
                    null
                }
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }

        provideContent {
            GlanceTheme {
                if (rootNode != null) {
                    GlanceJsonParser.RenderNode(rootNode)
                } else {
                    // Fallback / Placeholder UI
                    Text("No Script Output Available")
                }
            }
        }
    }
}
