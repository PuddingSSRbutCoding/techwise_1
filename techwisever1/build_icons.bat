@echo off
echo 🔄 กำลังสร้างไอคอนใหม่สำหรับแอป...

REM ลบไอคอนเก่า
echo 🗑️  ลบไอคอนเก่า...
if exist "android\app\src\main\res\mipmap-*" rmdir /s /q "android\app\src\main\res\mipmap-*"
if exist "android\app\src\main\res\drawable\ic_launcher_foreground.xml" del "android\app\src\main\res\drawable\ic_launcher_foreground.xml"

REM สร้างไอคอนใหม่
echo 🎨 สร้างไอคอนใหม่...
flutter pub get
flutter pub run flutter_launcher_icons:main

echo ✅ สร้างไอคอนเสร็จสิ้น!
echo 📱 ตอนนี้ไอคอนจะแสดงผลชัดเจนและไม่มีอะไรมาบัง
echo 🔄 รันแอปใหม่เพื่อดูผลลัพธ์
pause
