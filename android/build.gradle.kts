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

// Pin Java AND Kotlin to JVM 17 for every module with lazy configureEach
// and NO afterEvaluate. The pre-existing evaluationDependsOn(":app") above
// means some subprojects are already evaluated by the time this block runs,
// and calling afterEvaluate on an evaluated project throws
// "Cannot run Project.afterEvaluate when the project is already evaluated"
// (run #21, build.gradle.kts line 33). configureEach applies at
// task-realization time, which is safe regardless of evaluation state and
// runs after AGP's own setup, so this target wins. Run #19 failed on
// :audio_session (17 vs 11), run #20 on :file_picker (11 vs 1.8); a uniform
// 17/17 pin fixes every plugin at once.
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
