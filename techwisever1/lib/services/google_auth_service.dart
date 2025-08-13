import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'auth_utils.dart';

/// Google Authentication Service
/// 
/// สำหรับการใช้งาน Google Sign-In ให้ถูกต้อง ต้องตั้งค่า:
/// 1. เพิ่ม web client ใน Firebase Console
/// 2. อัพเดท google-services.json ให้มี web oauth client
/// 3. เปลี่ยน 'your-web-client-id' เป็น web client ID จริง
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
    // ✅ ใช้ web client ID จริงจาก Firebase Console
    serverClientId: '517912732365-h40nu5f5oebar3c68supsaal73g86imn.apps.googleusercontent.com',
  );

  /// เข้าสู่ระบบด้วย Google พร้อมตัวเลือกบัญชี
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // ตรวจสอบการเชื่อมต่ออินเทอร์เน็ตก่อน
      debugPrint('Starting Google Sign-In process...');
      
      // เคลียร์ cache เก่าเพื่อป้องกัน error
      await _googleSignIn.signOut();
      
      // ทำการ sign in แบบ manual เสมอเพื่อให้ผู้ใช้เลือกบัญชี
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Google Sign-In timeout');
              return null;
            },
          );
      
      if (googleUser == null) {
        // ผู้ใช้ยกเลิกการ login หรือ timeout
        debugPrint('Google Sign-In cancelled by user');
        return null;
      }

      debugPrint('Google user selected: ${googleUser.email}');

      final googleAuth = await googleUser.authentication
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Authentication timeout');
            },
          );

      // ตรวจสอบ tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens');
      }

      debugPrint('Got authentication tokens');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Firebase sign-in timeout');
            },
          );
      
      debugPrint('Firebase sign-in successful: ${userCredential.user?.email}');
      
      // สร้างข้อมูลผู้ใช้ใน Firestore (ทำแบบ fire-and-forget)
      if (userCredential.user != null) {
        AuthUtils.ensureUserExists(userCredential.user!).catchError((e) {
          debugPrint('Error creating user in Firestore: $e');
        });
      }

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      
      // ถ้าเป็น PlatformException ให้แสดงข้อมูลเพิ่มเติม
      if (e.toString().contains('PlatformException')) {
        debugPrint('This is likely a configuration issue. Please check:');
        debugPrint('1. google-services.json has correct web client ID');
        debugPrint('2. SHA-1 fingerprint is correct in Firebase Console');
        debugPrint('3. Package name matches in all configurations');
      }
      
      rethrow;
    }
  }

  /// เปลี่ยนบัญชี Google
  static Future<UserCredential?> switchGoogleAccount() async {
    try {
      // ตรวจสอบสถานะการเชื่อมต่อ
      await _googleSignIn.disconnect();
      await FirebaseAuth.instance.signOut();
      
      // ลดเวลาการรอให้น้อยลง
      await Future.delayed(const Duration(milliseconds: 200));

      // ให้ผู้ใช้เลือกบัญชีใหม่
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // ผู้ใช้ยกเลิกการเลือกบัญชี
        debugPrint('User cancelled account selection');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      
      // ตรวจสอบว่ามี token
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('ไม่สามารถรับ authentication token ได้');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // สร้างข้อมูลผู้ใช้ใน Firestore
      if (userCredential.user != null) {
        await AuthUtils.ensureUserExists(userCredential.user!);
      }

      debugPrint('Successfully switched to Google account: ${userCredential.user?.email}');
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