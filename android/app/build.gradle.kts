import java.util.Base64

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.set_point"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Necesario para resValue (color de marca del ícono y la pantalla de carga).
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.set_point"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Color del ícono y de la pantalla de carga: el mismo SP_BRAND que
        // usa la app (--dart-define=SP_BRAND=RRGGBB). Sin él, azul.
        resValue("color", "brand_color", "#FF${brandColorHex()}")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

/**
 * Lee SP_BRAND de los --dart-define (Flutter los pasa a Gradle en base64,
 * separados por comas). Acepta RRGGBB, #RRGGBB o 0xFFRRGGBB.
 */
fun brandColorHex(): String {
    val defines = (project.findProperty("dart-defines") as String?) ?: ""
    val raw = defines.split(",")
        .filter { it.isNotBlank() }
        .map { String(Base64.getDecoder().decode(it)) }
        .firstOrNull { it.startsWith("SP_BRAND=") }
        ?.substringAfter("=")
        ?.trim()
        ?.removePrefix("#")
        ?.removePrefix("0x")
        ?.removePrefix("0X")
        ?: ""
    val rgb = if (raw.length == 8) raw.substring(2) else raw
    return if (Regex("^[0-9a-fA-F]{6}$").matches(rgb)) rgb.uppercase() else "3449E8"
}
