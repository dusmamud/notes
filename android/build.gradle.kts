import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

// Pin Java AND Kotlin to JVM 17 for every module. Two layers are needed:
// (1) lazy configureEach for the Java/Kotlin tasks, and (2) the plugin's
// own android.compileOptions extension set to 17. Run #22 proved layer (1)
// alone is NOT enough: Kotlin moved from 1.8 to 17 for :file_picker, but
// its Java stayed at 11 because AGP re-applies Java from the plugin's own
// compileOptions, and Gradle fails on ANY Java/Kotlin mismatch (11 vs 17
// fails just like 17 vs 11 did). Run #23 proved layer (2) must NOT touch
// :app: its compileOptions are already 17 in its own build script and are
// finalized by the Flutter plugin, so setting them again throws
// "sourceCompatibility has been finalized" at build.gradle.kts line 52.
// :app is therefore excluded; only library plugins get the extension pin.
// afterEvaluate is guarded with project.state.executed (public Gradle API,
// issue #9395): if already evaluated, apply directly; otherwise register
// afterEvaluate.
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
    val setJava17FromExtension: Project.() -> Unit = {
        if (project.name != "app") {
            val androidExt = extensions.findByName("android")
            if (androidExt is com.android.build.gradle.BaseExtension) {
                androidExt.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
    if (project.state.executed) {
        setJava17FromExtension()
    } else {
        afterEvaluate { setJava17FromExtension() }
    }
    // Run #30 fix: :objectbox_flutter_libs 4.1.0 hardcodes compileSdkVersion 31
    // in its own android/build.gradle, but its transitive AndroidX deps
    // (fragment 1.7.1, window 1.2.0, lifecycle 2.7.0, core 1.13.1, ...) require
    // compileSdk 34+, so :objectbox_flutter_libs:checkReleaseAarMetadata fails
    // with 20 issues. Upgrading objectbox to 5.x is NOT a one-line fix: it
    // forces objectbox_generator 5.x, which needs build >= 4 / analyzer >= 8 /
    // source_gen 4, conflicting with build_runner 2.4.13, and 5.x requires a
    // build_runner regeneration (generatorVersion) even though this app never
    // opens an ObjectBox Store (storage is SharedPreferences JSON). So pin
    // only this library's compileSdk to 36, matching the app's Flutter 3.44
    // compileSdk, using the same guarded afterEvaluate pattern as the JVM pin
    // above. This changes no targetSdk, minSdk, feature, or Dart code.
    // Run #31 fix: the BaseExtension fallback in this block broke the whole build
    // script. Under AGP 9.0.1 (android.newDsl=true) BaseExtension is
    // deprecated and its Kotlin compileSdkVersion is a String?, so assigning
    // the Int 36 failed script compilation with 3 errors (lines 53, 83, 85)
    // before any task ran. The android extension under AGP 9 is a
    // CommonExtension, whose compileSdk is an Int?, so only that branch is
    // kept. The Java 17 pin above is untouched: it compiled in runs 22-30.
    val setObjectboxCompileSdk36: Project.() -> Unit = {
        if (project.name == "objectbox_flutter_libs") {
            val androidExt = extensions.findByName("android")
            if (androidExt is com.android.build.api.dsl.CommonExtension) {
                androidExt.compileSdk = 36
            }
        }
    }
    if (project.state.executed) {
        setObjectboxCompileSdk36()
    } else {
        afterEvaluate { setObjectboxCompileSdk36() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
