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
    val configureAndroid: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val setCompileSdk = android::class.java.getMethod("setCompileSdk", Integer.TYPE)
                setCompileSdk.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    val setCompileSdkVersion = android::class.java.getMethod("setCompileSdkVersion", Integer.TYPE)
                    setCompileSdkVersion.invoke(android, 36)
                } catch (ee: Exception) {}
            }
            try {
                val getNamespace = android::class.java.getMethod("getNamespace")
                val namespaceValue = getNamespace.invoke(android)
                if (namespaceValue == null) {
                    val setNamespace = android::class.java.getMethod("setNamespace", String::class.java)
                    
                    // Try to read package name from AndroidManifest.xml
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    var pkg: String? = null
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val match = Regex("""package=["']([^"']+)["']""").find(content)
                        pkg = match?.groupValues?.get(1)
                    }
                    
                    if (pkg == null || pkg.isEmpty()) {
                        val namePart = project.name.replace("-", "_").replace(":", "_")
                        pkg = "com.example.memoryos.$namePart"
                    }
                    
                    setNamespace.invoke(android, pkg)
                }
            } catch (e: Exception) {
                // Safe ignore
            }
        }
    }
    
    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
