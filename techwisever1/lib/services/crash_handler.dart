import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'app_state_service.dart';

/// Crash handler และ recovery service
class CrashHandler {
  
  /// Initialize crash handling
  static void initialize() {
    // เฉพาะ debug mode เท่านั้น
    if (kDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logError(details.toString(), 'FlutterError');
      };
    }
  }

  /// บันทึก error และเพิ่ม crash count
  static void _logError(String error, String context) async {
    try {
      developer.log(
        'CRASH: $error',
        name: 'CrashHandler',
        error: error,
      );
      
      // บันทึกใน app state
      await AppStateService.saveLastError(error, context);
      await AppStateService.incrementCrashCount();
      
      debugPrint('💥 Crash logged: $context');
    } catch (e) {
      debugPrint('❌ Error logging crash: $e');
    }
  }

  /// Handle app recovery
  static Future<bool> handleRecovery() async {
    try {
      final crashCount = await AppStateService.getCrashCount();
      final shouldRecover = await AppStateService.shouldShowRecoveryOptions();
      
      if (shouldRecover && crashCount > 2) {
        debugPrint('🔄 Initiating app recovery...');
        
        // Clear problematic state
        await AppStateService.clearLastError();
        
        // ลด crash count
        await AppStateService.resetCrashCount();
        
        debugPrint('✅ App recovery completed');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Recovery failed: $e');
      return false;
    }
  }

  /// Check if app is in stable state
  static Future<bool> isAppStable() async {
    try {
      final stats = await AppStateService.getAppStats();
      final crashCount = stats['crashCount'] as int;
      final loginAttempts = stats['loginAttempts'] as int;
      
      // ถือว่า stable ถ้า crash น้อยกว่า 2 ครั้ง และ login attempts น้อยกว่า 5
      return crashCount < 2 && loginAttempts < 5;
    } catch (e) {
      debugPrint('❌ Error checking app stability: $e');
      return false;
    }
  }

  /// Reset app to clean state
  static Future<void> resetAppState() async {
    try {
      await AppStateService.clearAllAppState();
      debugPrint('🧹 App state reset completed');
    } catch (e) {
      debugPrint('❌ Error resetting app state: $e');
    }
  }
}
