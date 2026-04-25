plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Enable ML model binding for LiteRT-LM
    bundle {
        language {
            // Split APKs by language for smaller downloads
            enableSplit = true
        }
    }

    // Increase method limit for LiteRT-LM
    dexOptions {
        javaMaxHeapSize = "4g"
    }
}

android {
    namespace = "com.vocaviz.vocaviz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.vocaviz.vocaviz"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Enable ProGuard for smaller APK and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // Disable ProGuard for debug builds
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// LiteRT-LM dependency for Gemma 4 on-device inference
// Uncomment when model artifact is available:
// dependencies {
//     implementation("com.google.ai.edge.litert:litert-lm-android:1.0.0")
// }

flutter {
    source = "../.."
}
