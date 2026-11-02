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

subprojects {
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext != null) {
            try {
                val method = ext.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(ext, 34)
            } catch (e: Exception) {
                try {
                    val method = ext.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(ext, 34)
                } catch (ignored: Exception) {}
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
