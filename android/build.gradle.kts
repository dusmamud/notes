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

// Pin Java AND Kotlin to JVM 17 for every module, AFTER each plugin's own
// build script has been evaluated. Without afterEvaluate, a plugin's own
// compileOptions (e.g. file_picker: Java 11 / Kotlin 1.8, audio_session:
// Java 17 / Kotlin 11) overrides a plain configureEach block and Gradle
// fails with "Inconsistent JVM-target compatibility detected".
// Run #19 failed on :audio_session (17 vs 11), run #20 on :file_picker
// (11 vs 1.8); a uniform 17/17 pin fixes every plugin at once.
subprojects {
    afterEvaluate {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
