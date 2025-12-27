import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // RESTORED: This is required for Firebase to work
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.sevak_app"
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
        applicationId = "com.example.sevak_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // RESTORED: Load your real release key from key.properties
    signingConfigs {
        create("release") {
            val keyPropertiesFile = rootProject.file("key.properties")
            val props = Properties()
            if (keyPropertiesFile.exists()) {
                FileInputStream(keyPropertiesFile).use { props.load(it) }
            }

            keyAlias = props.getProperty("keyAlias")
            keyPassword = props.getProperty("keyPassword")
            storeFile = props.getProperty("storeFile")?.let { file(it) }
            storePassword = props.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // RESTORED: Use the release key, NOT the debug key
            signingConfig = signingConfigs.getByName("release")
            // Enable minification and resource shrinking for production releases.
            // These are memory-intensive; Gradle JVM heap must be increased (see gradle.properties).
            isMinifyEnabled = true
            isShrinkResources = true
            // Keep debug-friendly mapping file mapping for troubleshooting if needed
        }
    }

// Ensure Flutter tooling can find the output APK produced by Gradle.
// Some Flutter versions expect the APK under <root>/build/app/outputs/flutter-apk/.
// Add a small task to copy the release APK after assembleRelease so Flutter's lookup succeeds.
tasks.register("copyReleaseApk") {
    doLast {
        val apkFile = file("${project.buildDir}/outputs/apk/release/app-release.apk")
        val destDir = file("${rootProject.buildDir}/app/outputs/flutter-apk/")
        if (apkFile.exists()) {
            destDir.mkdirs()
            copy {
                from(apkFile)
                into(destDir)
            }
            println("Copied release APK to: ${destDir.absolutePath}")
        } else {
            println("Release APK not found at: ${apkFile.absolutePath}")
        }
    }
}

tasks.named("assembleRelease") {
    finalizedBy("copyReleaseApk")
}
}

flutter {
    source = "../.."
}

dependencies {
    // RESTORED: Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
}