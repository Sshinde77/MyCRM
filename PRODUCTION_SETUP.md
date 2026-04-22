# MyCRM Production Setup Checklist

This project now includes baseline production wiring for:
- Runtime permissions (`camera`, `storage/file access`, `internet`, notification permission)
- Firebase Cloud Messaging (FCM) bootstrap on Android and iOS
- Android release signing via `android/key.properties`

## 1. Firebase + FCM

1. Create a Firebase project and add:
- Android app: `com.example.mycrm` (replace with your final package id first)
- iOS app: your final bundle id

2. Download config files:
- Android: `google-services.json` -> place at `android/app/google-services.json`
- iOS: `GoogleService-Info.plist` -> place at `ios/Runner/GoogleService-Info.plist`

3. Enable Cloud Messaging in Firebase console.

4. For Android, add SHA keys in Firebase project settings:
- Debug SHA-1 (for local testing)
- Release SHA-1 (for production)

Example command (Windows):
```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

If you meant `ssh1`, this usually should be `SHA-1` for Firebase Android app auth.

## 2. Android Production Signing

Create `android/key.properties` (do not commit real secrets):

```properties
storeFile=../keystore/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

Then build release:
```powershell
flutter build appbundle --release
```

## 3. iOS CocoaPods Bootstrap

This repository currently has no `ios/Podfile`. Generate iOS dependencies:
```powershell
flutter build ios --config-only
cd ios
pod install
```

Then open `ios/Runner.xcworkspace` in Xcode and enable:
- Push Notifications capability
- Background Modes -> Remote notifications

## 4. Production Identity

Before publishing, update:
- Android `applicationId` in `android/app/build.gradle.kts`
- Android package path if you rename the id
- iOS `PRODUCT_BUNDLE_IDENTIFIER` in Xcode
- App display names/icons as needed

## 5. Verify Push Token

Run app once and capture token from logs (`PushNotificationService`):
- Send this FCM token to your backend and map it to user/session.
- Use Firebase Console test message to verify foreground/background delivery.
