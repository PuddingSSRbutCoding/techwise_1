import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Network connectivity utilities
class NetworkUtils {
  
  /// ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ Internet connection available');
        return true;
      }
    } on SocketException catch (e) {
      debugPrint('❌ Socket exception: $e');
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout exception: $e');
    } catch (e) {
      debugPrint('❌ Unknown network error: $e');
    }
    return false;
  }

  /// ตรวจสอบการเชื่อมต่อ Firebase
  static Future<bool> canReachFirebase() async {
    try {
      final result = await InternetAddress.lookup('firebase.google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ Firebase reachable');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Cannot reach Firebase: $e');
    }
    return false;
  }

  /// ตรวจสอบการเชื่อมต่อ Google services
  static Future<bool> canReachGoogle() async {
    try {
      final result = await InternetAddress.lookup('accounts.google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('✅ Google services reachable');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Cannot reach Google services: $e');
    }
    return false;
  }

  /// ตรวจสอบการเชื่อมต่อเครือข่ายแบบเบื้องต้น
  static Future<NetworkStatus> checkNetworkStatus() async {
    try {
      // ทดสอบการเชื่อมต่อพื้นฐาน
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        return NetworkStatus.noInternet;
      }

      // ทดสอบการเชื่อมต่อ Firebase
      final canReachFB = await canReachFirebase();
      if (!canReachFB) {
        return NetworkStatus.firebaseUnreachable;
      }

      // ทดสอบการเชื่อมต่อ Google
      final canReachGGL = await canReachGoogle();
      if (!canReachGGL) {
        return NetworkStatus.googleUnreachable;
      }

      return NetworkStatus.connected;
    } catch (e) {
      debugPrint('Network check error: $e');
      return NetworkStatus.error;
    }
  }

  /// รับข้อความ error สำหรับสถานะเครือข่าย
  static String getNetworkErrorMessage(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        return 'เชื่อมต่อเครือข่ายได้ปกติ';
      case NetworkStatus.noInternet:
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้\nกรุณาตรวจสอบการเชื่อมต่อ WiFi หรือ Mobile Data';
      case NetworkStatus.firebaseUnreachable:
        return 'ไม่สามารถเชื่อมต่อ Firebase ได้\nกรุณาลองใหม่อีกครั้ง';
      case NetworkStatus.googleUnreachable:
        return 'ไม่สามารถเชื่อมต่อ Google services ได้\nการ login ด้วย Google อาจไม่ทำงาน';
      case NetworkStatus.error:
        return 'เกิดข้อผิดพลาดในการตรวจสอบเครือข่าย';
    }
  }
}

/// สถานะการเชื่อมต่อเครือข่าย
enum NetworkStatus {
  connected,
  noInternet,
  firebaseUnreachable,
  googleUnreachable,
  error
}
