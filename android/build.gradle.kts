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
// fails just like 17 vs 11 did). Layer (2) runs in afterEvaluate, but the
// pre-existing evaluationDependsOn(":app") means some subprojects are
// already evaluated when this block runs, and calling afterEvaluate on an
// evaluated project throws (run #21, line 33). So afterEvaluate is guarded
// with project.state.executed (public Gradle API, issue #9395): if already
// evaluated, apply directly; otherwise register afterEvaluate.
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
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
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
