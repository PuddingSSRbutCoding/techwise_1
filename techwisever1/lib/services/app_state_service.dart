import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service สำหรับจัดการ app state และ error recovery
class AppStateService {
  static const String _lastLoginMethodKey = 'last_login_method';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastErrorKey = 'last_error';
  static const String _appCrashCountKey = 'app_crash_count';
  
  /// บันทึกวิธีการ login ล่าสุด
  static Future<void> saveLastLoginMethod(String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginMethodKey, method);
      debugPrint('✅ Saved last login method: $method');
    } catch (e) {
      debugPrint('❌ Error saving login method: $e');
    }
  }

  /// รับวิธีการ login ล่าสุด
  static Future<String?> getLastLoginMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoginMethodKey);
    } catch (e) {
      debugPrint('❌ Error getting login method: $e');
      return null;
    }
  }

  /// บันทึกจำนวนครั้งที่พยายาม login
  static Future<void> incrementLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attempts = (prefs.getInt(_loginAttemptsKey) ?? 0) + 1;
      await prefs.setInt(_loginAttemptsKey, attempts);
      debugPrint('📊 Login attempts: $attempts');
    } catch (e) {
      debugPrint('❌ Error incrementing login attempts: $e');
    }
  }

  /// รีเซ็ตจำนวนครั้งที่พยายาม login
  static Future<void> resetLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginAttemptsKey);
      debugPrint('🔄 Reset login attempts');
    } catch (e) {
      debugPrint('❌ Error resetting login attempts: $e');
    }
  }

  /// รับจำนวนครั้งที่พยายาม login
  static Future<int> getLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_loginAttemptsKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting login attempts: $e');
      return 0;
    }
  }

  /// บันทึก error ล่าสุด
  static Future<void> saveLastError(String error, String context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorData = {
        'error': error,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_lastErrorKey, jsonEncode(errorData));
      debugPrint('💾 Saved last error: $error in $context');
    } catch (e) {
      debugPrint('❌ Error saving last error: $e');
    }
  }

  /// รับข้อมูล error ล่าสุด
  static Future<Map<String, dynamic>?> getLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorJson = prefs.getString(_lastErrorKey);
      if (errorJson != null) {
        return jsonDecode(errorJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting last error: $e');
      return null;
    }
  }

  /// ล้างข้อมูล error ล่าสุด
  static Future<void> clearLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastErrorKey);
      debugPrint('🧹 Cleared last error');
    } catch (e) {
      debugPrint('❌ Error clearing last error: $e');
    }
  }

  /// บันทึกจำนวนครั้งที่แอป crash
  static Future<void> incrementCrashCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crashes = (prefs.getInt(_appCrashCountKey) ?? 0) + 1;
      await prefs.setInt(_appCrashCountKey, crashes);
      debugPrint('💥 App crash count: $crashes');
    } catch (e) {
      debugPrint('❌ Error incrementing crash count: $e');
    }
  }

  /// รับจำนวนครั้งที่แอป crash
  static Future<int> getCrashCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_appCrashCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting crash count: $e');
      return 0;
    }
  }

  /// รีเซ็ตจำนวนครั้งที่แอป crash
  static Future<void> resetCrashCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appCrashCountKey);
      debugPrint('🔄 Reset crash count');
    } catch (e) {
      debugPrint('❌ Error resetting crash count: $e');
    }
  }

  /// ตรวจสอบว่าควรแสดง recovery options หรือไม่
  static Future<bool> shouldShowRecoveryOptions() async {
    final attempts = await getLoginAttempts();
    final crashes = await getCrashCount();
    
    // แสดง recovery options ถ้า:
    // - มีการพยายาม login มากกว่า 3 ครั้ง
    // - หรือ แอป crash มากกว่า 2 ครั้ง
    return attempts > 3 || crashes > 2;
  }

  /// ล้างข้อมูลทั้งหมดเพื่อ reset state
  static Future<void> clearAllAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastLoginMethodKey);
      await prefs.remove(_loginAttemptsKey);
      await prefs.remove(_lastErrorKey);
      await prefs.remove(_appCrashCountKey);
      debugPrint('🧹 Cleared all app state');
    } catch (e) {
      debugPrint('❌ Error clearing app state: $e');
    }
  }

  /// รับสถิติการใช้งานแอป
  static Future<Map<String, dynamic>> getAppStats() async {
    final lastLoginMethod = await getLastLoginMethod();
    final loginAttempts = await getLoginAttempts();
    final crashCount = await getCrashCount();
    final lastError = await getLastError();
    
    return {
      'lastLoginMethod': lastLoginMethod,
      'loginAttempts': loginAttempts,
      'crashCount': crashCount,
      'hasRecentError': lastError != null,
      'lastErrorTime': lastError?['timestamp'],
      'shouldShowRecovery': await shouldShowRecoveryOptions(),
    };
  }
}
