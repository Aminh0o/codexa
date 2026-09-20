# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# pdfrx / PDFium
-keep class com.shockwave.** { *; }
-dontwarn com.shockwave.**

# Google HTTP Client
-keep class com.google.api.client.** { *; }
-dontwarn com.google.api.client.**

# Google Drive API
-keep class com.google.api.services.drive.** { *; }
-dontwarn com.google.api.services.drive.**

# Gson (used by Google HTTP client)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Http
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**
-dontwarn android.net.**

# Play Store SplitInstall (referenced by Flutter but not used)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Flutter Secure Storage
-keep class com.itNomNom.flutter_secure_storage.** { *; }
-dontwarn com.itNomNom.flutter_secure_storage.**
