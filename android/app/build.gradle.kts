plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.yourwish.shougakukore.sansu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val storePasswordEnv = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            val keyPasswordEnv = System.getenv("ANDROID_KEY_PASSWORD")
            val keyFile = file("${project.projectDir}/key.jks")

            // Use actual values if provided, otherwise use dummy values for unsigned builds
            storeFile = keyFile
            storePassword = storePasswordEnv ?: "unsigned"
            keyAlias = "key"
            keyPassword = keyPasswordEnv ?: "unsigned"
        }
    }

    defaultConfig {
        applicationId = "com.yourwish.shougakukore.sansu"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Only apply signing config if secrets are available
            val hasSigningSecrets = !System.getenv("ANDROID_KEYSTORE_PASSWORD").isNullOrEmpty() &&
                    !System.getenv("ANDROID_KEY_PASSWORD").isNullOrEmpty() &&
                    file("${project.projectDir}/key.jks").exists()
            if (hasSigningSecrets) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
