#!/bin/bash

echo "🔄 กำลังสร้างไอคอนใหม่สำหรับแอป..."

# ลบไอคอนเก่า
echo "🗑️  ลบไอคอนเก่า..."
rm -rf android/app/src/main/res/mipmap-*
rm -rf android/app/src/main/res/drawable/ic_launcher_foreground.xml

# สร้างไอคอนใหม่
echo "🎨 สร้างไอคอนใหม่..."
flutter pub get
flutter pub run flutter_launcher_icons:main

echo "✅ สร้างไอคอนเสร็จสิ้น!"
echo "📱 ตอนนี้ไอคอนจะแสดงผลชัดเจนและไม่มีอะไรมาบัง"
echo "🔄 รันแอปใหม่เพื่อดูผลลัพธ์"
