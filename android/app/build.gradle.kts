plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.wildfire_mvp_v3"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.wildfire_mvp_v3"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Google Maps API Key configuration
        // SECURITY: Never commit API keys to git. Use one of these methods:
        // 1. gradle.properties: Add GOOGLE_MAPS_API_KEY_ANDROID=your_key_here
        // 2. Environment variable: export GOOGLE_MAPS_API_KEY_ANDROID=your_key_here
        // 3. dart-define-from-file: flutter run --dart-define-from-file=env/dev.env.json
        // The fallback placeholder will cause map tiles to fail (intentional for security)
        manifestPlaceholders["GOOGLE_MAPS_API_KEY_ANDROID"] = 
            project.findProperty("GOOGLE_MAPS_API_KEY_ANDROID")?.toString() 
            ?: System.getenv("GOOGLE_MAPS_API_KEY_ANDROID") 
            ?: "YOUR_API_KEY_HERE"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
