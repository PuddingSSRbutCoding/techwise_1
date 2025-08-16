# 📚 TechWise - แอปเรียนรู้เทคโนโลยี

[![Flutter Version](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

แอปเรียนรู้เทคโนโลยีสำหรับนักเรียนที่ต้องการเรียนรู้เกี่ยวกับอิเล็กทรอนิกส์และเทคนิคคอมพิวเตอร์ พร้อมระบบทดสอบความรู้และติดตามความก้าวหน้า

## 🎯 ภาพรวมของแอป

**TechWise** เป็นแอปการเรียนรู้ที่ออกแบบมาเพื่อให้นักเรียนสามารถเรียนรู้เทคโนโลยีได้อย่างเป็นระบบ ประกอบด้วย:

### 🎓 วิชาที่สอน
- **อิเล็กทรอนิกส์** (Electronics)
  - บทที่ 1: อุปกรณ์อิเล็กทรอนิกส์เบื้องต้น
  - บทที่ 2: อุปกรณ์ในงานไฟฟ้า
  - บทที่ 3: เนื้อหาขั้นสูง

- **เทคนิคคอมพิวเตอร์** (Computer Technology)
  - บทที่ 1: ความรู้พื้นฐานคอมพิวเตอร์
  - บทที่ 2: เครื่องมือพัฒนา
  - บทที่ 3: เนื้อหาขั้นสูง

### ✨ ฟีเจอร์หลัก
- 🔐 **ระบบการเข้าสู่ระบบ** - Google Sign-In และ Email/Password
- 📖 **เนื้อหาบทเรียน** - เรียนรู้แบบขั้นบันได
- 🧭 **แผนที่บทเรียน** - ติดตามความก้าวหน้าได้ชัดเจน
- 🧠 **ระบบทดสอบ** - แบบทดสอบหลากหลายรูปแบบ
- 👤 **โปรไฟล์ผู้ใช้** - จัดการข้อมูลส่วนตัว
- 📊 **ระบบแอดมิน** - จัดการผู้ใช้และเนื้อหา
- 🛠️ **ระบบป้องกันข้อผิดพลาด** - Crash handling และ Performance monitoring

## 🚀 การติดตั้งและรันแอป

### ✅ ความต้องการของระบบ

#### สำหรับ Development:
- **Flutter SDK** >= 3.8.1
- **Dart SDK** >= 3.0.0
- **Android Studio** หรือ **VS Code** พร้อม Flutter extension
- **Firebase CLI** สำหรับจัดการ Firebase
- **Git** สำหรับ version control

#### สำหรับ Android:
- **Android SDK** >= 21 (Android 5.0)
- **Google Play Services** อัปเดทล่าสุด

#### สำหรับ iOS:
- **iOS** >= 12.0
- **Xcode** >= 14.0 (สำหรับ macOS)

### 📱 การติดตั้ง

#### 1. Clone โปรเจค
```bash
git clone [repository-url]
cd pordog/techwisever1
```

#### 2. ติดตั้ง Dependencies
```bash
flutter clean
flutter pub get
```

#### 3. ตั้งค่า Firebase

**a) ติดตั้ง Firebase CLI:**
```bash
npm install -g firebase-tools
firebase login
```

**b) เชื่อมต่อกับ Firebase Project:**
```bash
flutterfire configure
```

**c) ตรวจสอบไฟล์ Firebase:**
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

#### 4. รันแอป

**สำหรับ Android:**
```bash
flutter run
```

**สำหรับ iOS:**
```bash
flutter run -d ios
```

**สำหรับ Web:**
```bash
flutter run -d web
```

### 🔧 สคริปต์สำหรับรันแอป

**Windows:**
```bash
./run_app.bat
```

**Linux/macOS:**
```bash
./local_test.sh
```

## 📁 โครงสร้างโปรเจค

