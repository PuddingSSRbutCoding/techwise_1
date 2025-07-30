# การทดสอบแอปผ่าน Local Network (ไม่ต้องใช้ USB)

## วิธีที่ 1: ใช้ ADB over Network

### ขั้นตอนที่ 1: เปิดใช้งาน Network Debugging

#### สำหรับ Android:
1. เปิด **Developer Options**
   - ไปที่ Settings > About Phone
   - แตะ Build Number 7 ครั้ง
   - กลับไปที่ Settings > Developer Options

2. เปิด **Network Debugging**
   - เปิด Developer Options
   - เปิด USB Debugging
   - เปิด "Wireless debugging" หรือ "Network debugging"

3. ดู IP Address
   - ไปที่ Settings > Developer Options > Wireless debugging
   - ดู IP address และ port (เช่น 192.168.1.100:5555)

#### สำหรับ iOS:
1. เปิด **Developer Mode**
   - ไปที่ Settings > Privacy & Security
   - เปิด Developer Mode
   - รีสตาร์ทอุปกรณ์

2. เชื่อมต่อผ่าน WiFi
   - ใช้ Xcode > Window > Devices and Simulators
   - เชื่อมต่อผ่าน WiFi

### ขั้นตอนที่ 2: เชื่อมต่อผ่าน Network

```bash
# เชื่อมต่อผ่าน IP address
adb connect <IP_ADDRESS>:5555

# ตัวอย่าง
adb connect 192.168.1.100:5555

# ตรวจสอบการเชื่อมต่อ
adb devices

# ควรเห็นอุปกรณ์ในรายการ
# 192.168.1.100:5555    device
```

### ขั้นตอนที่ 3: Run แอป

```bash
# ตรวจสอบอุปกรณ์ที่เชื่อมต่อ
flutter devices

# Run แอป
flutter run

# หรือ build และ install
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## วิธีที่ 2: ใช้ Web Version

### ขั้นตอนที่ 1: Build Web Version

```bash
# Build web version
flutter build web

# หรือ run web version
flutter run -d web-server --web-port 8080
```

### ขั้นตอนที่ 2: Serve Web App

#### ใช้ Python:
```bash
# ไปที่โฟลเดอร์ build/web
cd build/web

# Serve ด้วย Python
python -m http.server 8080

# หรือใช้ Python 3
python3 -m http.server 8080
```

#### ใช้ Node.js:
```bash
# ติดตั้ง serve
npm install -g serve

# Serve web app
serve build/web -p 8080
```

#### ใช้ PHP:
```bash
# ไปที่โฟลเดอร์ build/web
cd build/web

# Serve ด้วย PHP
php -S localhost:8080
```

### ขั้นตอนที่ 3: เข้าถึงผ่านมือถือ

1. **ดู IP Address ของคอมพิวเตอร์**
   ```bash
   # Windows
   ipconfig
   
   # macOS/Linux
   ifconfig
   # หรือ
   ip addr show
   ```

2. **เปิดเบราว์เซอร์ในมือถือ**
   - ไปที่ `http://<IP_ADDRESS>:8080`
   - ตัวอย่าง: `http://192.168.1.50:8080`

3. **เพิ่มเป็น Home Screen (PWA)**
   - เปิดเมนูในเบราว์เซอร์
   - เลือก "Add to Home Screen"
   - แอปจะปรากฏเหมือน native app

---

## วิธีที่ 3: ใช้ QR Code

### ขั้นตอนที่ 1: สร้าง QR Code

```bash
# ติดตั้ง qrcode-generator
pip install qrcode[pil]

# สร้าง QR Code สำหรับ URL
python -c "
import qrcode
url = 'http://192.168.1.50:8080'
qr = qrcode.QRCode(version=1, box_size=10, border=5)
qr.add_data(url)
qr.make(fit=True)
img = qr.make_image(fill_color='black', back_color='white')
img.save('techwise_qr.png')
print('QR Code created: techwise_qr.png')
"
```

### ขั้นตอนที่ 2: แชร์ QR Code

1. แสดง QR Code บนหน้าจอคอมพิวเตอร์
2. สแกนด้วยมือถือ
3. เปิดลิงก์ที่ได้

---

## วิธีที่ 4: ใช้ ngrok (สำหรับทดสอบจากภายนอก)

### ขั้นตอนที่ 1: ติดตั้ง ngrok

```bash
# ดาวน์โหลด ngrok
# ไปที่ https://ngrok.com/download

# หรือใช้ npm
npm install -g ngrok
```

### ขั้นตอนที่ 2: Serve Web App

```bash
# Serve web app
flutter run -d web-server --web-port 8080

# หรือ build และ serve
flutter build web
cd build/web
python -m http.server 8080
```

### ขั้นตอนที่ 3: เปิด ngrok

```bash
# เปิด ngrok tunnel
ngrok http 8080

# จะได้ URL เช่น https://abc123.ngrok.io
```

### ขั้นตอนที่ 4: แชร์ URL

- แชร์ URL ที่ได้จาก ngrok
- ทุกคนสามารถเข้าถึงได้จากที่ไหนก็ได้
- เหมาะสำหรับการทดสอบกับคนอื่น

---

## การแก้ไขปัญหา

### ปัญหา ADB Connection

```bash
# ลบการเชื่อมต่อเก่า
adb disconnect

# เชื่อมต่อใหม่
adb connect <IP_ADDRESS>:5555

# ตรวจสอบ
adb devices
```

### ปัญหา Network

```bash
# ตรวจสอบ Firewall
# Windows: เปิด Windows Defender Firewall
# macOS: เปิด System Preferences > Security & Privacy > Firewall

# ตรวจสอบ Port
netstat -an | grep 8080
```

### ปัญหา Web App

```bash
# ล้าง cache
flutter clean
flutter pub get

# Build ใหม่
flutter build web

# ตรวจสอบไฟล์
ls -la build/web/
```

---

## คำแนะนำเพิ่มเติม

### การตั้งค่า Security

1. **สำหรับ Local Network:**
   - ใช้ WiFi ที่ปลอดภัย
   - ตรวจสอบ Firewall settings
   - ใช้ VPN หากจำเป็น

2. **สำหรับ Production:**
   - ใช้ HTTPS
   - ตั้งค่า CORS
   - ใช้ Authentication

### การ Monitor Performance

```bash
# ดู logs แบบ real-time
flutter logs

# หรือใช้ adb
adb logcat

# ดู performance
flutter run --profile
```

### การทดสอบฟีเจอร์

1. **Login/Logout**
2. **Navigation**
3. **Data Loading**
4. **Offline Mode**
5. **Performance**
6. **UI/UX**

---

## สรุป

วิธีที่แนะนำสำหรับการทดสอบโดยไม่ใช้ USB:

1. **Local Network + ADB** - สำหรับ Android
2. **Web Version + Local Server** - สำหรับทุก platform
3. **ngrok** - สำหรับการแชร์กับคนอื่น
4. **QR Code** - สำหรับการเข้าถึงที่ง่าย

เลือกวิธีที่เหมาะสมกับความต้องการของคุณ! 