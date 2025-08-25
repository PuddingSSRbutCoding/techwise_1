import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ค่าคงที่สำหรับ UI ที่ใช้ร่วมกันในแอป
class UIConstants {
  // สีหลักของแอป
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  
  // สีรอง
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color secondaryLightColor = Color(0xFF81C784);
  static const Color secondaryDarkColor = Color(0xFF388E3C);
  
  // สีพื้นหลัง
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  
  // สีข้อความ
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  
  // สีสถานะ
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // สีแยกส่วนจาก taskbar
  static const Color statusBarColor = Colors.transparent;
  static const Color systemNavigationBarColor = Colors.white;
  
  // ขนาดและระยะห่าง
  static const double appBarHeight = 80.0;
  static const double bottomNavHeight = 70.0;
  static const double cardElevation = 4.0;
  static const double buttonElevation = 2.0;
  
  // ระยะห่าง
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // ขนาดตัวอักษร
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  
  // รัศมีมุม
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // เงา
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  
  /// สร้าง SystemUiOverlayStyle สำหรับแยกสีของ status bar และ navigation bar
  static SystemUiOverlayStyle get systemUiOverlayStyle => const SystemUiOverlayStyle(
    // Status bar (ด้านบน)
    statusBarColor: statusBarColor,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    
    // System navigation bar (ด้านล่าง)
    systemNavigationBarColor: systemNavigationBarColor,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  
  /// สร้าง AppBar theme ที่เหมาะสม
  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: surfaceColor,
    foregroundColor: textPrimaryColor,
    elevation: cardElevation,
    shadowColor: const Color(0x1A000000),
    surfaceTintColor: Colors.transparent,
    toolbarHeight: appBarHeight,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: fontSizeXXLarge,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    systemOverlayStyle: systemUiOverlayStyle,
  );
  
  /// สร้าง BottomNavigationBar theme ที่เหมาะสม
  static BottomNavigationBarThemeData get bottomNavigationBarTheme => const BottomNavigationBarThemeData(
    backgroundColor: surfaceColor,
    selectedItemColor: primaryColor,
    unselectedItemColor: textSecondaryColor,
    elevation: 8,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: fontSizeSmall,
    ),
    unselectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: fontSizeSmall,
    ),
  );
  

  
  /// สร้าง Card theme ที่เหมาะสม
  static CardThemeData get cardTheme => CardThemeData(
    color: cardColor,
    elevation: cardElevation,
    shadowColor: const Color(0x1A000000),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
  );
  
  /// สร้าง ElevatedButton theme ที่เหมาะสม
  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: buttonElevation,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
    ),
  );
}
