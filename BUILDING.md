# Building the Android release APK

This project requires a reproducible Android build configuration. Follow these steps to build a release APK reliably.

## Requirements
- JDK 17 installed (path example: `C:\Program Files\Java\jdk-17`).
- Flutter SDK (as used by this repo).
- Android SDK and build-tools installed (as shown by `flutter doctor`).

## Recommended `android/gradle.properties` settings (already applied)
- `org.gradle.java.home=C:\\Program Files\\Java\\jdk-17`  # Ensures Gradle/JDK 17 is used
- `org.gradle.jvmargs=-Xmx3072M -Dfile.encoding=UTF-8 -XX:+UseParallelGC -XX:ReservedCodeCacheSize=512m`  # Give D8/R8 enough heap to avoid OOM
- `org.gradle.workers.max=1`  # Reduces parallel memory pressure
- `android.useAndroidX=true`
- `android.enableJetifier=false`  # Disabled because the project uses AndroidX

## Build commands
- For normal release (shrinking enabled — recommended for production):

```
flutter clean
flutter build apk --release
```

Note: Shrinking (R8) requires more JVM heap for Gradle. Ensure `org.gradle.jvmargs` in `android/gradle.properties` is increased (e.g., `-Xmx3072M`).

- For low-memory environments (skip shrinking):

```
flutter clean
flutter build apk --release --no-shrink
```

## Why these changes were required
- Jetifier previously failed while processing `byte-buddy` with: `Unsupported class file major version 68`. We disabled Jetifier and forced/excluded a safe `byte-buddy` version so Jetifier no longer encounters incompatible class files.
- The R8/D8 dex merging step caused `OutOfMemoryError` on the local machine. Increasing Gradle JVM heap and reducing worker parallelism prevents the Gradle daemon from crashing.

## Notes for CI
- Ensure the CI runner has >=3GB available for the Gradle daemon when running with shrinking enabled, or use `--no-shrink` to avoid high memory usage.
- Document `org.gradle.java.home` in CI environment configuration if the runner's default JDK differs.

If you'd like, I can add a GitHub Actions workflow that uses these settings and builds the release automatically. Let me know and I can scaffold it.
