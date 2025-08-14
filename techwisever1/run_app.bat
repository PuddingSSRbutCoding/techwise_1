@echo off
echo กำลังรันแอป TechWise...
echo.

echo [1/3] กำลังอัปเดต dependencies...
flutter pub get
echo.

echo [2/3] กำลัง build แอป...
flutter clean
echo.

echo [3/3] กำลังเปิดแอป...
flutter run

