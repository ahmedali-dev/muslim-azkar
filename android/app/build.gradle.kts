import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingFile = rootProject.file("key.properties")
val signing = Properties()
if (signingFile.exists()) signingFile.inputStream().use { signing.load(it) }

android {
    namespace = "com.muslimazkar.muslim_azkar"
    compileSdk = 36
    ndkVersion = "27.0.12077973"
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "com.muslimazkar.muslim_azkar"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resourceConfigurations += listOf("ar", "en")
    }
    packaging {
        jniLibs {
            useLegacyPackaging = true
            // Flutter release engines support ARMv7, ARM64, and x86_64.
            // Exclude the transitive DataStore x86-only library from bundles.
            excludes += "**/x86/**"
        }
    }
    signingConfigs {
        if (signingFile.exists()) create("upload") {
            keyAlias = signing.getProperty("keyAlias")
            keyPassword = signing.getProperty("keyPassword")
            storeFile = file(signing.getProperty("storeFile"))
            storePassword = signing.getProperty("storePassword")
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName(if (signingFile.exists()) "upload" else "debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"),"proguard-rules.pro")
        }
    }
}
flutter { source = "../.." }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
