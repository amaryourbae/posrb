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
    val applyNdkFix = { p: Project ->
        val android = p.extensions.findByName("android")
        if (android != null) {
            try {
                val method = android.javaClass.getMethod("setNdkVersion", String::class.java)
                method.invoke(android, "28.2.13676358")
            } catch (e: Exception) {
                // Ignore if method not found
            }
        }
    }

    if (project.state.executed) {
        applyNdkFix(project)
    } else {
        project.afterEvaluate {
            applyNdkFix(project)
        }
    }
}

subprojects {
    if (name == "move_to_background") {
        val applyNamespaceFix = { p: Project ->
            val androidExt = p.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val namespaceObj = androidExt.javaClass.getMethod("getNamespace").invoke(androidExt)
                    if (namespaceObj == null) {
                        androidExt.javaClass.getMethod("namespace", String::class.java).invoke(androidExt, p.group.toString())
                    }
                } catch (e: Exception) {
                    println("Could not check or set namespace for ${p.name}")
                }
            }
        }

        if (state.executed) {
            applyNamespaceFix(this)
        } else {
            afterEvaluate {
                applyNamespaceFix(this)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
