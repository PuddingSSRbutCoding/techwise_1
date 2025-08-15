import 'package:flutter/material.dart';

import 'services/firebase_config.dart';
import 'services/auth_state_service.dart';
import 'auth/auth_gate.dart';
import 'main_screen.dart';
import 'login/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with proper configuration
    await FirebaseConfig.initialize();
    
    // Initialize auth state service
    AuthStateService.instance.initialize();
    
    runApp(const TechWiseApp());
  } catch (e) {
    debugPrint('App initialization failed: $e');
    
    // Run app with simplified error state
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'เกิดข้อผิดพลาดในการเริ่มต้นแอป',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'กรุณาปิดแอปแล้วเปิดใหม่อีกครั้ง',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  runApp(const TechWiseApp());
                },
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class TechWiseApp extends StatelessWidget {
  const TechWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechWise',
      home: const AuthGate(),        // ✅ ใช้ AuthGate เป็นราก
      routes: {
        '/main': (_) => const MainScreen(),
        '/login': (_) => const WelcomePage(), // กันโค้ดเดิมที่อ้าง '/login'
        '/welcome': (_) => const WelcomePage(), // เพิ่ม route สำหรับ logout
      },
    );
  }
}
