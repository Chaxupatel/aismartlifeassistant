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
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val clazz = androidExt.javaClass
                val compileSdkVersionMethod = clazz.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkVersionMethod.invoke(androidExt, 36)
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
