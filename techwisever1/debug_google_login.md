# Google Login Debug Guide

## การตรวจสอบปัญหา Google Login แบบทีละขั้นตอน

### 🔍 ขั้นตอนการ Debug

#### 1. ตรวจสอบ Debug Logs
เมื่อเกิดปัญหา Google Login ให้ดู console logs ใน VS Code หรือ Android Studio:

```bash
flutter run --verbose
```

ให้ความสำคัญกับ error messages เหล่านี้:
- `ApiException: 10` (API_NOT_AVAILABLE)
- `PlatformException`
- `network_error`
- `sign_in_failed`

#### 2. ตรวจสอบการตั้งค่าพื้นฐาน

**✅ Package Name Consistency:**
- `android/app/build.gradle.kts`: `applicationId = "com.example.techwisever1"`
- `android/app/src/main/AndroidManifest.xml`: `package="com.example.techwisever1"`
- `google-services.json`: `"package_name": "com.example.techwisever1"`

**✅ SHA-1 Fingerprint:**
```bash
# ตรวจสอบ SHA-1 ปัจจุบัน
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"
```

Current SHA-1: `89:E6:F6:9F:24:B5:3C:E2:CB:88:91:BD:8F:C9:E5:01:B8:58:C9:47`

#### 3. ปัญหาที่พบบ่อยและวิธีแก้ไข

**🚨 ApiException: 10 (API_NOT_AVAILABLE)**
```
สาเหตุ: Google Play Services API ไม่พร้อมใช้งาน
แก้ไข:
1. ตรวจสอบ SHA-1 fingerprint ใน Firebase Console
2. อัปเดต Google Play Services บนอุปกรณ์
3. ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
4. Clean และ rebuild project
```

**🚨 Network Error**
```
สาเหตุ: ปัญหาการเชื่อมต่อเครือข่าย
แก้ไข:
1. ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
2. ลองใช้ WiFi หรือ Mobile Data อื่น
3. ตรวจสอบ Firewall/Proxy settings
```

**🚨 Configuration Error**
```
สาเหตุ: การตั้งค่า Firebase/Google ไม่ถูกต้อง
แก้ไข:
1. ดาวน์โหลด google-services.json ใหม่จาก Firebase Console
2. ตรวจสอบ Web Client ID ใน GoogleAuthService
3. เปิดใช้ Google Sign-in ใน Firebase Console
```

#### 4. ขั้นตอนการแก้ไขแบบเป็นระบบ

**Step 1: Clean Project**
```bash
flutter clean
flutter pub get
```

**Step 2: ตรวจสอบ Firebase Console**
1. เข้า Firebase Console → Authentication → Sign-in method
2. ตรวจสอบว่า Google provider เปิดใช้งานแล้ว
3. ตรวจสอบ SHA-1 fingerprint ใน Project Settings

**Step 3: ตรวจสอบ google-services.json**
```json
{
  "oauth_client": [
    {
      "client_type": 1,  // Android client
      "certificate_hash": "89E6F69F24B53CE2CB8891BD8FC9E501B858C947"
    },
    {
      "client_type": 3   // Web client (สำคัญสำหรับ Google Sign-In)
    }
  ]
}
```

**Step 4: ทดสอบใหม่**
```bash
flutter run
```

#### 5. การตรวจสอบเพิ่มเติม

**Debug Mode vs Release Mode:**
- ปัจจุบันใช้ debug signing สำหรับทั้ง debug และ release
- สำหรับ production ต้องสร้าง release keystore และอัปเดต Firebase

**Google Play Services:**
- ตรวจสอบว่าอุปกรณ์มี Google Play Services ติดตั้งและเป็นเวอร์ชันล่าสุด
- บน emulator ต้องใช้ Google Play Store image

**การทดสอบบนอุปกรณ์จริง:**
- ลองทดสอบบนอุปกรณ์จริงแทน emulator
- ตรวจสอบว่าอุปกรณ์ login Google account แล้ว

### 📞 การขอความช่วยเหลือ

เมื่อรายงานปัญหา กรุณาแจ้ง:
1. Error message ที่แน่นอนจาก console
2. อุปกรณ์ที่ใช้ทดสอบ (จริง/emulator)
3. ขั้นตอนที่ทำแล้ว
4. ผลลัพธ์ที่ได้

---

**สร้างเมื่อ:** {วันที่ปัจจุบัน}
**Current Configuration:**
- Project ID: techwisever1
- Package: com.example.techwisever1  
- SHA-1: 89:E6:F6:9F:24:B5:3C:E2:CB:88:91:BD:8F:C9:E5:01:B8:58:C9:47
