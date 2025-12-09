// android/app/build.gradle.kts — FINAL & BULLETPROOF (December 2025)
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")          // correct ID (not kotlin-android
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // Modern Kotlin compiler options (replaces the deprecated jvmTarget line)
    //kotlin {
    //    jvmToolchain(17)
    //}

    kotlinOptions {
        jvmTarget = "17"  // Update from 1.8
    }

    defaultConfig {
        applicationId = "com.example.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use debug keys for now (change later when you sign)
            signingConfig = signingConfigs.getByName("debug")
            // Disable minification to prevent stripping of native classes
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
