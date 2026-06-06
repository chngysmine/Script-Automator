package com.js.scriptAutomator

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.ColorFilter
import androidx.glance.action.clickable
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.background
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.appwidget.cornerRadius
import androidx.glance.unit.ColorProvider
import androidx.glance.LocalContext
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.appWidgetBackground
import android.content.Intent
import android.content.ComponentName
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.google.gson.JsonObject
import com.google.gson.JsonArray

private fun JsonObject.getObj(key: String): JsonObject? {
    return if (has(key) && !get(key).isJsonNull) getAsJsonObject(key) else null
}

private fun JsonObject.getArr(key: String): JsonArray? {
    return if (has(key) && !get(key).isJsonNull) getAsJsonArray(key) else null
}

private fun JsonObject.getStr(key: String): String? {
    return if (has(key) && !get(key).isJsonNull) get(key).asString else null
}

private fun JsonObject.getFloat(key: String): Float? {
    return if (has(key) && !get(key).isJsonNull) get(key).asFloat else null
}

private fun JsonObject.getInt(key: String): Int? {
    return if (has(key) && !get(key).isJsonNull) get(key).asInt else null
}

object GlanceJsonParser {

    @Composable
    fun RenderNode(node: JsonObject, isRoot: Boolean = false, modifier: GlanceModifier = GlanceModifier) {
        val type = node.getStr("type") ?: "container"
        val modifiers = node.getObj("modifiers") ?: JsonObject()
        var glanceModifier = modifier.then(parseModifiers(modifiers))
        
        if (isRoot) {
            glanceModifier = glanceModifier.fillMaxSize()
        }

        when (type) {
            "column" -> {
                val horizontalAlign = parseHorizontalAlignment(modifiers.getStr("alignment"))
                Column(
                    modifier = glanceModifier,
                    horizontalAlignment = horizontalAlign
                ) {
                    RenderColumnChildren(node)
                }
            }
            "row" -> {
                val verticalAlign = parseVerticalAlignment(modifiers.getStr("alignment"))
                 Row(
                    modifier = glanceModifier,
                    verticalAlignment = verticalAlign
                ) {
                    RenderRowChildren(node)
                }
            }
            "stack" -> {
                androidx.glance.layout.Box(
                    modifier = glanceModifier,
                    contentAlignment = Alignment.Center
                ) {
                    val children = node.getArr("children")
                    children?.forEach { child ->
                        if (child.isJsonObject) {
                            RenderNode(child.asJsonObject, false, GlanceModifier)
                        }
                    }
                }
            }
            "text" -> {
                val content = node.getStr("content") ?: ""
                val style = parseTextStyle(modifiers)
                Text(
                    text = content, 
                    modifier = glanceModifier, 
                    style = style,
                    maxLines = modifiers.getInt("maxLines") ?: 1
                )
            }
            "icon" -> {
                val content = node.getStr("content") ?: ""
                val iconRes = mapSfSymbolToAndroid(content)
                val tintColorStr = modifiers.getStr("color")
                val tint = if (tintColorStr != null) {
                    ColorProvider(ColorParser.parse(tintColorStr))
                } else {
                    ColorProvider(Color.White)
                }
                
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = glanceModifier.size((modifiers.getFloat("fontSize") ?: 24f).dp),
                    colorFilter = ColorFilter.tint(tint)
                )
            }
            "image" -> {
                val uriString = node.getStr("content") ?: ""
                if (uriString.startsWith("file://")) {
                    val path = uriString.removePrefix("file://")
                    // Safely downsample the image to prevent IPC TransactionTooLargeException
                    // since Android widgets limit the total Binder transaction payload to 1MB.
                    val bitmap = decodeSampledBitmapFromFile(path, reqWidth = 300, reqHeight = 300)
                    if (bitmap != null) {
                        Image(
                            provider = ImageProvider(bitmap),
                            contentDescription = null,
                            modifier = glanceModifier,
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Log.e("GlanceJsonParser", "Failed to decode and sample image at path: $path")
                    }
                }
            }
             "spacer" -> {
                Spacer(modifier = glanceModifier)
            }
            "container" -> {
                val horizontalAlign = parseHorizontalAlignment(modifiers.getStr("alignment"))
                val verticalAlign = parseVerticalAlignment(modifiers.getStr("alignment"))
                Column(
                    modifier = glanceModifier,
                    horizontalAlignment = horizontalAlign,
                    verticalAlignment = verticalAlign
                ) {
                    RenderColumnChildren(node)
                }
            }
            "button" -> {
                val actionId = node.getStr("actionId")
                val scriptId = node.getStr("scriptId")
                val label = node.getStr("label") ?: node.getStr("content") ?: ""

                if (!actionId.isNullOrBlank()) {
                    val params = actionParametersOf(
                        ScriptRunnerActionCallback.SCRIPT_ID to (scriptId ?: ""),
                        ScriptRunnerActionCallback.ACTION_ID to actionId
                    )
                    Text(
                        text = label,
                        modifier = glanceModifier.clickable(actionRunCallback<ScriptRunnerActionCallback>(parameters = params)),
                        style = parseTextStyle(modifiers),
                        maxLines = 1
                    )
                } else {
                    androidx.glance.layout.Box(
                        modifier = glanceModifier,
                        contentAlignment = Alignment.Center
                    ) {
                        val children = node.getArr("children")
                        children?.forEach { child ->
                            if (child.isJsonObject) {
                                RenderNode(child.asJsonObject, false, GlanceModifier)
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun ColumnScope.RenderColumnChildren(node: JsonObject) {
        val children = node.getArr("children") ?: return
        val modifiers = node.getObj("modifiers") ?: JsonObject()
        val spacing = modifiers.getFloat("spacing") ?: 0f
        val alignment = modifiers.getStr("alignment")

        val isSpaceBetween = alignment == "spaceBetween"
        val isSpaceEvenly = alignment == "spaceEvenly" || alignment == "spaceAround"

        children.forEachIndexed { index, child ->
            if (child.isJsonObject) {
                val childObj = child.asJsonObject
                val childType = childObj.getStr("type") ?: "container"
                val childModifiers = childObj.getObj("modifiers") ?: JsonObject()
                val hasFlex = childModifiers.getInt("flex") == 1

                if (isSpaceEvenly && index == 0) {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                }

                if (childType == "spacer") {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                } else {
                    val childModifier = if (hasFlex) GlanceModifier.defaultWeight() else GlanceModifier
                    RenderNode(childObj, isRoot = false, modifier = childModifier)
                }

                if (index < children.size() - 1) {
                    if (isSpaceBetween || isSpaceEvenly) {
                        Spacer(modifier = GlanceModifier.defaultWeight())
                    } else if (spacing > 0 && childType != "spacer") {
                        val nextChild = children.get(index + 1)
                        if (nextChild != null && nextChild.isJsonObject) {
                            val nextChildType = nextChild.asJsonObject.getStr("type") ?: "container"
                            if (nextChildType != "spacer") {
                                Spacer(modifier = GlanceModifier.height(spacing.dp))
                            }
                        }
                    }
                }

                if (isSpaceEvenly && index == children.size() - 1) {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                }
            }
        }
    }

    @Composable
    private fun RowScope.RenderRowChildren(node: JsonObject) {
        val children = node.getArr("children") ?: return
        val modifiers = node.getObj("modifiers") ?: JsonObject()
        val spacing = modifiers.getFloat("spacing") ?: 0f
        val alignment = modifiers.getStr("alignment")

        val isSpaceBetween = alignment == "spaceBetween"
        val isSpaceEvenly = alignment == "spaceEvenly" || alignment == "spaceAround"

        children.forEachIndexed { index, child ->
            if (child.isJsonObject) {
                val childObj = child.asJsonObject
                val childType = childObj.getStr("type") ?: "container"
                val childModifiers = childObj.getObj("modifiers") ?: JsonObject()
                val hasFlex = childModifiers.getInt("flex") == 1

                if (isSpaceEvenly && index == 0) {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                }

                if (childType == "spacer") {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                } else {
                    val childModifier = if (hasFlex) GlanceModifier.defaultWeight() else GlanceModifier
                    RenderNode(childObj, isRoot = false, modifier = childModifier)
                }

                if (index < children.size() - 1) {
                    if (isSpaceBetween || isSpaceEvenly) {
                        Spacer(modifier = GlanceModifier.defaultWeight())
                    } else if (spacing > 0 && childType != "spacer") {
                        val nextChild = children.get(index + 1)
                        if (nextChild != null && nextChild.isJsonObject) {
                            val nextChildType = nextChild.asJsonObject.getStr("type") ?: "container"
                            if (nextChildType != "spacer") {
                                Spacer(modifier = GlanceModifier.width(spacing.dp))
                            }
                        }
                    }
                }

                if (isSpaceEvenly && index == children.size() - 1) {
                    Spacer(modifier = GlanceModifier.defaultWeight())
                }
            }
        }
    }

    private fun parseModifiers(modifiers: JsonObject): GlanceModifier {
        var modifier: GlanceModifier = GlanceModifier

        // Padding
        val padding = modifiers.getObj("padding")
        if (padding != null) {
            val value = padding.getFloat("value")
            modifier = if (value != null) {
                 modifier.padding(value.dp)
            } else {
                val l = padding.getFloat("left") ?: 0f
                val t = padding.getFloat("top") ?: 0f
                val r = padding.getFloat("right") ?: 0f
                val b = padding.getFloat("bottom") ?: 0f
                modifier.padding(l.dp, t.dp, r.dp, b.dp)
            }
        }

        // Size
        val width = modifiers.getFloat("width")
        if (width != null) {
             modifier = modifier.width(width.dp)
        }
        
        val height = modifiers.getFloat("height")
        if (height != null) {
             modifier = modifier.height(height.dp)
        }

        // Background
        val bg = modifiers.getStr("background")
        if (bg != null) {
            if (bg == "glass") {
                modifier = modifier.background(Color(0x22FFFFFF)) // Subtle glass on Android
            } else if (bg.startsWith("linear-gradient")) {
                val firstHex = findFirstHexColor(bg)
                if (firstHex != null) {
                    modifier = modifier.background(ColorParser.parse(firstHex))
                }
            } else {
                modifier = modifier.background(ColorParser.parse(bg))
            }
        }
        
        // Corner Radius
        val cornerRadius = modifiers.getFloat("cornerRadius")
        if (cornerRadius != null) {
            modifier = modifier.cornerRadius(cornerRadius.dp)
        }
        
        // Action (Click)
        val onClick = modifiers.getStr("onClick")
        if (onClick != null) {
            if (onClick == "app") {
                val intent = Intent().apply {
                    component = ComponentName("com.js.scriptAutomator", "com.js.scriptAutomator.MainActivity")
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
        val font = modifiers.getStr("font")
        var style = TextStyle(
            fontSize = (modifiers.getFloat("fontSize") ?: 14f).sp,
            fontWeight = if (font == "bold" || font == "semibold") {
                FontWeight.Bold
            } else {
                FontWeight.Normal
            }
        )
        val color = modifiers.getStr("color")
        if (color != null) {
            style = style.copy(color = ColorProvider(ColorParser.parse(color)))
        }
        return style
    }

    private fun mapSfSymbolToAndroid(symbol: String): Int {
        val name = symbol.lowercase()
        return when {
            name.contains("sun") -> android.R.drawable.btn_star_big_on
            name.contains("moon") -> android.R.drawable.star_off
            name.contains("cloud") -> android.R.drawable.ic_menu_gallery
            name.contains("rain") || name.contains("drop") -> android.R.drawable.ic_menu_edit
            name.contains("wind") -> android.R.drawable.ic_menu_send
            name.contains("thermometer") -> android.R.drawable.ic_menu_info_details
            name.contains("location") -> android.R.drawable.ic_menu_mylocation
            name.contains("gear") || name.contains("settings") -> android.R.drawable.ic_menu_preferences
            name.contains("trash") || name.contains("delete") -> android.R.drawable.ic_menu_delete
            name.contains("clock") || name.contains("alarm") || name.contains("timer") -> android.R.drawable.ic_menu_today
            name.contains("play") -> android.R.drawable.ic_media_play
            name.contains("pause") -> android.R.drawable.ic_media_pause
            name.contains("stop") -> android.R.drawable.ic_menu_close_clear_cancel
            name.contains("phone") -> android.R.drawable.ic_menu_call
            name.contains("envelope") || name.contains("mail") -> android.R.drawable.sym_action_email
            name.contains("map") -> android.R.drawable.ic_dialog_map
            name.contains("info") -> android.R.drawable.ic_dialog_info
            name.contains("warn") || name.contains("alert") || name.contains("exclamation") -> android.R.drawable.ic_dialog_alert
            name.contains("share") -> android.R.drawable.ic_menu_share
            name.contains("camera") -> android.R.drawable.ic_menu_camera
            name.contains("search") -> android.R.drawable.ic_menu_search
            name.contains("compass") -> android.R.drawable.ic_menu_compass
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

    /**
     * Safely reads an image from disk and downsamples it.
     * Android Widgets communicate with the system via Binder IPC.
     * Binder transactions are strictly limited to 1MB. Loading full-res
     * images into memory will instantly Crash the widget process.
     */
    private fun decodeSampledBitmapFromFile(path: String, reqWidth: Int, reqHeight: Int): Bitmap? {
        try {
            // First decode with inJustDecodeBounds=true to check dimensions
            val options = BitmapFactory.Options()
            options.inJustDecodeBounds = true
            BitmapFactory.decodeFile(path, options)

            // Calculate inSampleSize
            options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)

            // Decode bitmap with inSampleSize set
            options.inJustDecodeBounds = false
            return BitmapFactory.decodeFile(path, options)
        } catch (e: Exception) {
            Log.e("GlanceJsonParser", "Error decoding sampled bitmap", e)
            return null
        }
    }

    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val (height: Int, width: Int) = options.outHeight to options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width.
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }


    object ColorParser {
        fun parse(colorStr: String?): Color {
            if (colorStr == null) return Color.Transparent
            val trimmed = colorStr.trim()
            if (trimmed.isEmpty()) return Color.Transparent
            
            if (trimmed.equals("transparent", ignoreCase = true)) {
                return Color.Transparent
            }
            
            if (trimmed.startsWith("#")) {
                val cleanHex = trimmed.removePrefix("#")
                try {
                    return when (cleanHex.length) {
                        3 -> { // #RGB -> #RRGGBB
                            val r = cleanHex.substring(0, 1).repeat(2)
                            val g = cleanHex.substring(1, 2).repeat(2)
                            val b = cleanHex.substring(2, 3).repeat(2)
                            Color(android.graphics.Color.parseColor("#$r$g$b"))
                        }
                        4 -> { // #RGBA -> #AARRGGBB
                            val r = cleanHex.substring(0, 1).repeat(2)
                            val g = cleanHex.substring(1, 2).repeat(2)
                            val b = cleanHex.substring(2, 3).repeat(2)
                            val a = cleanHex.substring(3, 4).repeat(2)
                            val colorInt = java.lang.Long.parseLong("$a$r$g$b", 16).toInt()
                            Color(colorInt)
                        }
                        6 -> { // #RRGGBB
                            Color(android.graphics.Color.parseColor("#$cleanHex"))
                        }
                        8 -> { // CSS hex #RRGGBBAA -> Android expects #AARRGGBB
                            val r = cleanHex.substring(0, 2)
                            val g = cleanHex.substring(2, 4)
                            val b = cleanHex.substring(4, 6)
                            val a = cleanHex.substring(6, 8)
                            val colorInt = java.lang.Long.parseLong("$a$r$g$b", 16).toInt()
                            Color(colorInt)
                        }
                        else -> {
                            Color(android.graphics.Color.parseColor(trimmed))
                        }
                    }
                } catch (e: Exception) {
                    return Color.Transparent
                }
            } else if (trimmed.startsWith("rgba") || trimmed.startsWith("rgb")) {
                try {
                    val cleaned = trimmed.replace("rgba(", "")
                        .replace("rgb(", "")
                        .replace(")", "")
                        .replace(" ", "")
                    val parts = cleaned.split(",")
                    if (parts.size >= 3) {
                        val r = parts[0].toInt()
                        val g = parts[1].toInt()
                        val b = parts[2].toInt()
                        val a = if (parts.size == 4) parts[3].toFloat() else 1f
                        return Color(red = r / 255f, green = g / 255f, blue = b / 255f, alpha = a)
                    }
                } catch (e: Exception) {
                    return Color.Transparent
                }
            }
            
            // Try parsing by name (red, blue, etc.)
            try {
                return Color(android.graphics.Color.parseColor(trimmed))
            } catch (e: Exception) {
                return Color.Transparent
            }
        }
    }
}
