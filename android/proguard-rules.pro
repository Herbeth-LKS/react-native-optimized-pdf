# React Native Optimized PDF - ProGuard Rules

# Keep the native view classes
-keep class com.reactnativeoptimizedpdf.** { *; }

# Keep React Native classes
-keep class com.facebook.react.** { *; }

# Keep PDF Renderer
-keep class android.graphics.pdf.** { *; }
