# Flutter standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class org.chromium.** { *; }

# AndroidX WorkManager rules
-keep class androidx.work** { *; }
-dontwarn androidx.work**
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# AndroidX Room Database rules
-keep class androidx.room** { *; }
-dontwarn androidx.room**
-keep class * extends androidx.room.RoomDatabase

# Hive database rules
-keep class com.hivedb.** { *; }
-dontwarn com.hivedb.**
-keep class * extends io.hive.**

# Google Mobile Ads rules
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Firebase SDK rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter Play Core and Deferred Components warnings
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
