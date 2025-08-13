# Google Sign-In Troubleshooting Guide

## Common Error: ApiException 10 (API_NOT_AVAILABLE)

This error typically occurs due to configuration mismatches between your app and Firebase Console.

### ✅ Solution Steps

#### 1. Verify SHA-1 Fingerprint Match

**Problem**: SHA-1 fingerprint in `google-services.json` doesn't match your debug keystore.

**Check your debug keystore SHA-1**:
```bash
# Windows PowerShell
keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Current Debug SHA-1**: `89:E6:F6:9F:24:B5:3C:E2:CB:88:91:BD:8F:C9:E5:01:B8:58:C9:47`

**Fix**: Update `android/app/google-services.json` with the correct certificate hash (without colons):
```json
"certificate_hash": "89E6F69F24B53CE2CB8891BD8FC9E501B858C947"
```

#### 2. Verify Package Name Consistency

Ensure these match across all configurations:
- `android/app/build.gradle.kts`: `applicationId = "com.example.techwisever1"`
- `android/app/src/main/AndroidManifest.xml`: `package="com.example.techwisever1"`
- `google-services.json`: `"package_name": "com.example.techwisever1"`
- Firebase Console project settings

#### 3. Firebase Console Configuration

In Firebase Console → Authentication → Sign-in method → Google:

1. **Enable Google Sign-in**
2. **Add SHA-1 fingerprint**: `89:E6:F6:9F:24:B5:3C:E2:CB:88:91:BD:8F:C9:E5:01:B8:58:C9:47`
3. **Verify Web client ID** is configured
4. **Download updated google-services.json** after making changes

#### 4. Verify Web Client Configuration

Your current web client ID: `517912732365-h40nu5f5oebar3c68supsaal73g86imn.apps.googleusercontent.com`

Ensure this matches in:
- `lib/services/google_auth_service.dart` (serverClientId)
- Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration

#### 5. Clean and Rebuild

After configuration changes:
```bash
cd techwisever1
flutter clean
flutter pub get
flutter build apk --debug
```

### 🔍 Debug Information

**Project ID**: `techwisever1`
**Package Name**: `com.example.techwisever1`
**App ID**: `1:517912732365:android:858105dd796a6c2121bf84`

### 📝 Common Issues Checklist

- [x] SHA-1 fingerprint matches between keystore and Firebase Console ✅ FIXED
- [x] Package name is consistent across all configurations ✅ VERIFIED
- [ ] Google Sign-in is enabled in Firebase Console
- [x] Web client ID is properly configured ✅ VERIFIED
- [x] google-services.json is up to date ✅ UPDATED
- [ ] App has been cleaned and rebuilt after configuration changes

### ⚠️ Important Notes

1. **Debug vs Release**: Currently using debug signing for both debug and release builds. For production, create a proper release keystore and update Firebase Console with the release SHA-1.

2. **Web Client ID**: Must be from Firebase Console → Project Settings → General → Web apps section, not the Android client ID.

3. **Cache Issues**: If problems persist, try:
   - Uninstall app from device/emulator
   - Clear Flutter cache: `flutter clean`
   - Clear Google Sign-In cache in app settings

### 🚀 Testing

After fixing configuration:
1. Uninstall the app from your device/emulator
2. Run `flutter clean && flutter pub get`
3. Build and install: `flutter run`
4. Test Google Sign-In functionality

---

**Last Updated**: January 2025
**Debug SHA-1**: `89:E6:F6:9F:24:B5:3C:E2:CB:88:91:BD:8F:C9:E5:01:B8:58:C9:47`

