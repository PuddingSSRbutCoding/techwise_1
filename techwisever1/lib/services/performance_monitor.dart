import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Performance monitoring และ memory management
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final List<String> _performanceLogs = [];
  
  /// เริ่มต้นการวัดประสิทธิภาพ
  static void startTimer(String operation) {
    if (kDebugMode) {
      _startTimes[operation] = DateTime.now();
      debugPrint('⏱️ Started: $operation');
    }
  }
  
  /// จบการวัดประสิทธิภาพ
  static void endTimer(String operation) {
    if (kDebugMode && _startTimes.containsKey(operation)) {
      final elapsed = DateTime.now().difference(_startTimes[operation]!);
      final message = '✅ $operation: ${elapsed.inMilliseconds}ms';
      _performanceLogs.add(message);
      debugPrint(message);
      _startTimes.remove(operation);
      
      // ถ้าใช้เวลานานมาก ให้แจ้งเตือน
      if (elapsed.inSeconds > 5) {
        debugPrint('⚠️ Slow operation detected: $operation (${elapsed.inSeconds}s)');
      }
    }
  }
  
  /// วัดประสิทธิภาพของ function
  static Future<T> measureAsync<T>(String operation, Future<T> Function() function) async {
    startTimer(operation);
    try {
      final result = await function();
      endTimer(operation);
      return result;
    } catch (e) {
      endTimer('$operation (ERROR)');
      rethrow;
    }
  }
  
  /// Log memory usage
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // ใช้ developer tools ในการ log memory
      developer.log(
        'Memory check: $context',
        name: 'PerformanceMonitor',
      );
    }
  }
  
  /// รับ performance logs ทั้งหมด
  static List<String> getPerformanceLogs() {
    return List.from(_performanceLogs);
  }
  
  /// ล้าง performance logs
  static void clearLogs() {
    _performanceLogs.clear();
    _startTimes.clear();
  }
  
  /// ตรวจสอบว่า app ทำงานได้ดี
  static bool isPerformanceGood() {
    // ตรวจสอบจาก logs ล่าสุด
    final recentLogs = _performanceLogs.length > 10 
        ? _performanceLogs.skip(_performanceLogs.length - 10)
        : _performanceLogs;
    
    // นับจำนวน operations ที่ช้า
    final slowOperations = recentLogs.where((log) {
      final match = RegExp(r'(\d+)ms').firstMatch(log);
      if (match != null) {
        final ms = int.tryParse(match.group(1) ?? '0') ?? 0;
        return ms > 3000; // มากกว่า 3 วินาที
      }
      return false;
    }).length;
    
    // ถ้ามี slow operations มากกว่า 30% ถือว่าไม่ดี
    return slowOperations / recentLogs.length < 0.3;
  }
}
