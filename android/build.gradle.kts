import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory to avoid deep nested paths on Windows
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
        val project = this
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as BaseExtension
            android.compileSdkVersion(35)
            android.buildToolsVersion("35.0.0")
            
            android.defaultConfig {
                minSdk = 24
                targetSdk = 35
            }

            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = "17"
        }
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
            if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                useVersion("1.13.1")
            }
            if (requested.group == "androidx.activity" && (requested.name == "activity" || requested.name == "activity-ktx")) {
                useVersion("1.8.2")
            }
            if (requested.group == "androidx.fragment" && (requested.name == "fragment" || requested.name == "fragment-ktx")) {
                useVersion("1.7.0")
            }
            if (requested.group == "androidx.lifecycle" && requested.name.startsWith("lifecycle-")) {
                useVersion("2.7.0")
            }
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}