import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 출시 서명 키 — android/key.properties (git 제외)가 저장소 밖의 업로드 키스토어를 가리킨다.
// 만드는 법: ppangkal-frontend/tool/create_release_key.ps1, 절차는 RELEASE.md.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "com.ppangkal.ppangkal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 스토어 등록 후에는 절대 바꾸지 않는다 — 바꾸면 다른 앱으로 취급된다.
        applicationId = "com.ppangkal.ppangkal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // 키가 없는 PC에서도 `flutter run --release`로 성능 확인은 할 수 있게 디버그 키로 서명한다.
                // 이 결과물은 스토어에 올리면 안 된다 — tool/build_store_release.ps1이 서명을 검사해 막는다.
                logger.warn("⚠ android/key.properties 없음: release 빌드를 디버그 키로 서명합니다 (스토어 업로드 불가)")
                signingConfig = signingConfigs.getByName("debug")
            }
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
