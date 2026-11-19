# Flutter references Play Core (deferred components) even when unused.
-dontwarn com.google.android.play.core.**

# google_mlkit_text_recognition references optional script recognizers
# (Chinese, Devanagari, Japanese, Korean) that aren't bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# super_clipboard / super_native_extensions and irondash call into these
# classes from native code (JNI) by name; R8 would strip them in release
# builds and "Copy as image" would silently fail.
-keep class com.superlist.super_native_extensions.** { *; }
-keep class dev.irondash.** { *; }
-keepclasseswithmembers class * { native <methods>; }
