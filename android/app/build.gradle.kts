import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kurichiyar.matrimony"
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

    packaging {
        jniLibs {
            keepDebugSymbols.add("**/*.so")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kurichiyar.matrimony"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        
        // Auto-increment version code & version name logic
        val versionPropsFile = rootProject.file("version.properties")
        if (versionPropsFile.exists()) {
            val versionProps = Properties()
            versionProps.load(FileInputStream(versionPropsFile))
            versionCode = (versionProps.getProperty("VERSION_CODE") ?: "3").toInt()
            val major = versionProps.getProperty("VERSION_MAJOR") ?: "1"
            val minor = versionProps.getProperty("VERSION_MINOR") ?: "0"
            val patch = versionProps.getProperty("VERSION_PATCH") ?: "2"
            versionName = "$major.$minor.$patch"
        } else {
            versionCode = flutter.versionCode
            versionName = flutter.versionName
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") as String?
            keyPassword = keystoreProperties.getProperty("keyPassword") as String?
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword") as String?
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            val hasKeystore = storeFilePath != null && file(storeFilePath).exists()
            signingConfig = if (hasKeystore) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
    exclude(group = "org.jitsi", module = "webrtc")
    exclude(group = "androidx.media3", module = "media3-exoplayer-rtsp")
}

tasks.withType<Copy> {
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

tasks.matching { it.name.contains("AarMetadata") }.configureEach {
    enabled = false
}
