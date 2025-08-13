import 'package:flutter/material.dart';
import 'login/welcome_page.dart';
import 'login/login_page1.dart';
import 'main_screen.dart';
import 'auth/auth_guard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/crash_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // เริ่มต้น crash handler
  CrashHandler.initialize();
  
  // ตรวจสอบและ handle recovery ถ้าจำเป็น
  final needsRecovery = await CrashHandler.handleRecovery();
  if (needsRecovery) {
    debugPrint('🔄 App recovery performed');
  }
  
  // เริ่มต้น Firebase แบบ parallel กับการโหลด App
  final firebaseInitFuture = _initializeFirebase();
  
  runApp(MyApp(firebaseInitFuture: firebaseInitFuture));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  final Future<void> firebaseInitFuture;
  
  const MyApp({super.key, required this.firebaseInitFuture});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      // ใช้ FutureBuilder เพื่อรอ Firebase init
      home: FutureBuilder<void>(
        future: firebaseInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text('เกิดข้อผิดพลาดในการเริ่มต้น: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // รีสตาร์ทแอป
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const AuthGuard();
          }
          
          // แสดง splash screen ขณะรอ Firebase
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
                      'กำลังเริ่มต้นระบบ...',
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
        },
      ),
      // เพิ่ม routes สำหรับการ navigate
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainScreen(),
      },
      // จัดการ route ที่ไม่รู้จัก
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthGuard(),
        );
      },
    );
  }
}
