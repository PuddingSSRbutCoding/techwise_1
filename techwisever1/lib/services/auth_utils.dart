import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'network_utils.dart';

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

  /// ออกจากระบบและนำทางไปยังหน้า welcome
  static Future<void> signOutAndNavigate(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
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

  /// ตรวจสอบและสร้างข้อมูลผู้ใช้ถ้ายังไม่มี
  static Future<void> ensureUserExists(User user) async {
    try {
      final userData = await UserService.getUserData(user.uid);
      if (userData == null) {
        // สร้างข้อมูลผู้ใช้ใหม่ถ้ายังไม่มี
        await createUserInFirestore(user);
      }
    } catch (e) {
      debugPrint('Ensure user exists error: $e');
    }
  }

  /// แสดงข้อความ error ที่เหมาะสม พร้อมตรวจสอบเครือข่าย
  static Future<void> showAuthError(BuildContext context, String error) async {
    String errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
    String? actionText;
    VoidCallback? action;
    
    // ตรวจสอบปัญหาเครือข่ายก่อน
    if (error.contains('network-request-failed') || 
        error.contains('NetworkException') || 
        error.contains('timeout')) {
      final networkStatus = await NetworkUtils.checkNetworkStatus();
      errorMessage = NetworkUtils.getNetworkErrorMessage(networkStatus);
      
      if (networkStatus != NetworkStatus.connected) {
        actionText = 'ตรวจสอบอีกครั้ง';
        action = () async {
          final newStatus = await NetworkUtils.checkNetworkStatus();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(NetworkUtils.getNetworkErrorMessage(newStatus)),
                backgroundColor: newStatus == NetworkStatus.connected 
                    ? Colors.green 
                    : Colors.orange,
              ),
            );
          }
        };
      }
    } else {
      // Error messages ปกติ
      if (error.contains('user-not-found')) {
        errorMessage = 'ไม่พบบัญชีผู้ใช้นี้\nกรุณาตรวจสอบอีเมลหรือสมัครสมาชิกใหม่';
      } else if (error.contains('wrong-password')) {
        errorMessage = 'รหัสผ่านไม่ถูกต้อง\nกรุณาลองใหม่อีกครั้งหรือรีเซ็ตรหัสผ่าน';
      } else if (error.contains('invalid-email')) {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง\nกรุณากรอกอีเมลให้ถูกต้อง';
      } else if (error.contains('weak-password')) {
        errorMessage = 'รหัสผ่านอ่อนเกินไป\nกรุณาใช้รหัสผ่านที่มีความปลอดภัยมากขึ้น';
      } else if (error.contains('email-already-in-use')) {
        errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว\nกรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
      } else if (error.contains('sign_in_failed') || error.contains('ApiException')) {
        errorMessage = 'การเข้าสู่ระบบ Google ล้มเหลว\nกรุณาตรวจสอบการตั้งค่าหรือลองใหม่อีกครั้ง';
      } else if (error.contains('too-many-requests')) {
        errorMessage = 'มีการพยายามเข้าสู่ระบบมากเกินไป\nกรุณารอสักครู่แล้วลองใหม่';
      } else if (error.contains('user-disabled')) {
        errorMessage = 'บัญชีผู้ใช้ถูกปิดใช้งาน\nกรุณาติดต่อผู้ดูแลระบบ';
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: actionText != null ? SnackBarAction(
            label: actionText,
            textColor: Colors.white,
            onPressed: action ?? () {},
          ) : null,
        ),
      );
    }
  }

  /// ตรวจสอบเครือข่ายก่อนทำ authentication
  static Future<bool> checkNetworkBeforeAuth(BuildContext context) async {
    final networkStatus = await NetworkUtils.checkNetworkStatus();
    
    if (networkStatus != NetworkStatus.connected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkUtils.getNetworkErrorMessage(networkStatus)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () => checkNetworkBeforeAuth(context),
            ),
          ),
        );
      }
      return false;
    }
    
    return true;
  }
} 