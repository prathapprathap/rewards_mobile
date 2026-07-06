allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
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
    val configureAndroid: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null && android is com.android.build.gradle.BaseExtension) {
            if (android.namespace.isNullOrEmpty()) {
                val groupName = project.group.toString()
                android.namespace = if (groupName.isNotEmpty()) groupName else "com.library.${project.name.replace(":", "").replace("-", "")}"
            }
            try {
                android.compileSdkVersion(36)
            } catch (e: Exception) {}
            try {
                android.compileOptions.sourceCompatibility = JavaVersion.VERSION_11
                android.compileOptions.targetCompatibility = JavaVersion.VERSION_11
            } catch (e: Exception) {}
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "11"
            targetCompatibility = "11"
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "11"
            }
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
