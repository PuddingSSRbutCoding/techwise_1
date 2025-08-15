import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

/// Simplified Auth Utilities - เฉพาะฟังก์ชันที่จำเป็น
class AuthUtils {
  /// ตรวจสอบว่าผู้ใช้ login อยู่แล้วหรือไม่
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// รับข้อมูลผู้ใช้ปัจจุบัน
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// สร้างข้อมูลผู้ใช้ใน Firestore เมื่อ login สำเร็จ
  static Future<void> createUserInFirestore(User user) async {
    try {
      await UserService.createOrUpdateUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoURL: user.photoURL,
        role: 'user', // เริ่มต้นเป็นผู้ใช้ทั่วไป
      );
    } catch (e) {
      debugPrint('Create user in Firestore error: $e');
    }
  }

  /// แสดงข้อความ error แบบเรียบง่าย
  static void showAuthError(BuildContext context, String error) {
    String errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
    
    // Error messages พื้นฐาน
    if (error.contains('user-not-found')) {
      errorMessage = 'ไม่พบบัญชีผู้ใช้นี้ กรุณาตรวจสอบอีเมลหรือสมัครสมาชิกใหม่';
    } else if (error.contains('wrong-password')) {
      errorMessage = 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง';
    } else if (error.contains('invalid-email')) {
      errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
    } else if (error.contains('weak-password')) {
      errorMessage = 'รหัสผ่านอ่อนเกินไป กรุณาใช้รหัสผ่านที่ปลอดภัยมากขึ้น';
    } else if (error.contains('email-already-in-use')) {
      errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
    } else if (error.contains('sign_in_failed') || error.contains('ApiException')) {
      errorMessage = 'การเข้าสู่ระบบ Google ล้มเหลว กรุณาลองใหม่อีกครั้ง';
    } else if (error.contains('too-many-requests')) {
      errorMessage = 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณารอสักครู่แล้วลองใหม่';
    } else if (error.contains('user-disabled')) {
      errorMessage = 'บัญชีผู้ใช้ถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
    } else if (error.contains('network-request-failed') || 
               error.contains('timeout')) {
      errorMessage = 'ปัญหาการเชื่อมต่อ กรุณาตรวจสอบอินเทอร์เน็ตและลองใหม่';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ปิด',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
} 