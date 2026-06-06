package com.js.scriptAutomator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import kotlinx.coroutines.MainScope
import androidx.glance.appwidget.updateAll
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.js/paths"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNativeFilesDir") {
                result.success(context.filesDir.absolutePath)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.js.scriptAutomator/widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "reloadTimelines" -> {
                    // Trigger Widget Update
                    try {
                        MainScope().launch {
                           ScriptAutomatorWidget().updateAll(context)
                           result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("UPDATE_FAILED", e.message, null)
                    }
                }
                "getAndroidWidgetIds" -> {
                    try {
                        val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(context)
                        val componentName = android.content.ComponentName(context, ScriptAutomatorWidgetReceiver::class.java)
                        val widgetIds = appWidgetManager.getAppWidgetIds(componentName).toList()
                        result.success(widgetIds)
                    } catch (e: Exception) {
                        result.error("GET_IDS_FAILED", e.message, null)
                    }
                }
                "getWidgetAssociations" -> {
                    try {
                        val prefs = context.getSharedPreferences("widget_prefs", android.content.Context.MODE_PRIVATE)
                        val map = prefs.all.filter { it.key.startsWith("widget_") && it.value is String }
                        result.success(map)
                    } catch (e: Exception) {
                        result.error("GET_ASSOCIATIONS_FAILED", e.message, null)
                    }
                }
                "associateWidgetWithScript" -> {
                    try {
                        val widgetId = call.argument<Int>("widgetId")
                        val scriptId = call.argument<String>("scriptId")
                        if (widgetId != null) {
                            val prefs = context.getSharedPreferences("widget_prefs", android.content.Context.MODE_PRIVATE)
                            if (scriptId != null && scriptId.isNotEmpty()) {
                                prefs.edit().putString("widget_$widgetId", scriptId).apply()
                            } else {
                                prefs.edit().remove("widget_$widgetId").apply()
                            }
                            MainScope().launch {
                                ScriptAutomatorWidget().updateAll(context)
                                result.success(true)
                            }
                        } else {
                            result.error("INVALID_ARGS", "widgetId is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("ASSOCIATE_FAILED", e.message, null)
                    }
                }
                "pinWidget" -> {
                    try {
                        val scriptId = call.argument<String>("scriptId")
                        val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(context)
                        val componentName = android.content.ComponentName(context, ScriptAutomatorWidgetReceiver::class.java)
                        
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O && appWidgetManager.isRequestPinAppWidgetSupported) {
                            if (scriptId != null && scriptId.isNotEmpty()) {
                                val prefs = context.getSharedPreferences("widget_prefs", android.content.Context.MODE_PRIVATE)
                                prefs.edit().putString("pending_pin_script_id", scriptId).apply()
                            }
                            
                            val successCallback = android.app.PendingIntent.getBroadcast(
                                context,
                                999,
                                android.content.Intent(context, ScriptAutomatorWidgetReceiver::class.java).apply {
                                    action = "com.js.scriptAutomator.WIDGET_PINNED"
                                },
                                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
                            )
                            
                            appWidgetManager.requestPinAppWidget(componentName, null, successCallback)
                            result.success(true)
                        } else {
                            result.error("NOT_SUPPORTED", "Pinning widgets is not supported on this device/launcher", null)
                        }
                    } catch (e: Exception) {
                        result.error("PIN_FAILED", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Start Background Watchdog for periodic widget updates
        WatchdogScheduler.schedule(context)
    }
}
