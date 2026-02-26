plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.liquidsync.liquidsync_gallery"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.liquidsync.liquidsync_gallery"
        // minSdk 23: required by local_auth (biometrics) + flutter_secure_storage
        minSdk = flutter.minSdkVersion
        // targetSdk 36: Android 16 with compatible plugins
        targetSdk = 36
        compileSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Multidex for large dependency trees
        multiDexEnabled = true
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
