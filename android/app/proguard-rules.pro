# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive - Prevent stripping of adapters and models
-keep class com.ruchantopaca.namazvakti.models.** { *; }
-keep class * extends io.hive.TypeAdapter { *; }
-keepnames class * extends io.hive.TypeAdapter
-keep class io.hive.** { *; }

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Just Audio / ExoPlayer
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Ignore warnings for Play Core and Flutter Embedding (fixes R8 build failures)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
