# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase & Pigeon classes
-keep class com.google.firebase.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }
-keep public class * extends io.flutter.plugins.firebase.core.FlutterFirebasePlugin { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class * implements io.flutter.plugin.common.MessageCodec { *; }
-keep class * implements io.flutter.plugin.common.MethodCodec { *; }

# Prevent stripping of Geocoding / Geolocator / Background Service
-keep class com.baseflow.geolocator.** { *; }
-keep class id.flutter.flutter_background_service.** { *; }

# Keep all java method channels
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.MethodChannel$* { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.EventChannel$* { *; }
