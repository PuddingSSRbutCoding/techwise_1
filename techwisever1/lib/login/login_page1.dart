import 'package:flutter/material.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/login/beforein.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 🔹 เนื้อหาหลัก
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔸 กล่องหัวข้อ
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'ลงชื่อเข้าใช้งาน',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔸 โลโก้
                  Image.asset(
                    'assets/images/RElogo.png',
                    height: 250,
                  ),
                  const SizedBox(height: 8),

                  // 🔸 ฟอร์มอีเมล
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ป้อนที่อยู่อีเมล',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔸 ฟอร์มรหัสผ่าน
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'ป้อนรหัสผ่าน',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔸 ปุ่มดำเนินการต่อ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainScreen()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ดำเนินการต่อ'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔸 ลิงก์สมัครบัญชีใหม่
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'หากไม่มีบัญชี คลิก ',
                        style: TextStyle(color: Colors.black),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UserInfoFormPage()),
                          );
                        },
                        child: const Text(
                          'สร้างบัญชี',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}