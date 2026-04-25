plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

// ── Secrets ────────────────────────────────────────────────────────────────
// key.properties : signing keystore (gitignored)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// local.properties : clés API non-signing (Google Maps, etc.). Aussi gitignoré.
// On tolère MAPS_API_KEY absent pour les debug builds locaux, mais on fail fast
// sur un release sans clé (sinon les Maps crashent à la prod sans diagnostic).
val localPropertiesFile = rootProject.file("local.properties")
val localProperties = Properties()
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY")
    ?: System.getenv("MAPS_API_KEY")
    ?: ""

android {
    namespace = "com.spotbook.app"
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
        applicationId = "com.spotbook.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Injecté dans AndroidManifest.xml : <meta-data ... android:value="${MAPS_API_KEY}"/>
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        // On ne crée la signing config "release" que si key.properties existe.
        // Sinon, un `flutter build apk` sans keystore échouait avant de planter
        // sur un NullPointerException illisible ("storeFile must not be null").
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // R8 : minification + obfuscation + shrink ressources.
            // Rend le reverse-engineering (Jadx/apktool) bien plus coûteux
            // et réduit la taille de l'APK de 30-50%.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Fallback sur debug si pas de keystore (CI sans secrets).
            // En prod, key.properties DOIT être présent.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }

        debug {
            // Debug explicite : pas de minify (debuggable + stack traces lisibles)
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM — gère les versions compatibles automatiquement
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Cloud Messaging (FCM)
    implementation("com.google.firebase:firebase-messaging")
}
