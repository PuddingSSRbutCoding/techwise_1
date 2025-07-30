# 🔧 การแก้ไขปัญหา Google Sign-In

## 🚨 ปัญหาที่พบ
```
Google Sign-In Error: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

## ✅ การแก้ไขที่ทำแล้ว

### 1. **แก้ไข SHA-1 Fingerprint**
- **SHA-1 เดิม:** `89e6f69f24b53ce2cb8891bd8fc9e501b858c947`
- **SHA-1 ใหม่:** `BD4433F5C8E8445FC75C02DFDE8594881B15F725`

### 2. **อัปเดต google-services.json**
ไฟล์ `android/app/google-services.json` ได้รับการอัปเดตแล้ว

## 🔧 การตั้งค่าเพิ่มเติมที่ต้องทำ

### 1. **Firebase Console**
1. ไปที่ [Firebase Console](https://console.firebase.google.com/)
2. เลือกโปรเจค `techwisever1`
3. ไปที่ **Authentication** > **Sign-in method**
4. เปิดใช้งาน **Google** Sign-in
5. เพิ่ม SHA-1 fingerprint ใหม่ใน **Android configuration**

### 2. **Google Cloud Console**
1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เลือกโปรเจค `techwisever1`
3. ไปที่ **APIs & Services** > **Credentials**
4. แก้ไข OAuth 2.0 Client ID สำหรับ Android
5. เพิ่ม SHA-1 fingerprint ใหม่

### 3. **การทดสอบ**
```bash
# Clean และ rebuild
flutter clean
flutter pub get
flutter run
```

## 📋 ตรวจสอบรายการ

- [x] แก้ไข SHA-1 fingerprint ใน google-services.json
- [ ] อัปเดต Firebase Console
- [ ] อัปเดต Google Cloud Console
- [ ] ทดสอบ Google Sign-In

## 🛠️ คำสั่งที่มีประโยชน์

### ตรวจสอบ SHA-1 fingerprint
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Clean และ rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## 📞 หากยังมีปัญหา

1. **ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต**
2. **ตรวจสอบการตั้งค่า Firebase**
3. **ตรวจสอบ Google Play Services บนอุปกรณ์**
4. **ลองใช้ Google Sign-In ในโหมด debug**

## 🔍 การแก้ไขปัญหาอื่นๆ

### ปัญหา: "Google Sign-In not configured"
- ตรวจสอบ google-services.json อยู่ในตำแหน่งที่ถูกต้อง
- ตรวจสอบการตั้งค่าใน Firebase Console

### ปัญหา: "Network error"
- ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
- ตรวจสอบ Firewall settings

### ปัญหา: "Invalid client"
- ตรวจสอบ OAuth 2.0 Client ID
- ตรวจสอบ Package name ตรงกัน 