```
techwisever1/
├── lib/
│   ├── auth/                    # ระบบการเข้าสู่ระบบ
│   │   └── auth_guard.dart      # ตรวจสอบสถานะการล็อกอิน
│   ├── login/                   # หน้าจอล็อกอิน
│   │   ├── welcome_page.dart    # หน้าต้อนรับ
│   │   ├── login_page1.dart     # ล็อกอินด้วยอีเมล
│   │   └── beforein.dart        # สมัครสมาชิก
│   ├── main_screen.dart         # หน้าจอหลัก
│   ├── models/                  # Data models
│   │   └── user_model.dart      # โมเดลผู้ใช้
│   ├── profile/                 # ระบบโปรไฟล์
│   │   ├── profile_page.dart    # หน้าโปรไฟล์
│   │   ├── admin_dashboard_page.dart  # แดชบอร์ดแอดมิน
│   │   └── user_management_page.dart  # จัดการผู้ใช้
│   ├── question/                # ระบบทดสอบ
│   │   ├── question_model.dart  # โมเดลคำถาม
│   │   ├── question_page.dart   # หน้าทำแบบทดสอบ
│   │   └── question_service.dart # เซอร์วิสคำถาม
│   ├── services/                # Backend services
│   │   ├── auth_utils.dart      # ยูทิลิตี้การเข้าสู่ระบบ
│   │   ├── google_auth_service.dart # Google Sign-In
│   │   ├── user_service.dart    # จัดการข้อมูลผู้ใช้
│   │   ├── crash_handler.dart   # จัดการข้อผิดพลาด
│   │   ├── performance_monitor.dart # ติดตามประสิทธิภาพ
│   │   ├── network_utils.dart   # ยูทิลิตี้เครือข่าย
│   │   ├── validation_utils.dart # ตรวจสอบข้อมูล
│   │   └── app_state_service.dart # จัดการสถานะแอป
│   ├── subject/                 # ระบบเนื้อหาเรียน
│   │   ├── select_subject_page.dart    # เลือกวิชา
│   │   ├── electronics_page.dart       # วิชาอิเล็กทรอนิกส์
│   │   ├── computertech_page.dart      # วิชาเทคนิคคอมพิวเตอร์
│   │   ├── lesson_intro.dart           # แนะนำบทเรียน
│   │   ├── lesson_map_page.dart        # แผนที่บทเรียน
│   │   ├── lesson_word.dart            # เนื้อหาบทเรียน
│   │   └── subject_card.dart           # การ์ดวิชา
│   └── main.dart                # Entry point
├── assets/
│   ├── images/                  # รูปภาพทั้งหมด
│   └── icon/                    # ไอคอนแอป
├── android/                     # Android configuration
├── ios/                         # iOS configuration
├── web/                         # Web configuration
└── pubspec.yaml                 # Dependencies
```

### 🧩 คอมโพเนนต์สำคัญ

#### 🔐 Authentication System
```dart
// Google Sign-In
GoogleAuthService.signInWithGoogle()

// Email/Password
AuthUtils.signInWithEmail()
AuthUtils.registerWithEmail()

// Auth Guard - ตรวจสอบสถานะล็อกอิน
AuthGuard() // ใน main.dart
```

#### 📚 Learning Management
```dart
// เลือกวิชา
SelectSubjectPage()

// แผนที่บทเรียน  
LessonMapPage(subject: 'electronics', lesson: 1)

// เนื้อหาบทเรียน
LessonWordPage(subject: 'computer', lesson: 1, stage: 2)
```

#### 🧠 Question System
```dart
// หน้าทำแบบทดสอบ
QuestionTC1Page(
  docId: 'questioncomputer1',
  lesson: 1,
  stage: 1,
)

// เซอร์วิสจัดการคำถาม
QuestionService.fetchByLessonStage()
```

## 🚨 Troubleshooting

### 🔧 ปัญหาที่พบบ่อย

#### 1. **Google Sign-In ไม่ทำงาน**
```bash
# ตรวจสอบ SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
```

**Error: ApiException 10**
- ✅ ตรวจสอบ `google-services.json` ใน `android/app/`
- ✅ ตรวจสอบ SHA-1 fingerprint ใน Firebase Console
- ✅ ตรวจสอบ package name ให้ตรงกันทุกที่

#### 2. **App Crashes**
```dart
// ตรวจสอบ logs ใน terminal
flutter logs

// หรือใช้ crash handler
await CrashHandler.handleRecovery();
```

#### 3. **Build Issues**
```bash
# ลบ build cache
flutter clean
rm -rf .dart_tool/
flutter pub get

# สำหรับ Android
cd android && ./gradlew clean && cd ..
```

### 📚 เอกสารการแก้ไขที่มีอยู่

