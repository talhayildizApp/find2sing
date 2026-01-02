# Find2Sing - Firebase Auth Kurulum Rehberi

## 1. Firebase Projesi Oluşturma

### Firebase Console'da:
1. [Firebase Console](https://console.firebase.google.com/) adresine git
2. "Add project" tıkla
3. Proje adı: `find2sing` (veya istediğin bir isim)
4. Google Analytics'i etkinleştir (opsiyonel)
5. Projeyi oluştur

## 2. Flutter Uygulamasını Firebase'e Bağlama

### FlutterFire CLI Kurulumu:
```bash
# FlutterFire CLI'ı kur
dart pub global activate flutterfire_cli

# Firebase'e giriş yap
firebase login

# Uygulamayı yapılandır (proje dizininde çalıştır)
flutterfire configure --project=find2sing
```

Bu komut otomatik olarak:
- `firebase_options.dart` dosyasını oluşturur
- Android için `google-services.json` ekler
- iOS için `GoogleService-Info.plist` ekler

## 3. Firebase Authentication Ayarları

### Firebase Console > Authentication:
1. "Get started" tıkla
2. "Sign-in method" sekmesine git
3. Şu sağlayıcıları etkinleştir:

#### Email/Password:
- Email/Password: ✅ Enable
- Email link (passwordless sign-in): Opsiyonel

#### Google:
- Google: ✅ Enable
- Project support email: Kendi emailini seç
- Web SDK configuration: Otomatik oluşturulacak

#### Apple (iOS için):
- Apple: ✅ Enable
- Services ID: `com.seninfirma.sarkiapp` (bundle ID ile aynı)
- Apple Developer hesabından Sign in with Apple'ı yapılandır

## 4. Firestore Database Oluşturma

### Firebase Console > Firestore Database:
1. "Create database" tıkla
2. "Start in test mode" seç (geliştirme için)
3. Lokasyon: `europe-west1` (Türkiye'ye yakın)

### Firestore Kuralları (Security Rules):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Kullanıcı kendi verisini okuyabilir/yazabilir
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Submissions collection (eski)
    match /submissions/{docId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
    
    // Challenges collection (yakında)
    match /challenges/{challengeId} {
      allow read: if true; // Herkes görebilir
      allow write: if false; // Sadece admin yazabilir
    }
    
    // User challenge progress
    match /users/{userId}/challengeProgress/{progressId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 5. Android Konfigürasyonu

### `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Firebase için minimum
        // ...
    }
}
```

### `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <!-- Internet izni -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

## 6. iOS Konfigürasyonu

### `ios/Runner/Info.plist` - Google Sign-In için:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Sign in with Apple için:
1. Apple Developer > Certificates, Identifiers & Profiles
2. Identifiers > App ID'ni seç
3. Sign in with Apple'ı etkinleştir
4. Xcode'da Signing & Capabilities > + Sign in with Apple

## 7. Test Etme

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

### Test senaryoları:
1. ✅ Email ile kayıt ol
2. ✅ Email ile giriş yap
3. ✅ Google ile giriş yap
4. ✅ Apple ile giriş yap (iOS)
5. ✅ Şifre sıfırlama
6. ✅ Profil güncelleme
7. ✅ Çıkış yapma

## 8. Sonraki Adımlar

Sıradaki özellikler:
1. **Challenge veri yapısı** - Firestore şeması
2. **Challenge oyun ekranı** - UI
3. **AdMob entegrasyonu** - Reklam
4. **In-App Purchase** - Satın alma

---

## Dosya Yapısı

```
lib/
├── main.dart                          # Uygulama başlangıcı
├── firebase_options.dart              # FlutterFire CLI tarafından oluşturulur
├── models/
│   └── user_model.dart                # Kullanıcı veri modeli
├── providers/
│   └── auth_provider.dart             # Auth state yönetimi
├── services/
│   ├── auth_service.dart              # Firebase Auth işlemleri
│   └── firestore_service.dart         # Firestore işlemleri
└── screens/
    ├── auth/
    │   ├── login_screen.dart          # Giriş ekranı
    │   ├── register_screen.dart       # Kayıt ekranı
    │   ├── forgot_password_screen.dart # Şifre sıfırlama
    │   ├── profile_screen.dart        # Profil ekranı
    │   └── auth_wrapper.dart          # Auth kontrolü
    └── game/
        ├── ... (mevcut oyun ekranları)
```

## Yardım

Sorun yaşarsan:
- Firebase dokümantasyonu: https://firebase.google.com/docs/flutter/setup
- FlutterFire: https://firebase.flutter.dev/
