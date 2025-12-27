# Android Setup for react-native-optimized-pdf

## Automatic Linking (React Native 0.60+)

The package will be automatically linked when you run your project. No manual linking required.

## Manual Setup (if needed)

If automatic linking doesn't work, follow these steps:

### 1. Add to `settings.gradle`

```gradle
include ':react-native-optimized-pdf'
project(':react-native-optimized-pdf').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-optimized-pdf/android')
```

### 2. Add to `app/build.gradle`

```gradle
dependencies {
    implementation project(':react-native-optimized-pdf')
}
```

### 3. Add to `MainApplication.java` or `MainApplication.kt`

**Java:**

```java
import com.reactnativeoptimizedpdf.OptimizedPdfPackage;

@Override
protected List<ReactPackage> getPackages() {
    List<ReactPackage> packages = new PackageList(this).getPackages();
    packages.add(new OptimizedPdfPackage());
    return packages;
}
```

**Kotlin:**

```kotlin
import com.reactnativeoptimizedpdf.OptimizedPdfPackage

override fun getPackages(): List<ReactPackage> =
    PackageList(this).packages.apply {
        add(OptimizedPdfPackage())
    }
```

## Requirements

- Android SDK 24+
- Kotlin 1.9+

## Features

- High-performance PDF rendering using Android's native PdfRenderer
- Smooth zoom and pan with gesture support
- Double-tap to zoom/reset
- Memory-efficient rendering with proper bitmap recycling
- Antialiasing support for crisp text
