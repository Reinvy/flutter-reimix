# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ObjectBox
-keep class io.objectbox.** { *; }
-keepclassmembers class io.objectbox.** { *; }
-keep class com.reimixapp.reimix.** { *; }
-keep @io.objectbox.annotation.Entity class * { *; }

# audio_service
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.** { *; }

# just_audio
-keep class com.ryanheise.just_audio.** { *; }

# Keep all native plugins
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }
