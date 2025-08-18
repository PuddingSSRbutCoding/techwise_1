@echo off
echo ========================================
echo Building TechWise APK v1.0.2+3
echo ========================================

echo.
echo Cleaning previous builds...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Building APK...
flutter build apk --release

echo.
echo ========================================
echo Build completed!
echo APK location: build/app/outputs/flutter-apk/app-release.apk
echo ========================================

pause


