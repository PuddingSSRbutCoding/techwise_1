# ฟีเจอร์การเลือกบัญชี Google

## ภาพรวม
แอปพลิเคชัน TechWise ได้เพิ่มฟีเจอร์การเลือกบัญชี Google เพื่อให้ผู้ใช้สามารถเลือกบัญชี Google ที่ต้องการใช้ในการเข้าสู่ระบบได้

## ฟีเจอร์ที่เพิ่มเข้ามา

### 1. การเลือกบัญชี Google ในการเข้าสู่ระบบ
- เมื่อผู้ใช้คลิกปุ่ม "เข้าสู่ระบบด้วย Google" ระบบจะแสดงตัวเลือกบัญชี Google
- หากมีบัญชีที่ login อยู่แล้ว ระบบจะแสดงตัวเลือกให้เลือกบัญชี
- หากไม่มีบัญชีที่ login อยู่ ระบบจะให้ sign in ใหม่

### 2. การเปลี่ยนบัญชี Google ในหน้า Profile
- เพิ่มปุ่ม "เปลี่ยนบัญชี Google" ในหน้า Profile
- ปุ่มนี้จะแสดงเฉพาะเมื่อผู้ใช้ login ด้วย Google
- เมื่อคลิกปุ่มนี้ ระบบจะออกจากบัญชีปัจจุบันและให้เลือกบัญชีใหม่

### 3. GoogleAuthService
สร้าง service class สำหรับจัดการ Google Sign-In ที่มีฟังก์ชัน:
- `signInWithGoogle()` - เข้าสู่ระบบด้วย Google พร้อมตัวเลือกบัญชี
- `switchGoogleAccount()` - เปลี่ยนบัญชี Google
- `signOut()` - ออกจากระบบ Google
- `isGoogleUser()` - ตรวจสอบว่าผู้ใช้ login ด้วย Google หรือไม่
- `getCurrentGoogleUser()` - รับข้อมูลบัญชี Google ปัจจุบัน

## การใช้งาน

### สำหรับผู้ใช้
1. **การเข้าสู่ระบบด้วย Google**
   - เปิดแอปและไปที่หน้า Welcome
   - คลิกปุ่ม "เข้าสู่ระบบด้วย Google"
   - เลือกบัญชี Google ที่ต้องการใช้
   - ระบบจะเข้าสู่ระบบด้วยบัญชีที่เลือก

2. **การเปลี่ยนบัญชี Google**
   - ไปที่หน้า Profile
   - คลิกปุ่ม "เปลี่ยนบัญชี Google" (แสดงเฉพาะเมื่อ login ด้วย Google)
   - เลือกบัญชี Google ใหม่
   - ระบบจะเปลี่ยนไปใช้บัญชีใหม่

### สำหรับนักพัฒนา
```dart
// การใช้งาน GoogleAuthService
import '../services/google_auth_service.dart';

// เข้าสู่ระบบด้วย Google
final userCredential = await GoogleAuthService.signInWithGoogle();

// เปลี่ยนบัญชี Google
final userCredential = await GoogleAuthService.switchGoogleAccount();

// ออกจากระบบ
await GoogleAuthService.signOut();

// ตรวจสอบว่าผู้ใช้ login ด้วย Google หรือไม่
bool isGoogleUser = GoogleAuthService.isGoogleUser(FirebaseAuth.instance.currentUser);
```

## การตั้งค่า

### Android
ไฟล์ `android/app/google-services.json` ต้องมีการตั้งค่า Google Sign-In ที่ถูกต้อง

### iOS
ไฟล์ `ios/Runner/Info.plist` ต้องมีการตั้งค่า URL schemes สำหรับ Google Sign-In

## การแก้ไขปัญหา

### ปัญหาที่พบบ่อย
1. **ไม่แสดงตัวเลือกบัญชี**
   - ตรวจสอบการตั้งค่า Google Sign-In ใน Firebase Console
   - ตรวจสอบไฟล์ google-services.json

2. **ไม่สามารถเปลี่ยนบัญชีได้**
   - ตรวจสอบว่าผู้ใช้ login ด้วย Google หรือไม่
   - ตรวจสอบการตั้งค่า OAuth 2.0

3. **เกิดข้อผิดพลาดในการ sign in**
   - ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
   - ตรวจสอบการตั้งค่า Firebase

## หมายเหตุ
- ฟีเจอร์นี้ทำงานเฉพาะกับบัญชี Google เท่านั้น
- ต้องมีการตั้งค่า Firebase และ Google Sign-In ที่ถูกต้อง
- การเลือกบัญชีจะทำงานได้ดีที่สุดเมื่อมีบัญชี Google หลายบัญชีในอุปกรณ์ 