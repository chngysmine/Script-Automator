package com.antigravity.script_automator

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.google.gson.JsonObject

object GlanceJsonParser {

    @Composable
    fun RenderNode(node: JsonObject) {
        val type = node.get("type").asString
        val modifiers = if (node.has("modifiers")) node.getAsJsonObject("modifiers") else JsonObject()
        val glanceModifier = parseModifiers(modifiers)

        when (type) {
            "column" -> {
                val horizontalAlign = parseAlignment(modifiers.get("alignment")?.asString, true) as Alignment.Horizontal
                val verticalAlign = parseAlignment(modifiers.get("alignment")?.asString, false) as Alignment.Vertical
                Column(
                    modifier = glanceModifier,
                    horizontalAlignment = horizontalAlign,
                    verticalAlignment = verticalAlign
                ) {
                    RenderChildren(node)
                }
            }
            "row" -> {
                val horizontalAlign = parseAlignment(modifiers.get("alignment")?.asString, true) as Alignment.Horizontal
                val verticalAlign = parseAlignment(modifiers.get("alignment")?.asString, false) as Alignment.Vertical
                 Row(
                    modifier = glanceModifier,
                    horizontalAlignment = horizontalAlign,
                    verticalAlignment = verticalAlign
                ) {
                    RenderChildren(node)
                }
            }
            "stack" -> {
                // Box equiv to ZStack
                // Glance Box content alignment is singular, unlike SwiftUI ZStack.
                // We default to Center for now.
                androidx.glance.layout.Box(
                    modifier = glanceModifier,
                    contentAlignment = Alignment.Center
                ) {
                    RenderChildren(node)
                }
            }
            "text" -> {
                val content = node.get("content").asString
                val style = parseTextStyle(modifiers)
                Text(text = content, modifier = glanceModifier, style = style)
            }
            "image" -> {
                val uriString = node.get("content").asString
                // Strict Security: Only allow file:// URIs from app internal storage
                if (uriString.startsWith("file://")) {
                    Image(
                        provider = ImageProvider(Uri.parse(uriString)),
                        contentDescription = null,
                        modifier = glanceModifier,
                        contentScale = ContentScale.Crop
                    )
                }
            }
             "spacer" -> {
                Spacer(modifier = glanceModifier)
            }
        }
    }

    @Composable
    private fun RenderChildren(node: JsonObject) {
        if (node.has("children")) {
            val children = node.getAsJsonArray("children")
            children.forEach { child ->
                RenderNode(child.asJsonObject)
            }
        }
    }

    private fun parseModifiers(modifiers: JsonObject): GlanceModifier {
        var modifier = GlanceModifier

        // Padding
        if (modifiers.has("padding")) {
            val padding = modifiers.getAsJsonObject("padding")
            if (padding.has("value")) {
                 val all = padding.get("value").asFloat
                 modifier = modifier.padding(all.dp)
            }
        }

        // Size
        if (modifiers.has("width")) {
             modifier = modifier.width(modifiers.get("width").asFloat.dp)
        } else if (modifiers.has("flex")) {
             modifier = modifier.defaultWeight() // Default weight for flex
        }
        
        if (modifiers.has("height")) {
             modifier = modifier.height(modifiers.get("height").asFloat.dp)
        }

        // Background
        if (modifiers.has("background")) {
            val bg = modifiers.get("background").asString
            if (bg == "glass") {
                // Premium Glass Simulation: Semi-transparent white
                modifier = modifier.background(Color(0x88FFFFFF))
            } else if (bg.startsWith("linear-gradient")) {
                // Dynamic Gradient Fallback: Extract first color or use default
                // Format assumed: linear-gradient(deg, #Color1, #Color2)
                val firstHex = findFirstHexColor(bg)
                if (firstHex != null) {
                    modifier = modifier.background(Color(android.graphics.Color.parseColor(firstHex)))
                } else {
                     modifier = modifier.background(Color(0xFF6200EE)) // Fallback if parsing fails
                }
            } else {
                try {
                    modifier = modifier.background(Color(android.graphics.Color.parseColor(bg)))
                } catch (e: Exception) { }
            }
        }
        
        // Action (Click)
        if (modifiers.has("onClick")) {
            val actionType = modifiers.get("onClick").asString
            if (actionType == "app") {
                // Open App
                modifier = modifier.clickable(androidx.glance.appwidget.action.actionStartActivity<MainActivity>())
            } else {
                // Run Script Callback (Concrete Implementation)
                 modifier = modifier.clickable(androidx.glance.appwidget.action.actionRunCallback<ScriptRunnerActionCallback>())
            }
        }
        
        return modifier
    }

    private fun findFirstHexColor(input: String): String? {
        val regex = "#[a-fA-F0-9]{6}".toRegex()
        return regex.find(input)?.value
    }

    private fun parseTextStyle(modifiers: JsonObject): TextStyle {
        var style = TextStyle.defaults
        if (modifiers.has("color")) {
            val hex = modifiers.get("color").asString
            style = style.copy(color = ColorProvider(Color(android.graphics.Color.parseColor(hex))))
        }
        if (modifiers.has("font")) {
            val font = modifiers.get("font").asString
            if (font == "bold") {
                 // style = style.copy(fontWeight = FontWeight.Bold) // Glance doesn't support FontWeight directly in same way easily without resource
            }
        }
        return style
    }

    private fun parseAlignment(align: String?, isHorizontal: Boolean): Any {
        return if (isHorizontal) {
             when (align) {
                "center" -> Alignment.CenterHorizontally
                "end" -> Alignment.End
                else -> Alignment.Start
            }
        } else {
             when (align) {
                "center" -> Alignment.CenterVertically
                "end" -> Alignment.Bottom
                else -> Alignment.Top
            }
        }
    }
}
