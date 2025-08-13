import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login/welcome_page.dart';
import '../main_screen.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isInitializing = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // ตรวจสอบสถานะผู้ใช้ปัจจุบันทันที
      _currentUser = FirebaseAuth.instance.currentUser;
      
      // รอ auth state เพียงเล็กน้อย
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // แสดง loading screen ในขณะที่ระบบกำลังเริ่มต้น
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'กำลังโหลด...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ใช้ StreamBuilder แต่เริ่มจาก initialData
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: _currentUser, // เริ่มจากข้อมูลที่มีอยู่แล้ว
      builder: (context, snapshot) {
        // ถ้ามีข้อมูลเริ่มต้นหรือได้รับข้อมูลแล้ว แสดงหน้าที่เหมาะสม
        final user = snapshot.data;
        
        if (user != null) {
          // ผู้ใช้ login แล้ว -> ไปหน้า main
          return const MainScreen();
        } else {
          // ผู้ใช้ยังไม่ได้ login -> ไปหน้า welcome/login
          return const WelcomePage();
        }
      },
    );
  }
}
