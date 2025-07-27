import 'package:flutter/material.dart';
import 'package:techwisever1/login/login_page1.dart';
import 'package:techwisever1/main_screen.dart';

class UserInfoFormPage extends StatelessWidget {
  const UserInfoFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final schoolController = TextEditingController();
    final emailController = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          // 🔵 พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 🔵 เนื้อหา
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // 🔷 กล่องหัวข้อโปร่งใส
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
                        'กรอกรายละเอียด',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔷 โลโก้
                    Image.asset(
                      'assets/images/RElogo.png',
                      width: 150,
                    ),
                    const SizedBox(height: 20),

                    // 🔷 ช่องกรอกข้อมูล
                    buildTextField(nameController, 'ชื่อ'),
                    const SizedBox(height: 16),
                    buildTextField(passwordController, 'รหัสผ่าน', isPassword: true),
                    const SizedBox(height: 16),
                    buildTextField(schoolController, 'สถานศึกษา'),
                    const SizedBox(height: 16),
                    buildTextField(emailController, 'ที่อยู่อีเมล'),
                    const SizedBox(height: 30),

                    // 🔷 ปุ่มดำเนินการต่อ
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 ช่องกรอกข้อความ
  Widget buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
