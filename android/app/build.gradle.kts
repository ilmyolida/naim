plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin is now applied after the Android plugin (Built-in Kotlin)
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "an.naim.library"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs = freeCompilerArgs + listOf(
            "-Xskip-metadata-version-check",
            "-Xuse-deprecated-lambda-syntax"
        )
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "an.naim.library"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = file("key.properties")
    if (!keystorePropertiesFile.exists()) {
        throw GradleException("[ERROR] key.properties fayli topilmadi: $keystorePropertiesFile")
    }
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))

    val jksFile = file("$rootDir/app/naim.jks")
    if (!jksFile.exists()) {
        throw GradleException("[ERROR] naim.jks fayli topilmadi: $jksFile")
    }

    signingConfigs {
        create("release") {
            val keyAliasValue = keystoreProperties["keyAlias"] as String?
            val keyPasswordValue = keystoreProperties["keyPassword"] as String?
            val storePasswordValue = keystoreProperties["storePassword"] as String?
            if (keyAliasValue.isNullOrBlank() || keyPasswordValue.isNullOrBlank() || storePasswordValue.isNullOrBlank()) {
                throw GradleException("[ERROR] key.properties faylida keyAlias, keyPassword yoki storePassword yo'q yoki bo'sh!")
            }
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storeFile = jksFile
            storePassword = storePasswordValue
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
