import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  /// ตรวจสอบสถานะการ login และนำทางไปยังหน้าที่เหมาะสม
  static void handleAuthStateChange(BuildContext context, User? user) {
    if (user != null) {
      // ผู้ใช้ login อยู่แล้ว - ไปที่หน้า main
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      // ผู้ใช้ยังไม่ได้ login - ไปที่หน้า login
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  /// ตรวจสอบว่าผู้ใช้ login อยู่แล้วหรือไม่
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// รับข้อมูลผู้ใช้ปัจจุบัน
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// ออกจากระบบและนำทางไปยังหน้า login
  static Future<void> signOutAndNavigate(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// แสดงข้อความ error ที่เหมาะสม
  static void showAuthError(BuildContext context, String error) {
    String errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
    
    if (error.contains('user-not-found')) {
      errorMessage = 'ไม่พบบัญชีผู้ใช้นี้';
    } else if (error.contains('wrong-password')) {
      errorMessage = 'รหัสผ่านไม่ถูกต้อง';
    } else if (error.contains('invalid-email')) {
      errorMessage = 'อีเมลไม่ถูกต้อง';
    } else if (error.contains('weak-password')) {
      errorMessage = 'รหัสผ่านอ่อนเกินไป';
    } else if (error.contains('email-already-in-use')) {
      errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว';
    } else if (error.contains('network-request-failed')) {
      errorMessage = 'ปัญหาในการเชื่อมต่อเครือข่าย';
    } else if (error.contains('sign_in_failed')) {
      errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ Google';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
} 