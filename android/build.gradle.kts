plugins {
    id("com.android.application") version "8.6.0" apply false
    id("com.android.library") version "8.6.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Prevent Jetify from processing incompatible byte-buddy classes
    configurations.all {
        exclude(group = "net.bytebuddy", module = "byte-buddy")
        resolutionStrategy.force("net.bytebuddy:byte-buddy:1.18.4")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}