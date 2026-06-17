plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read signing credentials from android/key.properties (git-ignored).
// Create key.properties from the template before building a release.
// val keystorePropertiesFile = rootProject.file("key.properties")
// val keystoreProperties = java.util.Properties()
// if (keystorePropertiesFile.exists()) {
//     keystoreProperties.load(keystorePropertiesFile.inputStream())
// }

android {
    namespace = "com.reimixapp.reimix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        // if (keystorePropertiesFile.exists()) {
        //     create("release") {
        //         keyAlias = keystoreProperties["keyAlias"] as String
        //         keyPassword = keystoreProperties["keyPassword"] as String
        //         storeFile = file(keystoreProperties["storeFile"] as String)
        //         storePassword = keystoreProperties["storePassword"] as String
        //     }
        // }
    }

    defaultConfig {
        applicationId = "com.reimixapp.reimix"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // signingConfig = if (keystorePropertiesFile.exists()) {
            //     signingConfigs.getByName("release")
            // } else {
                // Fallback to debug signing if key.properties is absent
                // (e.g. during CI testing — NOT for Play Store uploads).
                signingConfigs.getByName("debug")
            // }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

dependencies {
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
