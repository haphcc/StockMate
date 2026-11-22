allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val localBuildDir = providers.environmentVariable("STOCKMATE_ANDROID_BUILD_DIR").orNull
val newBuildDir: Directory = if (localBuildDir.isNullOrBlank()) {
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
} else {
    rootProject.layout.dir(rootProject.provider { rootProject.file(localBuildDir) }).get()
}
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
