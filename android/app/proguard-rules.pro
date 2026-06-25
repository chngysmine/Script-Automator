# Flutter Wrapper rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class org.chromium.** { *; }

# Keep native methods and JNI bindings
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep our Custom Widget Receiver and Watchdog classes
-keep class com.js.scriptAutomator.ScriptAutomatorWidgetReceiver { *; }
-keep class com.js.scriptAutomator.WatchdogReceiver { *; }

# Keep Glance app widgets classes
-keep class androidx.glance.** { *; }

# Keep Gson serialization models
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent obfuscation of JSEngine and FFI related classes if any
-keep class com.js.scriptAutomator.JSEngine { *; }
