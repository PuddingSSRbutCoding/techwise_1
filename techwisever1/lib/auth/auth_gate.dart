import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/login/welcome_page.dart';
import 'package:techwisever1/services/auth_state_service.dart';
import 'dart:async';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _timeoutTimer;
  bool _isTimeout = false;

  @override
  void initState() {
    super.initState();
    // ลด timeout เป็น 15 วินาที เพื่อให้ responsive มากขึ้น
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isTimeout = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // ตรวจสอบ timeout เฉพาะเมื่อ waiting นานเกินไป
        if (_isTimeout && snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'การเชื่อมต่อใช้เวลานานเกินไป',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isTimeout = false;
                      });
                      _timeoutTimer?.cancel();
                      _timeoutTimer = Timer(const Duration(seconds: 15), () {
                        if (mounted) {
                          setState(() {
                            _isTimeout = true;
                          });
                        }
                      });
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          );
        }

        // ปรับ loading logic - ลดเวลาแสดง loading และแสดง MainScreen ทันที
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          // แสดง loading เฉพาะเมื่อยังไม่มีข้อมูลเลย (first time) และลดเวลา
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('กำลังตรวจสอบสถานะการเข้าสู่ระบบ...'),
                  const SizedBox(height: 8),
                  const Text(
                    'หากใช้เวลานาน กรุณาลองใหม่',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // ยกเลิก timeout timer เมื่อได้ผลลัพธ์แล้ว
        _timeoutTimer?.cancel();

        final user = snap.data;
        if (user != null) {
          // ล็อกอินแล้ว → ไปที่ MainScreen ทันทีโดยไม่รอข้อมูล
          debugPrint('✅ Auth: User authenticated - ${user.email}');
          
          // หยุด loading state ทันทีหลังจาก login สำเร็จ
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AuthStateService.instance.isLoadingUser.value = false;
            // ล้างข้อมูลเก่าและรีเซ็ตสถานะ
            AuthStateService.instance.clearAllData();
          });

          // แสดง MainScreen ทันที - ไม่ต้องรอ AuthStateService
          return const MainScreen(initialIndex: 0);
        }

        // ยังไม่ล็อกอิน → ไปที่ WelcomePage ทันที
        debugPrint('🔄 Auth: No user authenticated - showing welcome page');
        
        // หยุด loading state ทันทีหลังจาก logout สำเร็จ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuthStateService.instance.isLoadingUser.value = false;
          // ล้างข้อมูลเก่าและรีเซ็ตสถานะ
          AuthStateService.instance.clearAllData();
        });
        
        return const WelcomePage();
      },
    );
  }
}
