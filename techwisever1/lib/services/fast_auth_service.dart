import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Fast Authentication Service - สำหรับการล็อกอินแบบเร็ว
class FastAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ตรวจสอบสถานะการล็อกอินแบบเร็ว
  static Future<bool> isUserAuthenticated() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user != null;
    } catch (e) {
      debugPrint('Fast auth check failed: $e');
      return false;
    }
  }

  /// สร้างข้อมูลผู้ใช้แบบเร็ว (ไม่รอ Firestore)
  static Future<Map<String, dynamic>> createQuickUserData(User user) async {
    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? 'ผู้ใช้',
      'photoURL': user.photoURL,
      'role': 'user',
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': DateTime.now().toIso8601String(),
      'isActive': true,
      'isQuickData': true, // ระบุว่าเป็นข้อมูลชั่วคราว
    };
  }

  /// บันทึกข้อมูลผู้ใช้ใน Firestore แบบไม่บล็อก UI
  static Future<void> saveUserDataInBackground(User user) async {
    try {
      // ใช้ timeout สั้นมาก
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Background user save timeout - continuing anyway');
              return;
            },
          );
      debugPrint('✅ User data saved in background');
    } catch (e) {
      debugPrint('⚠️ Background user save failed: $e');
      // ไม่ throw error เพื่อไม่ให้บล็อก UI
    }
  }

  /// ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่ (แบบเร็ว)
  static Future<bool> isAdminQuick(String uid) async {
    try {
      // ตรวจสอบบัญชีพิเศษที่กำหนดเป็น admin โดยตรง
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == 'techwiseofficialth@gmail.com') {
        return true;
      }

      // ตรวจสอบจาก Firestore แบบเร็ว
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ Admin check timeout');
              return _firestore.collection('users').doc(uid).get();
            },
          );

      if (doc?.exists == true) {
        final data = doc!.data() as Map<String, dynamic>?;
        return data?['role'] == 'admin' ||
            data?['email'] == 'techwiseofficialth@gmail.com';
      }

      return false;
    } catch (e) {
      debugPrint('Quick admin check failed: $e');
      return false;
    }
  }

  /// ดึงข้อมูลผู้ใช้แบบเร็ว (ไม่รอ Firestore)
  static Future<Map<String, dynamic>?> getUserDataQuick(String uid) async {
    try {
      // ใช้ timeout สั้นมาก
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ Quick user data fetch timeout');
              throw TimeoutException('Quick user data fetch timeout');
            },
          );

      if (doc?.exists == true) {
        return doc!.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Quick user data fetch failed: $e');
      return null;
    }
  }

  /// ดึงรูปโปรไฟล์แบบเร็ว
  static Future<String?> getUserPhotoURLQuick(String uid) async {
    try {
      // ใช้ข้อมูลจาก Firebase Auth ก่อน (เร็วที่สุด)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          return user.photoURL;
        }
      }

      // ถ้าไม่มีรูปใน Auth ให้ดึงจาก Firestore แบบเร็ว
      final userData = await getUserDataQuick(uid);
      if (userData != null) {
        // ให้ความสำคัญกับรูปที่ผู้ใช้อัปโหลดเองก่อน
        final customPhotoURL = userData['customPhotoURL'];
        if (customPhotoURL != null && customPhotoURL.isNotEmpty) {
          return customPhotoURL;
        }
        // ถ้าไม่มีรูป custom ให้ใช้รูปจาก Google
        return userData['photoURL'];
      }

      return null;
    } catch (e) {
      debugPrint('Quick photo URL fetch failed: $e');
      return null;
    }
  }

  /// ดึงชื่อผู้ใช้แบบเร็ว
  static Future<String?> getUserDisplayNameQuick(String uid) async {
    try {
      // ใช้ข้อมูลจาก Firebase Auth ก่อน (เร็วที่สุด)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          return user.displayName;
        }
      }

      // ถ้าไม่มีชื่อใน Auth ให้ดึงจาก Firestore แบบเร็ว
      final userData = await getUserDataQuick(uid);
      if (userData != null) {
        return userData['displayName'] ?? userData['email'] ?? 'ผู้ใช้';
      }

      return null;
    } catch (e) {
      debugPrint('Quick display name fetch failed: $e');
      return null;
    }
  }

  /// ล้างข้อมูลการล็อกอินแบบเร็ว
  static Future<void> quickSignOut() async {
    try {
      // ออกจาก Firebase Auth ทันที
      await FirebaseAuth.instance.signOut().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ Sign out timeout - continuing anyway');
          return;
        },
      );
      debugPrint('✅ Quick sign out completed');
    } catch (e) {
      debugPrint('❌ Quick sign out failed: $e');
      // ไม่ throw error เพื่อไม่ให้แอปค้าง
    }
  }
}
