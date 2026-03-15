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
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.action.actionRunCallback
import android.content.Intent
import android.content.ComponentName
import android.graphics.BitmapFactory
import com.google.gson.JsonObject

object GlanceJsonParser {

    @Composable
    fun RenderNode(node: JsonObject, isRoot: Boolean = false) {
        val type = node.get("type").asString
        val modifiers = if (node.has("modifiers")) node.getAsJsonObject("modifiers") else JsonObject()
        var glanceModifier = parseModifiers(modifiers)
        
        if (isRoot) {
            glanceModifier = glanceModifier.fillMaxSize()
        }

        when (type) {
            "column" -> {
                val horizontalAlign = parseHorizontalAlignment(modifiers.get("alignment")?.asString)
                val verticalAlign = parseVerticalAlignment(modifiers.get("alignment")?.asString)
                Column(
                    modifier = glanceModifier,
                    horizontalAlignment = horizontalAlign,
                    verticalAlignment = verticalAlign
                ) {
                    RenderChildren(node)
                }
            }
            "row" -> {
                val horizontalAlign = parseHorizontalAlignment(modifiers.get("alignment")?.asString)
                val verticalAlign = parseVerticalAlignment(modifiers.get("alignment")?.asString)
                 Row(
                    modifier = glanceModifier,
                    horizontalAlignment = horizontalAlign,
                    verticalAlignment = verticalAlign
                ) {
                    RenderChildren(node)
                }
            }
            "stack" -> {
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
                Text(
                    text = content, 
                    modifier = glanceModifier, 
                    style = style,
                    maxLines = if (modifiers.has("maxLines")) modifiers.get("maxLines").asInt else 1
                )
            }
            "icon" -> {
                val content = node.get("content").asString
                val iconRes = mapSfSymbolToAndroid(content)
                val tint = if (modifiers.has("color")) {
                    ColorProvider(Color(android.graphics.Color.parseColor(modifiers.get("color").asString)))
                } else {
                    ColorProvider(Color.White)
                }
                
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = glanceModifier.size((modifiers.get("fontSize")?.asFloat ?: 24f).dp),
                    colorFilter = ColorFilter.tint(tint)
                )
            }
            "image" -> {
                val uriString = node.get("content").asString
                if (uriString.startsWith("file://")) {
                    val path = uriString.removePrefix("file://")
                    val bitmap = BitmapFactory.decodeFile(path)
                    if (bitmap != null) {
                        Image(
                            provider = ImageProvider(bitmap),
                            contentDescription = null,
                            modifier = glanceModifier,
                            contentScale = ContentScale.Crop
                        )
                    }
                }
            }
             "spacer" -> {
                Spacer(modifier = glanceModifier)
            }
            "container" -> {
                var contentAlignment = Alignment.Center
                if (modifiers.has("alignment")) {
                    val align = modifiers.get("alignment").asString
                    contentAlignment = when (align) {
                        "topStart" -> Alignment.TopStart
                        "topCenter" -> Alignment.TopCenter
                        "topEnd" -> Alignment.TopEnd
                        "centerStart" -> Alignment.CenterStart
                        "center" -> Alignment.Center
                        "centerEnd" -> Alignment.CenterEnd
                        "bottomStart" -> Alignment.BottomStart
                        "bottomCenter" -> Alignment.BottomCenter
                        "bottomEnd" -> Alignment.BottomEnd
                        else -> Alignment.Center
                    }
                }

                androidx.glance.layout.Box(
                    modifier = glanceModifier,
                    contentAlignment = contentAlignment
                ) {
                    RenderChildren(node)
                }
            }
        }
    }

    @Composable
    private fun RenderChildren(node: JsonObject) {
        if (node.has("children")) {
            val children = node.getAsJsonArray("children")
            children.forEach { child ->
                RenderNode(child.asJsonObject, false)
            }
        }
    }

    private fun parseModifiers(modifiers: JsonObject): GlanceModifier {
        var modifier: GlanceModifier = GlanceModifier

        // Padding
        if (modifiers.has("padding")) {
            val padding = modifiers.getAsJsonObject("padding")
            modifier = if (padding.has("value")) {
                 val all = padding.get("value").asFloat
                 modifier.padding(all.dp)
            } else {
                val l = padding.get("left")?.asFloat ?: 0f
                val t = padding.get("top")?.asFloat ?: 0f
                val r = padding.get("right")?.asFloat ?: 0f
                val b = padding.get("bottom")?.asFloat ?: 0f
                modifier.padding(l.dp, t.dp, r.dp, b.dp)
            }
        }

        // Size
        if (modifiers.has("width")) {
             modifier = modifier.width(modifiers.get("width").asFloat.dp)
        }
        
        if (modifiers.has("height")) {
             modifier = modifier.height(modifiers.get("height").asFloat.dp)
        }
        
        if (modifiers.has("flex") && modifiers.get("flex").asInt == 1) {
            // In Column/Row, weight is handled differently, but for root it's fillMaxSize
            // We handle weight via a different mechanism if needed, but flex:1 usually means fill
            modifier = modifier.fillMaxWidth().fillMaxHeight()
        }

        // Background
        if (modifiers.has("background")) {
            val bg = modifiers.get("background").asString
            if (bg == "glass") {
                modifier = modifier.background(Color(0x22FFFFFF)) // Subtle glass on Android
            } else if (bg.startsWith("linear-gradient")) {
                val firstHex = findFirstHexColor(bg)
                if (firstHex != null) {
                    modifier = modifier.background(Color(android.graphics.Color.parseColor(firstHex)))
                }
            } else {
                try {
                    modifier = modifier.background(Color(android.graphics.Color.parseColor(bg)))
                } catch (e: Exception) { }
            }
        }
        
        // Corner Radius
        if (modifiers.has("cornerRadius")) {
            modifier = modifier.cornerRadius(modifiers.get("cornerRadius").asFloat.dp)
        }
        
        // Action (Click)
        if (modifiers.has("onClick")) {
            val actionType = modifiers.get("onClick").asString
            if (actionType == "app") {
                val intent = Intent().apply {
                    component = ComponentName("com.antigravity.script_automator", "com.antigravity.script_automator.MainActivity")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                modifier = modifier.clickable(actionStartActivity(intent))
            } else {
                 modifier = modifier.clickable(actionRunCallback<ScriptRunnerActionCallback>())
            }
        }
        
        return modifier
    }

    private fun findFirstHexColor(input: String): String? {
        val regex = "#[a-fA-F0-9]{6,8}".toRegex()
        return regex.find(input)?.value
    }

    private fun parseTextStyle(modifiers: JsonObject): TextStyle {
        var style = TextStyle(
            fontSize = (modifiers.get("fontSize")?.asFloat ?: 14f).sp,
            fontWeight = if (modifiers.get("font")?.asString == "bold" || modifiers.get("font")?.asString == "semibold") {
                FontWeight.Bold
            } else {
                FontWeight.Normal
            }
        )
        if (modifiers.has("color")) {
            val hex = modifiers.get("color").asString
            style = style.copy(color = ColorProvider(Color(android.graphics.Color.parseColor(hex))))
        }
        return style
    }

    private fun mapSfSymbolToAndroid(symbol: String): Int {
        return when (symbol) {
            "moon.stars.fill" -> android.R.drawable.ic_menu_today // Placeholder for lunar
            "sun.max.fill" -> android.R.drawable.ic_menu_day
            "cloud.fill" -> android.R.drawable.ic_menu_gallery
            "location.fill" -> android.R.drawable.ic_menu_mylocation
            "drop.fill" -> android.R.drawable.ic_menu_edit
            "wind" -> android.R.drawable.ic_menu_send
            "thermometer.medium" -> android.R.drawable.ic_menu_info_details
            else -> android.R.drawable.ic_menu_help
        }
    }

    private fun parseHorizontalAlignment(align: String?): Alignment.Horizontal {
        return when (align) {
            "center", "spaceAround", "spaceEvenly" -> Alignment.CenterHorizontally
            "end", "bottomEnd", "topEnd" -> Alignment.End
            else -> Alignment.Start
        }
    }

    private fun parseVerticalAlignment(align: String?): Alignment.Vertical {
        return when (align) {
            "center", "spaceAround", "spaceEvenly" -> Alignment.CenterVertically
            "end", "bottomCenter", "bottomEnd" -> Alignment.Bottom
            else -> Alignment.Top
        }
    }
}
