#!/bin/bash

# สคริปต์สำหรับการทดสอบแอป TechWise ผ่าน Local Network
# ใช้งาน: ./local_test.sh [web|android|qr|ngrok]

set -e

# สีสำหรับ output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ฟังก์ชันแสดงข้อความ
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ฟังก์ชันดู IP Address
get_ip_address() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows
        ipconfig | grep "IPv4" | head -1 | awk '{print $NF}'
    else
        # macOS/Linux
        if command -v ip &> /dev/null; then
            ip route get 1.1.1.1 | awk '{print $7}' | head -1
        else
            ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
        fi
    fi
}

# ฟังก์ชันตรวจสอบ Port
check_port() {
    local port=$1
    if command -v netstat &> /dev/null; then
        netstat -an | grep ":$port " | grep LISTEN &> /dev/null
    else
        lsof -i :$port &> /dev/null
    fi
}

# ฟังก์ชันทดสอบ Web
test_web() {
    print_status "เริ่มทดสอบ Web version..."
    
    # Build web
    print_status "Building web version..."
    flutter build web
    
    # ดู IP address
    local ip=$(get_ip_address)
    local port=8080
    
    print_status "IP Address: $ip"
    print_status "Port: $port"
    
    # ตรวจสอบ port
    if check_port $port; then
        print_warning "Port $port กำลังใช้งานอยู่"
        read -p "ต้องการใช้ port อื่นหรือไม่? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "ใส่ port ใหม่: " port
        fi
    fi
    
    # Serve web app
    print_status "Starting web server..."
    cd build/web
    python -m http.server $port &
    local server_pid=$!
    
    print_success "Web server เริ่มต้นที่ http://$ip:$port"
    print_status "กด Ctrl+C เพื่อหยุด"
    
    # รอการหยุด
    trap "kill $server_pid 2>/dev/null; exit" INT
    wait
}

# ฟังก์ชันทดสอบ Android
test_android() {
    print_status "เริ่มทดสอบ Android version..."
    
    # ตรวจสอบ ADB
    if ! command -v adb &> /dev/null; then
        print_error "ADB ไม่ได้ติดตั้ง กรุณาติดตั้ง Android SDK"
        exit 1
    fi
    
    # ตรวจสอบอุปกรณ์
    print_status "ตรวจสอบอุปกรณ์ที่เชื่อมต่อ..."
    adb devices
    
    # ถาม IP address ของมือถือ
    read -p "ใส่ IP address ของมือถือ (เช่น 192.168.1.100): " phone_ip
    
    if [ -z "$phone_ip" ]; then
        print_error "กรุณาใส่ IP address"
        exit 1
    fi
    
    # เชื่อมต่อผ่าน network
    print_status "เชื่อมต่อผ่าน network..."
    adb connect $phone_ip:5555
    
    # ตรวจสอบการเชื่อมต่อ
    if adb devices | grep -q "$phone_ip"; then
        print_success "เชื่อมต่อสำเร็จ"
        
        # Run แอป
        print_status "เริ่มรันแอป..."
        flutter run
    else
        print_error "ไม่สามารถเชื่อมต่อได้"
        print_status "ตรวจสอบ:"
        print_status "1. เปิด Developer Options ในมือถือ"
        print_status "2. เปิด USB Debugging"
        print_status "3. เปิด Wireless Debugging"
        print_status "4. ดู IP address ใน Wireless Debugging settings"
    fi
}

# ฟังก์ชันสร้าง QR Code
create_qr() {
    print_status "สร้าง QR Code..."
    
    # ตรวจสอบ Python
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        print_error "Python ไม่ได้ติดตั้ง"
        exit 1
    fi
    
    # ติดตั้ง qrcode
    print_status "ติดตั้ง qrcode library..."
    if command -v pip &> /dev/null; then
        pip install qrcode[pil]
    elif command -v pip3 &> /dev/null; then
        pip3 install qrcode[pil]
    else
        print_error "pip ไม่ได้ติดตั้ง"
        exit 1
    fi
    
    # ดู IP address
    local ip=$(get_ip_address)
    local port=8080
    local url="http://$ip:$port"
    
    print_status "สร้าง QR Code สำหรับ: $url"
    
    # สร้าง QR Code
    python -c "
import qrcode
url = '$url'
qr = qrcode.QRCode(version=1, box_size=10, border=5)
qr.add_data(url)
qr.make(fit=True)
img = qr.make_image(fill_color='black', back_color='white')
img.save('techwise_qr.png')
print('QR Code created: techwise_qr.png')
"
    
    print_success "QR Code สร้างเสร็จ: techwise_qr.png"
    print_status "เปิดไฟล์ techwise_qr.png และสแกนด้วยมือถือ"
}

# ฟังก์ชันทดสอบด้วย ngrok
test_ngrok() {
    print_status "เริ่มทดสอบด้วย ngrok..."
    
    # ตรวจสอบ ngrok
    if ! command -v ngrok &> /dev/null; then
        print_error "ngrok ไม่ได้ติดตั้ง"
        print_status "ติดตั้ง ngrok:"
        print_status "1. ไปที่ https://ngrok.com/download"
        print_status "2. ดาวน์โหลดและติดตั้ง"
        print_status "3. หรือใช้: npm install -g ngrok"
        exit 1
    fi
    
    # Build web
    print_status "Building web version..."
    flutter build web
    
    # Serve web app
    print_status "Starting web server..."
    cd build/web
    python -m http.server 8080 &
    local server_pid=$!
    
    # รอสักครู่
    sleep 2
    
    # เปิด ngrok
    print_status "Opening ngrok tunnel..."
    ngrok http 8080 &
    local ngrok_pid=$!
    
    # รอสักครู่
    sleep 3
    
    print_success "ngrok tunnel เปิดแล้ว"
    print_status "ตรวจสอบ URL ที่: http://localhost:4040"
    print_status "กด Ctrl+C เพื่อหยุด"
    
    # รอการหยุด
    trap "kill $server_pid $ngrok_pid 2>/dev/null; exit" INT
    wait
}

# ฟังก์ชันแสดงเมนู
show_menu() {
    echo ""
    echo "=== TechWise Local Testing Menu ==="
    echo "1. ทดสอบ Web version"
    echo "2. ทดสอบ Android (ADB over Network)"
    echo "3. สร้าง QR Code"
    echo "4. ทดสอบด้วย ngrok"
    echo "5. ออกจากโปรแกรม"
    echo ""
    read -p "เลือกตัวเลือก (1-5): " choice
}

# ฟังก์ชันหลัก
main() {
    print_status "เริ่มต้นการทดสอบแอป TechWise ผ่าน Local Network"
    
    # ตรวจสอบ Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter ไม่ได้ติดตั้ง"
        exit 1
    fi
    
    # ตรวจสอบ argument
    if [ $# -eq 0 ]; then
        show_menu
        case $choice in
            1) test_web ;;
            2) test_android ;;
            3) create_qr ;;
            4) test_ngrok ;;
            5) print_success "ออกจากโปรแกรม"; exit 0 ;;
            *) print_error "ตัวเลือกไม่ถูกต้อง"; exit 1 ;;
        esac
    else
        case $1 in
            "web") test_web ;;
            "android") test_android ;;
            "qr") create_qr ;;
            "ngrok") test_ngrok ;;
            *) 
                print_error "ตัวเลือกไม่ถูกต้อง: $1"
                print_status "ใช้งาน: $0 [web|android|qr|ngrok]"
                exit 1
                ;;
        esac
    fi
}

# เรียกใช้ฟังก์ชันหลัก
main "$@" 