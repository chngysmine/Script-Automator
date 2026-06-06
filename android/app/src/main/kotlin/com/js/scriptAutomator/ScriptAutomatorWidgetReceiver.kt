package com.js.scriptAutomator
 
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

class ScriptAutomatorWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ScriptAutomatorWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.js.scriptAutomator.WIDGET_PINNED") {
            val widgetId = intent.getIntExtra(
                android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID,
                android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID
            )
            Log.i("WidgetReceiver", "Pinned widget callback received. New Widget ID: $widgetId")
            if (widgetId != android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID) {
                val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
                val scriptId = prefs.getString("pending_pin_script_id", null)
                if (scriptId != null) {
                    prefs.edit()
                        .putString("widget_$widgetId", scriptId)
                        .remove("pending_pin_script_id")
                        .apply()
                    Log.i("WidgetReceiver", "Successfully associated widget $widgetId with script $scriptId")
                    
                    // Force update to display the script layout immediately
                    MainScope().launch {
                        try {
                            ScriptAutomatorWidget().updateAll(context)
                        } catch (e: Exception) {
                            Log.e("WidgetReceiver", "Failed to update widget: ${e.message}")
                        }
                    }
                }
            }
        }
    }
}
