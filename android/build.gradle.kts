allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. flutter_timezone, home_widget, sign_in_with_apple) declare
// their own Java/Kotlin compile options (often Java 8) in their own build
// scripts. Those run AFTER any pluginManager.withPlugin hook here, so the only
// reliable way to force every subproject to Java 17 — matching the app and
// keeping Kotlin/Java JVM targets consistent — is to override in afterEvaluate,
// once each plugin has finished configuring itself.
subprojects {
    // Always align the Kotlin JVM target.
    fun Project.alignCompileTasks() {
        tasks.withType(org.gradle.api.tasks.compile.JavaCompile::class.java).configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                // sentry_flutter 8.14.2 pins Kotlin languageVersion 1.6 in its
                // own build script; Kotlin 2.3 rejects anything below 2.0
                // outright ("Language version 1.6 is no longer supported").
                // Force the oldest still-supported version everywhere, same
                // afterEvaluate rationale as the Java level above.
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            }
        }
    }
    // The authoritative fix is the android extension's compileOptions — AGP
    // derives each compile task's Java level from it. Plugins like home_widget
    // set theirs to Java 8 in their own build script, so we must override it
    // AFTER they evaluate. :app is force-evaluated early by the
    // evaluationDependsOn above and already targets 17, so for it we only touch
    // tasks (its extension is finalized and would throw if set again).
    if (state.executed) {
        alignCompileTasks()
    } else {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
                // Some plugins (e.g. geocoding_android) pin an old compileSdk
                // (33) whose AndroidX deps now demand a newer one. Force
                // every plugin module up to 36 so AAR metadata checks pass
                // (package_info_plus 9.x compiles against 36 and requires
                // dependents to match — a clamp of 35 fails its check).
                if (compileSdkVersion == null ||
                    (compileSdkVersion?.substringAfter("android-")?.toIntOrNull() ?: 0) < 36
                ) {
                    compileSdkVersion(36)
                }
                // sweph pins NDK 21, whose linker aligns ELF segments for
                // 4 KB pages only — Play rejects that ("app does not support
                // 16 KB memory page sizes") and 16 KB-kernel devices would
                // crash loading libsweph.so. NDK r28+ aligns for 16 KB by
                // default, so force every plugin's native build onto it.
                // NDK 28 in turn refuses sweph's minSdk 16 ([CXX1110]), and
                // sweph's C sources need fseeko/ftello, which bionic only
                // declares from API 24 — clamp plugin minSdk to 24. Safe:
                // the app's own minSdk IS 24 (flutter.minSdkVersion), so no
                // older device can install; the merged manifest still uses
                // the app's minSdk, this only affects plugin compilation.
                ndkVersion = "28.2.13676358"
                if ((defaultConfig.minSdkVersion?.apiLevel ?: 0) < 24) {
                    defaultConfig.minSdkVersion(24)
                }
            }
            alignCompileTasks()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
