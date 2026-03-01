import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
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

    signingConfigs {
        create("release") {
            val keyPropertiesFile = rootProject.file("key.properties")
            val props = Properties()
            
            if (keyPropertiesFile.exists()) {
                FileInputStream(keyPropertiesFile).use { props.load(it) }
            }

            keyAlias = props.getProperty("keyAlias")
            keyPassword = props.getProperty("keyPassword")
            
            val storePath = props.getProperty("storeFile")
            if (storePath != null) {
                storeFile = rootProject.file(storePath)
            }
            
            storePassword = props.getProperty("storePassword")
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            if (rootProject.file("key.properties").exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")        // Downgrade from 1.9.0
            force("androidx.core:core:1.15.0")             // Downgrade from 1.17.0
            force("androidx.core:core-ktx:1.15.0")         // Downgrade from 1.17.0
        }
    }
}

// --- HELPER TASKS TO ENSURE FLUTTER FINDS THE FILES ---

// 1. For APK
tasks.register("copyReleaseApk") {
    doLast {
        val apkFile = file("${project.buildDir}/outputs/apk/release/app-release.apk")
        val repoRoot = project.rootProject.projectDir
        val destDir = file("${repoRoot}/build/app/outputs/flutter-apk/")
        
        if (apkFile.exists()) {
            destDir.mkdirs()
            copy {
                from(apkFile)
                into(destDir)
            }
        }
    }
}

// 2. For App Bundle (AAB) - ADDED THIS FIX
tasks.register("copyReleaseAab") {
    doLast {
        val aabFile = file("${project.buildDir}/outputs/bundle/release/app-release.aab")
        val repoRoot = project.rootProject.projectDir
        val destDir = file("${repoRoot}/build/app/outputs/bundle/release/")
        
        if (aabFile.exists()) {
            destDir.mkdirs()
            copy {
                from(aabFile)
                into(destDir)
            }
        }
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    finalizedBy("copyReleaseApk")
}

// Attach the new AAB fix to the bundle task
tasks.matching { it.name == "bundleRelease" }.configureEach {
    finalizedBy("copyReleaseAab")
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
}2