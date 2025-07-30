#!/bin/bash

# สคริปต์สำหรับ Build และ Deploy แอป TechWise
# ใช้งาน: ./build_and_deploy.sh [android|web|all]

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

# ตรวจสอบ Flutter
check_flutter() {
    print_status "ตรวจสอบ Flutter installation..."
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter ไม่ได้ติดตั้ง กรุณาติดตั้ง Flutter ก่อน"
        exit 1
    fi
    print_success "Flutter พร้อมใช้งาน"
}

# ตรวจสอบ Dependencies
check_dependencies() {
    print_status "ตรวจสอบ dependencies..."
    flutter pub get
    print_success "Dependencies อัปเดตเสร็จสิ้น"
}

# Build Android APK
build_android() {
    print_status "เริ่ม build Android APK..."
    
    # สร้างโฟลเดอร์สำหรับเก็บ APK
    mkdir -p builds/android
    
    # Build APK
    flutter build apk --release
    
    # คัดลอก APK ไปยังโฟลเดอร์ builds
    cp build/app/outputs/flutter-apk/app-release.apk builds/android/techwise-release.apk
    
    print_success "Android APK สร้างเสร็จสิ้น: builds/android/techwise-release.apk"
}

# Build Web
build_web() {
    print_status "เริ่ม build Web version..."
    
    # สร้างโฟลเดอร์สำหรับเก็บ Web build
    mkdir -p builds/web
    
    # Build Web
    flutter build web
    
    # คัดลอก Web build ไปยังโฟลเดอร์ builds
    cp -r build/web/* builds/web/
    
    print_success "Web version สร้างเสร็จสิ้น: builds/web/"
}

# สร้างไฟล์ README สำหรับ deployment
create_deployment_readme() {
    cat > builds/README.md << EOF
# TechWise App Builds

## Android APK
- ไฟล์: \`android/techwise-release.apk\`
- ขนาด: \$(du -h builds/android/techwise-release.apk | cut -f1)
- สร้างเมื่อ: \$(date)

## การติดตั้งบนมือถือ

### สำหรับ Android:
1. เปิด "Install from Unknown Sources" ในมือถือ
2. ดาวน์โหลดไฟล์ APK
3. เปิดไฟล์ APK และติดตั้ง

### สำหรับ Web:
1. เปิดเบราว์เซอร์ในมือถือ
2. ไปที่ URL ที่กำหนด
3. เพิ่มเป็น Home Screen (PWA)

## การทดสอบ
- ทดสอบการ Login
- ทดสอบการเลือกวิชา
- ทดสอบการดูบทเรียน
- ทดสอบการทำงานแบบ Offline

## การแก้ไขปัญหา
- หากแอปไม่ติดตั้ง: ตรวจสอบ Android version compatibility
- หากแอปไม่ทำงาน: ตรวจสอบ Firebase configuration
- หากมีปัญหา Network: ตรวจสอบ internet connection
EOF

    print_success "สร้างไฟล์ README สำหรับ deployment"
}

# สร้างไฟล์สำหรับ Firebase App Distribution
create_firebase_config() {
    cat > builds/firebase_distribution.md << EOF
# Firebase App Distribution Setup

## ขั้นตอนการตั้งค่า

### 1. ไปที่ Firebase Console
- เปิด [Firebase Console](https://console.firebase.google.com/)
- เลือกโปรเจค TechWise

### 2. เปิด App Distribution
- ไปที่ App Distribution ในเมนูด้านซ้าย
- คลิก "Get started"

### 3. อัปโหลด APK
- คลิก "Upload APK"
- เลือกไฟล์: \`android/techwise-release.apk\`
- รอการอัปโหลดเสร็จสิ้น

### 4. เพิ่ม Testers
- คลิก "Add testers"
- เพิ่ม email ของ testers
- หรือใช้ Google Groups

### 5. ส่งลิงก์
- Testers จะได้รับ email พร้อมลิงก์ดาวน์โหลด
- หรือใช้ QR Code สำหรับดาวน์โหลด

## การจัดการ Testers
- เพิ่ม/ลบ testers ได้ตลอดเวลา
- ดูสถิติการดาวน์โหลด
- ตรวจสอบ feedback จาก testers

## การอัปเดต
- อัปโหลด APK ใหม่เมื่อมีการอัปเดต
- Testers จะได้รับแจ้งเตือนอัตโนมัติ
- สามารถเปรียบเทียบ version ได้
EOF

    print_success "สร้างไฟล์คู่มือ Firebase App Distribution"
}

# ฟังก์ชันหลัก
main() {
    print_status "เริ่มต้นการ Build และ Deploy แอป TechWise"
    
    # ตรวจสอบ Flutter
    check_flutter
    
    # ตรวจสอบ Dependencies
    check_dependencies
    
    # ตรวจสอบ argument
    if [ $# -eq 0 ]; then
        print_warning "ไม่ระบุ platform ใช้ค่าเริ่มต้น: android"
        PLATFORM="android"
    else
        PLATFORM=$1
    fi
    
    # สร้างโฟลเดอร์ builds
    mkdir -p builds
    
    case $PLATFORM in
        "android")
            build_android
            ;;
        "web")
            build_web
            ;;
        "all")
            build_android
            build_web
            ;;
        *)
            print_error "Platform ไม่ถูกต้อง: $PLATFORM"
            print_status "ใช้งาน: $0 [android|web|all]"
            exit 1
            ;;
    esac
    
    # สร้างไฟล์คู่มือ
    create_deployment_readme
    create_firebase_config
    
    print_success "การ Build และ Deploy เสร็จสิ้น!"
    print_status "ตรวจสอบโฟลเดอร์ builds/ สำหรับไฟล์ที่สร้าง"
    
    # แสดงข้อมูลไฟล์ที่สร้าง
    echo ""
    print_status "ไฟล์ที่สร้าง:"
    ls -la builds/
}

# เรียกใช้ฟังก์ชันหลัก
main "$@" 