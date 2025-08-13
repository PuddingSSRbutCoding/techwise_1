# Google Sign-In Setup Instructions

## สิ่งที่ต้องทำเพื่อแก้ไขปัญหา Google Login

### 1. เพิ่ม Web OAuth Client ใน Firebase Console

1. ไปที่ [Firebase Console](https://console.firebase.google.com/)
2. เลือกโปรเจค `techwisever1`
3. ไปที่ **Authentication** > **Sign-in method**
4. เลือก **Google**
5. คลิก **Web SDK configuration**
6. คัดลอก **Web client ID** ที่มีรูปแบบ `517912732365-xxxxxxxxxx.apps.googleusercontent.com`

### 2. อัพเดท google-services.json

เปิดไฟล์ `android/app/google-services.json` และเปลี่ยน:

```json
"client_id": "517912732365-your-web-client-id.apps.googleusercontent.com"
```

เป็น Web client ID จริงที่คัดลอกมาจากขั้นตอนที่ 1

### 3. อัพเดท GoogleAuthService

เปิดไฟล์ `lib/services/google_auth_service.dart` และเปลี่ยน:

```dart
serverClientId: '517912732365-your-web-client-id.apps.googleusercontent.com'
```

เป็น Web client ID จริงเดียวกัน

### 4. การตรวจสอบ

หลังจากทำการแก้ไขแล้ว:

1. ทำ clean build: `flutter clean && flutter pub get`
2. Build แอพใหม่: `flutter run`
3. ทดสอบ Google Sign-In
4. ทดสอบการสลับบัญชี

### ปัญหาที่แก้ไขแล้ว

✅ **Loading ค้างหลังสลับบัญชี**: แก้ไขด้วยการปรับปรุง state management และ dialog handling

✅ **Google Login Configuration**: เพิ่ม web OAuth client configuration

✅ **Error Handling**: ปรับปรุงการจัดการ error และแสดงข้อความที่เข้าใจง่าย

✅ **Navigation Issues**: แก้ไขปัญหา navigation stack และ AuthGuard

✅ **Performance Optimization**: 
- ลดเวลา delay จาก 500ms เหลือ 50-100ms
- เพิ่ม timeout สำหรับ network operations
- ใช้ cached Google user เพื่อเร่งการ login
- Parallel Firebase initialization
- ปรับปรุง AuthGuard ให้ใช้ initialData

✅ **Loading Speed Improvements**:
- AuthGuard init time: 500ms → 50ms (90% faster)
- Google Sign-in: ใช้ cached user เมื่อเป็นไปได้
- Firebase init: ทำแบบ parallel กับ App loading
- Added comprehensive timeouts

### หมายเหตุ

- Web client ID จำเป็นสำหรับ Google Sign-In บน Android
- หาก certificate hash เปลี่ยน ต้องอัพเดทใน Firebase Console
- สำหรับ production ควรใช้ release keystore แยกจาก debug keystore
