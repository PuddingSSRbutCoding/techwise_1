import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'dart:async';

/// Service สำหรับจัดการ authentication state และ user data
class AuthStateService {
  static AuthStateService? _instance;
  static AuthStateService get instance => _instance ??= AuthStateService._();

  AuthStateService._();

  final ValueNotifier<bool> isLoadingUser = ValueNotifier(false);
  final ValueNotifier<Map<String, dynamic>?> userData = ValueNotifier(null);
  final ValueNotifier<String?> error = ValueNotifier(null);

  StreamSubscription<User?>? _authSubscription;
  Timer? _timeoutTimer;

  /// เริ่มต้น service และ listen ต่อ auth state changes
  void initialize() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChange,
      onError: (error) {
        debugPrint('Auth state error: $error');
        this.error.value = error.toString();
      },
    );
  }

  /// จัดการการเปลี่ยนแปลง auth state
  void _handleAuthStateChange(User? user) async {
    // ยกเลิก timer เก่าทันทีเมื่อมี auth state change
    _timeoutTimer?.cancel();

    if (user == null) {
      // ผู้ใช้ออกจากระบบ - รีเซ็ตสถานะทันทีและล้างข้อมูลทั้งหมด
      stopLoadingAndClearData();
      debugPrint('🔄 Auth state cleared - user signed out');
      return;
    }

    // ผู้ใช้เข้าสู่ระบบ - หยุด loading state ทันที
    isLoadingUser.value = false;
    
    // ตรวจสอบก่อนว่าผู้ใช้ยังคงเป็นคนเดิมหรือไม่
    final currentUid = userData.value?['uid'];
    if (currentUid == user.uid) {
      // ถ้าเป็นผู้ใช้เดิมและมีข้อมูลแล้ว ไม่ต้องโหลดใหม่
      debugPrint('🔄 Same user - skipping reload: ${user.email}');
      return;
    }

    // ผู้ใช้ใหม่ - โหลดข้อมูลในพื้นหลังแบบเร็ว
    debugPrint('🔄 Auth state changed - loading user data for: ${user.email}');

    // ใช้ Future.microtask และเพิ่มการตรวจสอบ mounted state
    Future.microtask(() {
      // ตรวจสอบอีกครั้งว่า user ยังคงเป็นคนเดิมหรือไม่ก่อนโหลด
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == user.uid) {
        _loadUserDataFast(user.uid);
      } else {
        debugPrint('🔄 User changed during loading - cancelling');
      }
    });
  }

  /// โหลดข้อมูลผู้ใช้แบบเร็ว (ลด timeout และใช้ fallback ทันที)
  Future<void> _loadUserDataFast(String uid) async {
    // ตรวจสอบว่าผู้ใช้ยังคงเป็นคนเดิมหรือไม่ก่อนเริ่มโหลด
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != uid) {
      debugPrint('🔄 User changed before loading started - aborting');
      return;
    }

    // ยกเลิก timer เก่าก่อน (ถ้ามี)
    _timeoutTimer?.cancel();

    isLoadingUser.value = true;
    error.value = null;

    // ลด timeout เป็น 1.5 วินาที เพื่อให้ responsive มากขึ้น
    _timeoutTimer = Timer(const Duration(milliseconds: 1500), () {
      if (isLoadingUser.value) {
        debugPrint('⚠️ User data loading timeout - using fallback immediately');
        isLoadingUser.value = false;

        // ตรวจสอบอีกครั้งว่าผู้ใช้ยังคงเป็นคนเดิมก่อนสร้าง fallback
        final stillCurrentUser = FirebaseAuth.instance.currentUser;
        if (stillCurrentUser?.uid == uid) {
          _createFallbackUserData(uid)
              .then((fallbackData) {
                // ตรวจสอบอีกครั้งก่อน set ข้อมูล
                final finalCheck = FirebaseAuth.instance.currentUser;
                if (finalCheck?.uid == uid) {
                  userData.value = fallbackData;
                  debugPrint('✅ Using fallback user data after timeout');
                }
              })
              .catchError((e) {
                debugPrint('❌ Fallback data creation failed: $e');
                // ตรวจสอบก่อนแสดง error
                final errorUser = FirebaseAuth.instance.currentUser;
                if (errorUser?.uid == uid) {
                  error.value = 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้';
                }
              });
        }
      }
    });

    try {
      // ตรวจสอบอีกครั้งก่อนเริ่ม request
      final checkUser = FirebaseAuth.instance.currentUser;
      if (checkUser?.uid != uid) {
        debugPrint('🔄 User changed during loading - aborting request');
        return;
      }

      // ใช้ timeout ใน UserService call ที่สั้นกว่า (1 วินาที)
      final data = await UserService.getUserData(uid).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('⚠️ UserService.getUserData timeout - using fallback');
          return null;
        },
      );

      _timeoutTimer?.cancel();

      // ตรวจสอบอีกครั้งหลังได้ข้อมูล
      final postRequestUser = FirebaseAuth.instance.currentUser;
      if (postRequestUser?.uid != uid) {
        debugPrint('🔄 User changed after request - discarding data');
        return;
      }

      if (data != null) {
        userData.value = data;
        isLoadingUser.value = false;
        error.value = null;
        debugPrint('✅ User data loaded successfully');
      } else {
        // ไม่พบข้อมูลผู้ใช้ - ลองสร้างใหม่แบบเร็ว
        debugPrint('⚠️ No user data found, creating new user...');
        try {
          await _createUserDataFast(uid);
        } catch (createError) {
          debugPrint('❌ Failed to create user data: $createError');
          // ตรวจสอบก่อนสร้าง fallback
          final fallbackCheck = FirebaseAuth.instance.currentUser;
          if (fallbackCheck?.uid == uid) {
            userData.value = await _createFallbackUserData(uid);
            isLoadingUser.value = false;
            error.value = null;
          }
        }
      }
    } catch (e) {
      _timeoutTimer?.cancel();
      debugPrint('❌ Failed to load user data: $e');

      // ตรวจสอบก่อนจัดการ error
      final errorUser = FirebaseAuth.instance.currentUser;
      if (errorUser?.uid != uid) {
        debugPrint('🔄 User changed during error handling - skipping');
        return;
      }

      // ในกรณี error ให้ลองใช้ข้อมูลจาก Firebase Auth แทนทันที
      try {
        userData.value = await _createFallbackUserData(uid);
        isLoadingUser.value = false;
        error.value = null;
        debugPrint('✅ Using fallback user data after error');
      } catch (fallbackError) {
        // ตรวจสอบอีกครั้งก่อนแสดง error
        final finalErrorCheck = FirebaseAuth.instance.currentUser;
        if (finalErrorCheck?.uid == uid) {
          isLoadingUser.value = false;
          error.value = 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้';
          debugPrint('❌ Fallback user data failed: $fallbackError');
        }
      }
    }
  }

  /// โหลดข้อมูลผู้ใช้จาก Firestore (ปรับปรุงให้เร็วขึ้น)
  Future<void> _loadUserData(String uid) async {
    // ตรวจสอบว่าผู้ใช้ยังคงเป็นคนเดิมหรือไม่ก่อนเริ่มโหลด
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != uid) {
      debugPrint('🔄 User changed before loading started - aborting');
      return;
    }

    // ยกเลิก timer เก่าก่อน (ถ้ามี)
    _timeoutTimer?.cancel();

    isLoadingUser.value = true;
    error.value = null;

    // ลด timeout เป็น 2 วินาที เพื่อให้ responsive มากขึ้น
    _timeoutTimer = Timer(const Duration(seconds: 2), () {
      if (isLoadingUser.value) {
        debugPrint('⚠️ User data loading timeout');
        isLoadingUser.value = false;

        // ตรวจสอบอีกครั้งว่าผู้ใช้ยังคงเป็นคนเดิมก่อนสร้าง fallback
        final stillCurrentUser = FirebaseAuth.instance.currentUser;
        if (stillCurrentUser?.uid == uid) {
          _createFallbackUserData(uid)
              .then((fallbackData) {
                // ตรวจสอบอีกครั้งก่อน set ข้อมูล
                final finalCheck = FirebaseAuth.instance.currentUser;
                if (finalCheck?.uid == uid) {
                  userData.value = fallbackData;
                  debugPrint('✅ Using fallback user data after timeout');
                }
              })
              .catchError((e) {
                debugPrint('❌ Fallback data creation failed: $e');
                // เช็คว่าผู้ใช้ยังคงเป็นคนเดิมก่อนแสดง error
                final errorCheck = FirebaseAuth.instance.currentUser;
                if (errorCheck?.uid == uid) {
                  error.value = 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้';
                }
              });
        }
      }
    });

    try {
      // ตรวจสอบอีกครั้งก่อนเริ่ม request
      final checkUser = FirebaseAuth.instance.currentUser;
      if (checkUser?.uid != uid) {
        debugPrint('🔄 User changed during loading - aborting request');
        return;
      }

      // ใช้ timeout ใน UserService call ที่สั้นกว่า
      final data = await UserService.getUserData(uid).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('⚠️ UserService.getUserData timeout');
          return null;
        },
      );

      _timeoutTimer?.cancel();

      // ตรวจสอบอีกครั้งหลังได้ข้อมูล
      final postRequestUser = FirebaseAuth.instance.currentUser;
      if (postRequestUser?.uid != uid) {
        debugPrint('🔄 User changed after request - discarding data');
        return;
      }

      if (data != null) {
        userData.value = data;
        debugPrint('✅ User data loaded successfully');
      } else {
        // ไม่พบข้อมูลผู้ใช้ - ลองสร้างใหม่
        debugPrint('⚠️ No user data found, creating new user...');
        try {
          await _createUserData(uid);
        } catch (createError) {
          debugPrint('❌ Failed to create user data: $createError');
          // ตรวจสอบก่อนสร้าง fallback
          final fallbackCheck = FirebaseAuth.instance.currentUser;
          if (fallbackCheck?.uid == uid) {
            userData.value = await _createFallbackUserData(uid);
          }
        }
      }

      isLoadingUser.value = false;
      error.value = null;
    } catch (e) {
      _timeoutTimer?.cancel();
      debugPrint('❌ Failed to load user data: $e');

      // ตรวจสอบก่อนจัดการ error
      final errorUser = FirebaseAuth.instance.currentUser;
      if (errorUser?.uid != uid) {
        debugPrint('🔄 User changed during error handling - skipping');
        return;
      }

      // ในกรณี error ให้ลองใช้ข้อมูลจาก Firebase Auth แทน
      try {
        userData.value = await _createFallbackUserData(uid);
        isLoadingUser.value = false;
        error.value = null;
        debugPrint('✅ Using fallback user data');
      } catch (fallbackError) {
        // ตรวจสอบอีกครั้งก่อนแสดง error
        final finalErrorCheck = FirebaseAuth.instance.currentUser;
        if (finalErrorCheck?.uid == uid) {
          isLoadingUser.value = false;
          error.value = 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้';
          debugPrint('❌ Fallback user data failed: $fallbackError');
        }
      }
    }
  }

  /// สร้างข้อมูลผู้ใช้ใหม่แบบเร็ว (ลด timeout)
  Future<void> _createUserDataFast(String uid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.createOrUpdateUser(
          uid: uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
        ).timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('⚠️ User creation timeout - using fallback');
            throw TimeoutException('User creation timeout');
          },
        );

        // โหลดข้อมูลใหม่หลังจากสร้าง
        final data = await UserService.getUserData(
          uid,
        ).timeout(const Duration(milliseconds: 800), onTimeout: () => null);
        userData.value = data;
        debugPrint('✅ New user data created and loaded');
      }
    } catch (e) {
      debugPrint('❌ Failed to create user data: $e');
      throw e;
    }
  }

  /// สร้างข้อมูลผู้ใช้ใหม่สำหรับผู้ใช้ที่ยังไม่มีข้อมูลใน Firestore
  Future<void> _createUserData(String uid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.createOrUpdateUser(
          uid: uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
        ).timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            debugPrint('⚠️ User creation timeout - using fallback');
            throw TimeoutException('User creation timeout');
          },
        );

        // โหลดข้อมูลใหม่หลังจากสร้าง
        final data = await UserService.getUserData(uid).timeout(
          const Duration(milliseconds: 800),
          onTimeout: () => null,
        );
        userData.value = data;
        debugPrint('✅ New user data created and loaded');
      }
    } catch (e) {
      debugPrint('❌ Failed to create user data: $e');
      throw e;
    }
  }

  /// สร้างข้อมูลผู้ใช้สำรองจาก Firebase Auth
  Future<Map<String, dynamic>> _createFallbackUserData(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    return {
      'uid': uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? 'ผู้ใช้',
      'photoURL': user.photoURL,
      'role': 'user',
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': DateTime.now().toIso8601String(),
      'isActive': true,
    };
  }

  /// รีเฟรชข้อมูลผู้ใช้
  Future<void> refreshUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _loadUserData(user.uid).timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️ Refresh user data timeout - stopping loading');
            isLoadingUser.value = false;
            return;
          },
        );
      } catch (e) {
        debugPrint('❌ Refresh user data failed: $e');
        // หยุด loading state ทันทีเมื่อเกิด error
        isLoadingUser.value = false;
      }
    }
  }

  /// ล้างข้อมูลทั้งหมดเมื่อ logout
  void clearAllData() {
    _timeoutTimer?.cancel();
    isLoadingUser.value = false;
    userData.value = null;
    error.value = null;
    debugPrint('🧹 All auth data cleared');
  }

  /// หยุดการ loading และล้างข้อมูลทันที (สำหรับใช้หลังจาก login/logout สำเร็จ)
  void stopLoadingAndClearData() {
    _timeoutTimer?.cancel();
    isLoadingUser.value = false;
    userData.value = null;
    error.value = null;
    debugPrint('🔄 Loading stopped and data cleared after auth state change');
  }

  /// ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่
  bool get isAdmin {
    final data = userData.value;
    if (data == null) return false;

    final email = data['email'] ?? '';
    return data['role'] == 'admin' || email == 'techwiseofficialth@gmail.com';
  }

  /// ปิด service และยกเลิก listeners
  void dispose() {
    _authSubscription?.cancel();
    _timeoutTimer?.cancel();
    isLoadingUser.dispose();
    userData.dispose();
    error.dispose();
  }
}
