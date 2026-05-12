import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'managers/preferences_manager.dart';

void main() async {
  // Flutter interfeysini bog'lash (async ishlar uchun kerak)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Xotira boshqaruvini (PreferencesManager)initializatsiya qilish
  // Ilova boshlanishida sozlamalarni va tarixni yuklash uchun kerak.
  await PreferencesManager.init();

  // 2. Ilovani ishga tushirish
  runApp(const AnNaimDictionaryApp());
}

class AnNaimDictionaryApp extends StatelessWidget {
  const AnNaimDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'An-Na’im al-Kubro',
      debugShowCheckedModeBanner: false, // Debug barini yashirish
      home: HomeScreen(), // Boshlang'ich ekran
    );
  }
}
/* dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.0 # (yoki undan yangi versiyasi)*/
  /*
  Albatta, qo'shimcha sozlamalar kerak bo'ladi. Flutter'da `shared_preferences` kabi kutubxonalar ishlatilganda va loyiha professional darajaga ko'tarilganda, Android qismidagi `build.gradle` fayllariga bir nechta muhim o'zgartirishlar kiritiladi.

Siz so'ragan `XML` (Manifest) va `build.gradle` (KTS yoki Groovy) uchun kerakli barcha qo'shimchalarni quyida keltiraman.

### 1. Android Manifest (`android/app/src/main/AndroidManifest.xml`)

Lug'at ilovasi uchun internet shart bo'lmasa-da, ko'p funksiyalar va kelajakda ovozli qidiruv yoki yangilanishlar uchun ruxsatnomalar kerak bo'ladi.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="An-Na'im al-Kubro"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            ... >
            </activity>
    </application>
</manifest>

```

---

### 2. App darajasidagi `build.gradle` (`android/app/build.gradle`)

Agar sizda **KTS** (Kotlin Script) bo'lsa, quyidagi o'zgarishlarni kiritishingiz kerak. Bu yerda asosan `minSdkVersion` (minimal Android versiyasi) va `multiDex` (kod ko'payib ketsa xato bermasligi uchun) sozlanadi.

```kotlin
android {
    namespace = "uz.yourname.annaim" // O'zingizning paket nomingiz
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "uz.yourname.annaim"
        
        // shared_preferences va zamonaviy kutubxonalar uchun kamida 21 bo'lishi tavsiya etiladi
        minSdk = 21 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // Agar so'zlar soni va kutubxonalar ko'payib ketsa, bu ruxsat kerak bo'ladi
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Ilovani kichraytirish va himoyalash (Obfuscation)
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // MultiDex uchun qo'shimcha (agar kerak bo'lsa)
    implementation("androidx.multidex:multidex:2.0.1")
}

```

---

### 3. Proyekt darajasidagi `build.gradle` (`android/build.gradle`)

Bu yerda Kotlin va Gradle plugin versiyalari lug'at ilovasidagi yangi kutubxonalarga mos bo'lishi kerak.

```kotlin
// Plugins qismida versiyalarni tekshiring
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("com.android.library") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

```

---

### 4. Proyektning `pubspec.yaml` fayliga muhim qo'shimcha

Ilovangizda arabcha so'zlar chiroyli chiqishi uchun o'zingiz tanlagan shriftingiz (masalan, `Traditional Arabic`) bo'lishi shart. Uni quyidagicha qo'shasiz:

```yaml
flutter:
  uses-material-design: true

  # Arabcha shriftni ilovaga bog'lash
  fonts:
    - family: Traditional Arabic
      fonts:
        - asset: assets/fonts/trado.ttf # Shrift fayli manzili

```

### Muhim tushuntirish (Comentariy):

* **minSdkVersion 21:** Bu Android 5.0 dan yuqori barcha telefonlarda ishlashini ta'minlaydi. Hozirgi kutubxonalarning ko'pi 19 yoki 21 dan pastini qo'llab-quvvatlamaydi.
* **multiDexEnabled true:** Ilovada so'zlar (500 ta tarix, 1000 ta so'z va h.k.) va kod hajmi oshganda Android'ning 64k metod limitidan oshib ketish xavfi bor, bu sozlama o'sha xatoni oldini oladi.
* **isMinifyEnabled:** Release (tayyor ilova) versiyada buni `true` qilsangiz, kodingizni begonalardan himoya qiladi (kodni o'qib bo'lmaydigan qilib chalkashtiradi).

Ushbu sozlamalarni kiritganingizdan so'ng, terminalda `flutter clean` va keyin `flutter pub get` buyruqlarini berishni unutmang. Shunda barcha o'zgarishlar kuchga kiradi.*/