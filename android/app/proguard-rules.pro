# =============================================================================
# ProGuard / R8 keep rules for release (minified) builds.
# AGP 9 enables R8 by default. These rules preserve classes that plugins
# instantiate via reflection or JNI, which R8 would otherwise strip/rename
# and cause runtime crashes (e.g. WorkManager's Room DB failing to init).
# =============================================================================

# ---- Keep native (JNI) method names across the app ----
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---- Keep useful attributes for reflection / stack traces ----
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod, RuntimeVisibleAnnotations

# ---- androidx App Startup (InitializationProvider) ----
-keep class androidx.startup.** { *; }

# ---- WorkManager (used by home_widget for background widget updates) ----
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.ListenableWorker { <init>(...); }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger

# ---- Room (WorkManager's internal DB, and any app usage) ----
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-keepclassmembers class * { @androidx.room.* <methods>; }
-dontwarn androidx.room.paging.**

# ---- home_widget ----
-keep class es.antonborri.home_widget.** { *; }

# ---- sqflite + sqflite_sqlcipher / SQLCipher ----
-keep class com.tekartik.sqflite.** { *; }
-keep class net.zetetic.** { *; }
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# ---- Google Sign-In / Google Play Services ----
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ---- sign_in_with_apple ----
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# ---- geolocator / geocoding (Baseflow) ----
-keep class com.baseflow.** { *; }

# ---- Flutter embedding / plugins (safety) ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
