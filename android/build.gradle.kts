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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
