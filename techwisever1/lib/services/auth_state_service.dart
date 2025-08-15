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
    if (user == null) {
      // ผู้ใช้ออกจากระบบ - รีเซ็ตสถานะทันที
      _timeoutTimer?.cancel();
      isLoadingUser.value = false;
      userData.value = null;
      error.value = null;
      debugPrint('🔄 Auth state cleared - user signed out');
      return;
    }
    
    // ผู้ใช้เข้าสู่ระบบ - โหลดข้อมูลในพื้นหลัง (ไม่บล็อก UI)
    debugPrint('🔄 Auth state changed - loading user data for: ${user.email}');
    // ใช้ unawaited เพื่อไม่ให้บล็อก UI
    _loadUserData(user.uid);
  }
  
  /// โหลดข้อมูลผู้ใช้จาก Firestore (ปรับปรุงให้เร็วขึ้น)
  Future<void> _loadUserData(String uid) async {
    isLoadingUser.value = true;
    error.value = null;
    
    // ลด timeout เป็น 8 วินาที เพื่อให้ responsive มากขึ้น
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (isLoadingUser.value) {
        debugPrint('⚠️ User data loading timeout');
        isLoadingUser.value = false;
        error.value = 'การโหลดข้อมูลผู้ใช้ใช้เวลานานเกินไป';
      }
    });
    
    try {
      // ใช้ timeout ใน UserService call ด้วย
      final data = await UserService.getUserData(uid).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('⚠️ UserService.getUserData timeout');
          return null;
        },
      );
      
      _timeoutTimer?.cancel();
      
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
          // ถ้าสร้างไม่ได้ก็ให้ใช้ข้อมูลจาก Firebase Auth แทน
          userData.value = await _createFallbackUserData(uid);
        }
      }
      
      isLoadingUser.value = false;
      error.value = null;
    } catch (e) {
      _timeoutTimer?.cancel();
      debugPrint('❌ Failed to load user data: $e');
      
      // ในกรณี error ให้ลองใช้ข้อมูลจาก Firebase Auth แทน
      try {
        userData.value = await _createFallbackUserData(uid);
        isLoadingUser.value = false;
        error.value = null;
        debugPrint('✅ Using fallback user data');
      } catch (fallbackError) {
        isLoadingUser.value = false;
        error.value = 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้';
        debugPrint('❌ Fallback user data failed: $fallbackError');
      }
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
        );
        
        // โหลดข้อมูลใหม่หลังจากสร้าง
        final data = await UserService.getUserData(uid);
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
      await _loadUserData(user.uid);
    }
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
