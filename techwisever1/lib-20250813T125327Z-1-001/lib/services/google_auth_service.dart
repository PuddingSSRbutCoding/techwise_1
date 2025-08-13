import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'auth_utils.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );

  /// เข้าสู่ระบบด้วย Google พร้อมตัวเลือกบัญชี
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // เรียก signIn() โดยตรงเพื่อให้ผู้ใช้เลือกบัญชี
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // ผู้ใช้ยกเลิกการ login
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // สร้างข้อมูลผู้ใช้ใน Firestore
      if (userCredential.user != null) {
        await AuthUtils.ensureUserExists(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// เปลี่ยนบัญชี Google
  static Future<UserCredential?> switchGoogleAccount() async {
    try {
      // ออกจากบัญชีปัจจุบัน
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();

      // ให้ผู้ใช้เลือกบัญชีใหม่
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // ผู้ใช้ยกเลิกการเลือกบัญชี
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // สร้างข้อมูลผู้ใช้ใน Firestore
      if (userCredential.user != null) {
        await AuthUtils.ensureUserExists(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Switch Google Account Error: $e');
      rethrow;
    }
  }

  /// ออกจากระบบ Google
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      rethrow;
    }
  }

  /// ตรวจสอบว่าผู้ใช้ login ด้วย Google หรือไม่
  static bool isGoogleUser(User? user) {
    return user?.providerData.any((element) => element.providerId == 'google.com') ?? false;
  }

  /// รับข้อมูลบัญชี Google ปัจจุบัน
  static Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Get Current Google User Error: $e');
      return null;
    }
  }
} 