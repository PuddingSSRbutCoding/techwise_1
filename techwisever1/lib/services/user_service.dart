import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// สร้างหรืออัปเดตข้อมูลผู้ใช้ใน Firestore
  static Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String role = 'user',
    String? userRole, // ครู-อาจารย์/นักศึกษา
    String? grade, // ระดับชั้น
    String? institution, // สถานที่ศึกษา
  }) async {
    try {
      final Map<String, dynamic> userData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // เพิ่มข้อมูลเพิ่มเติมถ้ามี
      if (userRole != null) userData['userRole'] = userRole;
      if (grade != null) userData['grade'] = grade;
      if (institution != null) userData['institution'] = institution;

      await _firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));

      // ถ้าเป็นครั้งแรกที่สร้าง ให้เพิ่ม createdAt
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data()?['createdAt'] == null) {
        await _firestore.collection('users').doc(uid).update({
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// รับข้อมูลผู้ใช้จาก Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// รับ URL รูปโปรไฟล์ของผู้ใช้ (แสดง custom photo ก่อน ถ้าไม่มีจึงแสดง Google photo)
  static Future<String?> getUserPhotoURL(String uid) async {
    try {
      final userData = await getUserData(uid);
      // ให้ความสำคัญกับรูปที่ผู้ใช้อัปโหลดเองก่อน
      final customPhotoURL = userData?['customPhotoURL'];
      if (customPhotoURL != null && customPhotoURL.isNotEmpty) {
        return customPhotoURL;
      }
      // ถ้าไม่มีรูป custom ให้ใช้รูปจาก Google
      return userData?['photoURL'];
    } catch (e) {
      return null;
    }
  }

  /// ตรวจสอบว่าผู้ใช้เป็นแอดมินหรือไม่
  static Future<bool> isAdmin(String uid) async {
    try {
      final userData = await getUserData(uid);
      final email = userData?['email'] ?? '';
      
      // ตรวจสอบบัญชีพิเศษที่กำหนดเป็น admin โดยตรง
      if (email == 'techwiseofficialth@gmail.com') {
        // อัปเดต role เป็น admin ถ้ายังไม่ได้ตั้งค่า
        if (userData?['role'] != 'admin') {
          await changeUserRole(uid, 'admin');
        }
        return true;
      }
      
      return userData?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// อัปเดตข้อมูลผู้ใช้
  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  /// ลบผู้ใช้
  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// รับรายการผู้ใช้ทั้งหมด (สำหรับแอดมิน)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  /// เปลี่ยนบทบาทของผู้ใช้
  static Future<void> changeUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to change user role: $e');
    }
  }

  /// อัปโหลดรูปโปรไฟล์ไปยัง Firebase Storage
  static Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadURL = await uploadTask.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// อัปเดตรูปโปรไฟล์ของผู้ใช้
  static Future<void> updateProfileImage(String uid, File imageFile) async {
    try {
      // อัปโหลดรูปไปยัง Storage
      final photoURL = await uploadProfileImage(uid, imageFile);
      
      // อัปเดต photoURL ใน Firestore
      await _firestore.collection('users').doc(uid).update({
        'customPhotoURL': photoURL, // ใช้ field แยกต่างหากจาก photoURL ของ Google
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // อัปเดต photoURL ใน Firebase Auth (ถ้าต้องการ)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }
} 