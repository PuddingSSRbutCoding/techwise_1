import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Google Authentication Service - เวอร์ชันเรียบง่าย
class GoogleAuthService {
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// เข้าสู่ระบบด้วย Google (เวอร์ชันเรียบง่าย)
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🚀 Starting Google Sign-In...');
      
      // ขั้นตอนที่ 1: เลือกบัญชี Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ User cancelled Google Sign-In');
        return null;
      }

      debugPrint('✅ Google user selected: ${googleUser.email}');

      // ขั้นตอนที่ 2: ได้รับ authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // ขั้นตอนที่ 3: สร้าง Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ขั้นตอนที่ 4: เข้าสู่ระบบ Firebase
      debugPrint('🔥 Signing in to Firebase...');
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      debugPrint('🎉 Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign-In Error: $e');
      
      // แสดงข้อความง่ายๆ สำหรับ API Error 10
      if (e.toString().contains('ApiException: 10')) {
        debugPrint('💡 ต้องตั้งค่า SHA-1 fingerprint ใน Firebase Console');
        debugPrint('SHA-1: 89:E6:F6:9F:24:B5:3C:E2:CB:88:91:BD:8F:C9:E5:01:B8:58:C9:47');
      }
      
      rethrow;
    }
  }

  /// เปลี่ยนบัญชี Google (บังคับเลือกใหม่)
  static Future<UserCredential?> switchGoogleAccount() async {
    try {
      // ออกจากระบบก่อน
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      
      // เลือกบัญชีใหม่
      return await signInWithGoogle();
    } catch (e) {
      debugPrint('❌ Switch Account Error: $e');
      rethrow;
    }
  }

  /// ออกจากระบบ Google
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign Out Error: $e');
      rethrow;
    }
  }

  /// ตรวจสอบว่าผู้ใช้ login ด้วย Google หรือไม่
  static bool isGoogleUser(User? user) {
    return user?.providerData.any((element) => element.providerId == 'google.com') ?? false;
  }
} 