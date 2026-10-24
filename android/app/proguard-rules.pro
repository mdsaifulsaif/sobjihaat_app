# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SharedPreferences R8 keep rules to fix release crash
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesApiRegistrar { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesAsyncApiRegistrar { *; }

# Secure Storage
-keep class androidx.security.crypto.** { *; }

# Suppress warnings for Play Core deferred components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
