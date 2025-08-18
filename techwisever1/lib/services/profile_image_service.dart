import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service สำหรับจัดการรูปโปรไฟล์แบบ global
/// ใช้ local storage และ fallback ไป Firebase
class ProfileImageService {
  static const String _localImageKey = 'local_profile_image';

  /// ดึงรูปโปรไฟล์แบบ global (local storage + Firebase fallback)
  static Future<ImageProvider?> getProfileImage(String uid) async {
    try {
      // 1. ลองดึงจาก local storage ก่อน
      final localImage = await _getLocalProfileImage(uid);
      if (localImage != null) {
        return FileImage(localImage);
      }

      // 2. ถ้าไม่มี local ให้ดึงจาก Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid && user.photoURL != null) {
        return NetworkImage(user.photoURL!);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting profile image: $e');
      return null;
    }
  }

  /// ดึงรูปโปรไฟล์แบบ global สำหรับ current user
  static Future<ImageProvider?> getCurrentUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return getProfileImage(user.uid);
    }
    return null;
  }

  /// ดึงรูปโปรไฟล์แบบ global พร้อม fallback icon
  static Future<Widget> getProfileImageWidget({
    required String uid,
    double radius = 25,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
  }) async {
    final image = await getProfileImage(uid);

    if (image != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.white,
        backgroundImage: image,
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade300,
        child: Icon(
          Icons.person,
          color: iconColor ?? Colors.grey,
          size: iconSize ?? (radius * 0.6),
        ),
      );
    }
  }

  /// ดึงรูปโปรไฟล์แบบ global สำหรับ current user พร้อม fallback icon
  static Future<Widget> getCurrentUserProfileImageWidget({
    double radius = 25,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return getProfileImageWidget(
        uid: user.uid,
        radius: radius,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        iconSize: iconSize,
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade300,
        child: Icon(
          Icons.person,
          color: iconColor ?? Colors.grey,
          size: iconSize ?? (radius * 0.6),
        ),
      );
    }
  }

  /// ตรวจสอบว่ามีรูป local หรือไม่
  static Future<bool> hasLocalProfileImage(String uid) async {
    try {
      final localImage = await _getLocalProfileImage(uid);
      return localImage != null;
    } catch (e) {
      return false;
    }
  }

  /// ตรวจสอบว่ามีรูป local สำหรับ current user หรือไม่
  static Future<bool> hasCurrentUserLocalProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return hasLocalProfileImage(user.uid);
    }
    return false;
  }

  /// ดึงรูป local จาก storage
  static Future<File?> _getLocalProfileImage(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('${_localImageKey}_$uid');

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          return file;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting local profile image: $e');
      return null;
    }
  }

  /// บันทึกรูป local ลง storage
  static Future<bool> saveLocalProfileImage(
    String uid,
    String imagePath,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_localImageKey}_$uid', imagePath);
      return true;
    } catch (e) {
      debugPrint('Error saving local profile image: $e');
      return false;
    }
  }

  /// ลบรูป local ออกจาก storage
  static Future<bool> removeLocalProfileImage(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_localImageKey}_$uid');
      return true;
    } catch (e) {
      debugPrint('Error removing local profile image: $e');
      return false;
    }
  }

  /// ลบรูป local สำหรับ current user
  static Future<bool> removeCurrentUserLocalProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return removeLocalProfileImage(user.uid);
    }
    return false;
  }
}