1. **[CRASH_FIXES.md](CRASH_FIXES.md)** - การแก้ไข app crashes และ stability
2. **[LOGIN_FIXES_COMPLETE.md](LOGIN_FIXES_COMPLETE.md)** - การแก้ไขปัญหา login ทั้งหมด
3. **[GOOGLE_SIGNIN_FIX.md](GOOGLE_SIGNIN_FIX.md)** - การแก้ไข Google Sign-In API Exception 10
4. **[USER_MANAGEMENT_SYSTEM.md](USER_MANAGEMENT_SYSTEM.md)** - ระบบจัดการผู้ใช้
5. **[SYSTEM_IMPROVEMENTS.md](SYSTEM_IMPROVEMENTS.md)** - การปรับปรุงระบบ

## 🔄 การอัปเดตและ Maintenance

### 📅 Regular Tasks

#### รายสัปดาห์:
- [ ] ตรวจสอบ dependencies อัปเดท
- [ ] รัน test suite ทั้งหมด
- [ ] ตรวจสอบ crash reports
- [ ] อัปเดต documentation

#### รายเดือน:
- [ ] อัปเดต Flutter/Dart version
- [ ] ตรวจสอบ security vulnerabilities
- [ ] ล้างข้อมูล test users
- [ ] Backup Firebase data

### 🚀 Deployment Process

#### 1. **Pre-deployment Checklist**
- [ ] ทดสอบบนอุปกรณ์จริง (Android + iOS)
- [ ] ตรวจสอบ performance
- [ ] ล้างข้อมูล debug
- [ ] อัปเดต version ใน `pubspec.yaml`

#### 2. **Build Release**
```bash
# Android APK
flutter build apk --release

# Android App Bundle (สำหรับ Play Store)
flutter build appbundle --release

# iOS (ต้องมี macOS + Xcode)
flutter build ios --release
```

## 👥 การทำงานเป็นทีม

### 🔀 Git Workflow

#### Branch Strategy:
```
main              # Production-ready code
├── develop       # Development branch  
├── feature/xxx   # Feature branches
├── hotfix/xxx    # Emergency fixes
└── release/xxx   # Release preparation
```

#### Commit Messages:
```
feat: เพิ่มระบบทดสอบใหม่
fix: แก้ไข Google Sign-In error
docs: อัปเดต README
style: ปรับ UI ของหน้า login
refactor: ปรับโครงสร้าง question service
test: เพิ่ม unit tests สำหรับ auth
```

### 👨‍💻 Developer Onboarding

#### สำหรับนักพัฒนาใหม่:

1. **Setup Environment** (วัน 1)
   - ติดตั้ง Flutter SDK
   - ติดตั้ง IDE (VS Code/Android Studio)
   - ตั้งค่า Firebase CLI
   - Clone และรันโปรเจค

2. **Learn Codebase** (วัน 2-3)
   - อ่าน README.md (ไฟล์นี้)
   - ทำความเข้าใจ project structure
   - รันและทดสอบแอป
   - อ่าน troubleshooting guides

3. **First Task** (วัน 4-5)
   - แก้ไข bugs เล็กๆ
   - เพิ่ม features ง่ายๆ
   - เขียน unit tests
   - Code review process

## 🎉 สรุป

**TechWise** เป็นแอปการเรียนรู้ที่ครบครันและมีความเสถียรสูง พร้อมสำหรับการพัฒนาต่อและการใช้งานจริง 

### ✅ สิ่งที่พร้อมแล้ว:
- ระบบ authentication ที่แข็งแกร่ง
- เนื้อหาการเรียนรู้ที่เป็นระบบ
- ระบบทดสอบที่ครอบคลุม
- การจัดการผู้ใช้แบบ admin
- ระบบป้องกันและแก้ไขข้อผิดพลาด
- Documentation ที่ครบถ้วน

### 🚀 พร้อมสำหรับ:
- การพัฒนา features ใหม่
- การใช้งานกับผู้ใช้จริง
- การขยายเนื้อหาการเรียนรู้
- การปรับปรุงประสบการณ์ผู้ใช้

**Happy Coding! 🎯**

---

**Created**: 2024  
**Version**: 3.0.0  
**Status**: ✅ Production Ready  
**Last Updated**: 2024
