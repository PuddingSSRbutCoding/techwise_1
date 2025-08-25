# วิธีการ Build และทดสอบการแก้ไขปัญหาสีของ Header

## การ Build แอป

### 1. ตรวจสอบ Dependencies
```bash
cd techwisever1
flutter pub get
```

### 2. Build สำหรับ Android
```bash
# Build APK
flutter build apk --release

# หรือใช้ script ที่มีอยู่
./build_apk.sh
# หรือ
build_apk.bat
```

### 3. Build สำหรับ iOS
```bash
# Build สำหรับ iOS Simulator
flutter build ios --simulator

# Build สำหรับ iOS Device
flutter build ios
```

## การทดสอบ

### 1. ทดสอบบน Emulator/Simulator
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### 2. ทดสอบบน Device จริง
- เชื่อมต่อมือถือผ่าน USB
- เปิด Developer Options และ USB Debugging
- รันคำสั่ง `flutter devices` เพื่อดูรายการอุปกรณ์
- รันคำสั่ง `flutter run -d <device_id>`

## สิ่งที่ต้องทดสอบ

### ✅ การแยกสีของ Header และ Taskbar
1. **Status Bar (ด้านบน)**
   - ควรมีสีโปร่งใส (transparent)
   - ไอคอนควรเป็นสีดำ
   - ไม่ควรทับกับ AppBar

2. **AppBar**
   - ควรมีสีขาวพร้อมเงา
   - ข้อความ "TechWise" ควรเป็นสีน้ำเงิน
   - ควรมี elevation ที่เหมาะสม

3. **Navigation Bar (ด้านล่าง)**
   - ควรมีสีขาว
   - ไอคอนควรเป็นสีดำ
   - ไม่ควรทับกับ BottomNavigationBar

4. **BottomNavigationBar**
   - ควรมีสีขาวพร้อมเงา
   - ไอคอนที่เลือกควรเป็นสีน้ำเงิน
   - ไอคอนที่ไม่ได้เลือกควรเป็นสีเทา

### ✅ SafeArea และ Padding
1. **ด้านบน**: เนื้อหาควรไม่ทับกับ status bar
2. **ด้านล่าง**: เนื้อหาควรไม่ทับกับ navigation bar
3. **ด้านข้าง**: ควรมี padding ที่เหมาะสม

### ✅ Theme และสี
1. สีควรสอดคล้องกันทั้งแอป
2. ควรใช้ Material 3 design
3. สีควรเหมาะสมสำหรับการอ่าน

## การแก้ไขปัญหาที่อาจเกิดขึ้น

### ปัญหา: สียังทับกัน
**วิธีแก้**: ตรวจสอบว่า `UIConstants.systemUiOverlayStyle` ถูกเรียกใช้ใน `main()`

### ปัญหา: AppBar ไม่แสดงผล
**วิธีแก้**: ตรวจสอบว่า `UIConstants.appBarTheme` ถูกใช้ใน theme

### ปัญหา: SafeArea ไม่ทำงาน
**วิธีแก้**: ตรวจสอบว่า `SafeArea` ถูกใช้ในหน้าต่างๆ

### ปัญหา: สีไม่สอดคล้องกัน
**วิธีแก้**: ตรวจสอบว่าใช้ `UIConstants` ในทุกไฟล์

## การตรวจสอบ Logs

### Android
```bash
adb logcat | grep flutter
```

### iOS
```bash
# ดู logs ใน Xcode Console
```

## การทดสอบบนมือถือหลายๆ รุ่น

### Android
- Samsung Galaxy (S series, A series)
- Google Pixel
- OnePlus
- Xiaomi
- Huawei

### iOS
- iPhone (various models)
- iPad (various models)

## การตรวจสอบ Performance

### 1. ตรวจสอบ Frame Rate
```bash
flutter run --profile
```

### 2. ตรวจสอบ Memory Usage
```bash
flutter run --profile --trace-startup
```

### 3. ตรวจสอบ Build Size
```bash
flutter build apk --analyze-size
```

## การ Deploy

### 1. Android
- อัปโหลด APK ไปยัง Google Play Console
- หรือแจกจ่ายผ่าน APK โดยตรง

### 2. iOS
- อัปโหลดไปยัง App Store Connect
- หรือใช้ TestFlight สำหรับการทดสอบ

## หมายเหตุสำคัญ

1. **Material 3**: แอปใช้ Material 3 design ซึ่งรองรับ Android 12+ และ iOS 15+
2. **Backward Compatibility**: แอปควรทำงานได้บน Android API 21+ และ iOS 12+
3. **Accessibility**: สีและ contrast ควรเหมาะสมสำหรับผู้ใช้ที่มีปัญหาการมองเห็น
4. **Dark Mode**: แอปรองรับ light mode เป็นหลัก แต่สามารถเพิ่ม dark mode ได้ในอนาคต

## การบำรุงรักษา

### 1. อัปเดต Dependencies
```bash
flutter pub upgrade
```

### 2. ตรวจสอบ Flutter Version
```bash
flutter --version
```

### 3. Clean Build
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## การรายงานปัญหา

หากพบปัญหาในการ build หรือทดสอบ กรุณารายงานพร้อม:
1. Flutter version
2. OS version
3. Device model
4. Error message
5. Steps to reproduce
6. Screenshots (ถ้ามี)
