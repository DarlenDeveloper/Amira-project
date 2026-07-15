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

// FlutterFire plugins (firebase_core, cloud_firestore, firebase_auth, etc.) ship
// a local-config.gradle that hardcodes compileSdk=34. This machine's android-34
// platform is missing android.jar, so those plugins fail to compile. Force every
// Android subproject to compile against SDK 36 (fully installed, and compileSdk
// is backward compatible per Flutter's own guidance).
subprojects {
    val forceCompileSdk36: Project.() -> Unit = {
        val androidExt = extensions.findByName("android")
        if (androidExt is com.android.build.gradle.BaseExtension) {
            androidExt.compileSdkVersion(36)
        }
    }
    if (state.executed) {
        forceCompileSdk36()
    } else {
        afterEvaluate { forceCompileSdk36() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
