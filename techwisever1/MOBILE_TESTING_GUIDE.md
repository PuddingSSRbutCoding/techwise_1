# คู่มือการทดสอบแอปในมือถือโดยไม่ต้องเชื่อม USB

## วิธีที่ 1: ใช้ Firebase App Distribution (แนะนำ)

### ขั้นตอนที่ 1: เตรียม Firebase Project

1. ไปที่ [Firebase Console](https://console.firebase.google.com/)
2. สร้างโปรเจคใหม่หรือใช้โปรเจคที่มีอยู่
3. เพิ่มแอป Android ในโปรเจค Firebase

### ขั้นตอนที่ 2: ตั้งค่า Firebase ในโปรเจค

1. ดาวน์โหลดไฟล์ `google-services.json` จาก Firebase Console
2. วางไฟล์ใน `android/app/` directory
3. ตรวจสอบว่าไฟล์ `android/build.gradle.kts` มี Google Services plugin:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // เพิ่มบรรทัดนี้
}
```

### ขั้นตอนที่ 3: เพิ่ม Dependencies

เพิ่ม dependencies ใน `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.30.0
  firebase_auth: ^4.17.0
  google_sign_in: ^6.2.1
  firebase_app_check: ^0.2.1+14
```

### ขั้นตอนที่ 4: Build APK

```bash
# Build APK สำหรับ release
flutter build apk --release

# หรือ build APK สำหรับ debug
flutter build apk --debug
```

### ขั้นตอนที่ 5: อัปโหลดไป Firebase App Distribution

1. ไปที่ Firebase Console > App Distribution
2. อัปโหลดไฟล์ APK ที่ได้จาก build
3. เพิ่ม testers โดยใช้ email หรือ Google account
4. Testers จะได้รับลิงก์สำหรับดาวน์โหลดแอป

---

## วิธีที่ 2: ใช้ GitHub Actions (Automated)

### ขั้นตอนที่ 1: สร้าง GitHub Repository

1. สร้าง repository ใหม่บน GitHub
2. Push โค้ดไปยัง repository

### ขั้นตอนที่ 2: สร้าง GitHub Actions Workflow

สร้างไฟล์ `.github/workflows/build-android.yml`:

```yaml
name: Build Android APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.19.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

### ขั้นตอนที่ 3: ดาวน์โหลด APK

1. ไปที่ GitHub repository > Actions
2. เลือก workflow ที่รันเสร็จแล้ว
3. ดาวน์โหลด APK จาก Artifacts

---

## วิธีที่ 3: ใช้ Local Network (สำหรับทดสอบในเครือข่ายเดียวกัน)

### ขั้นตอนที่ 1: เปิดใช้งาน Network Debugging

1. เปิด Developer Options ในมือถือ
2. เปิด USB Debugging และ Network Debugging
3. ดู IP address ของมือถือ

### ขั้นตอนที่ 2: เชื่อมต่อผ่าน Network

```bash
# เชื่อมต่อผ่าน IP address
adb connect <IP_ADDRESS>:5555

# ตรวจสอบการเชื่อมต่อ
adb devices

# Install และ run แอป
flutter run
```

---

## วิธีที่ 4: ใช้ QR Code (สำหรับ Web)

### ขั้นตอนที่ 1: Build Web Version

```bash
flutter build web
```

### ขั้นตอนที่ 2: Serve Web App

```bash
# ใช้ Python
python -m http.server 8000

# หรือใช้ Node.js
npx serve build/web
```

### ขั้นตอนที่ 3: เข้าถึงผ่านมือถือ

1. ดู IP address ของคอมพิวเตอร์
2. เปิดเบราว์เซอร์ในมือถือ
3. ไปที่ `http://<IP_ADDRESS>:8000`

---

## วิธีที่ 5: ใช้ Expo (ถ้าเป็น React Native)

หากต้องการใช้ Expo สำหรับ React Native:

```bash
# Install Expo CLI
npm install -g @expo/cli

# สร้างโปรเจคใหม่
expo init MyApp

# Start development server
expo start

# Scan QR code ด้วย Expo Go app
```

---

## คำแนะนำเพิ่มเติม

### การตั้งค่า Security

1. **สำหรับ Android:**
   - เปิด "Install from Unknown Sources" ในมือถือ
   - อนุญาตการติดตั้งแอปจากแหล่งอื่น

2. **สำหรับ iOS:**
   - ต้องมี Apple Developer Account
   - ใช้ TestFlight หรือ Ad Hoc Distribution

### การจัดการ Dependencies

ตรวจสอบว่าไฟล์ `pubspec.yaml` มี dependencies ที่จำเป็น:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.30.0
  firebase_auth: ^4.17.0
  google_sign_in: ^6.2.1
  # เพิ่ม dependencies อื่นๆ ตามต้องการ
```

### การแก้ไขปัญหา

1. **APK ไม่ติดตั้ง:**
   - ตรวจสอบ Android version compatibility
   - เปิด "Install from Unknown Sources"

2. **แอปไม่ทำงาน:**
   - ตรวจสอบ Firebase configuration
   - ดู logs ใน Android Studio หรือ Firebase Console

3. **Network issues:**
   - ตรวจสอบ firewall settings
   - ใช้ VPN หากจำเป็น

---

## สรุป

วิธีที่แนะนำที่สุดคือ **Firebase App Distribution** เพราะ:
- ง่ายต่อการจัดการ
- มีระบบจัดการ testers
- รองรับการอัปเดตอัตโนมัติ
- มีระบบ crash reporting
- ปลอดภัยและน่าเชื่อถือ 