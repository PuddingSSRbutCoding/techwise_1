import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';
import '../services/loading_utils.dart';
import '../services/auth_utils.dart';
import 'login_page1.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ พื้นหลัง
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ✅ เนื้อหาอยู่ตรงกลาง
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ โลโก้ + ข้อความ "ยินดีต้อนรับ"
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/RElogo.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                      const Positioned(
                        bottom: 1,
                        child: Text(
                          'ยินดีต้อนรับ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 54, 148),
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.white,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 20,
                                color: Colors.white,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 30,
                                color: Color.fromARGB(255, 156, 184, 241),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // ✅ คำอธิบาย
                  const Text(
                    'วัดระดับความรู้และความเข้าใจ\nอิเล็กทรอนิกส์ และ เทคโนโลยีคอมพิวเตอร์\nเพื่อการเรียนรู้ทุกเวลา',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // ✅ ปุ่ม Login ด้วย Email
                  buildLoginButton(
                    imagePath: 'assets/images/mail.png',
                    text: 'เข้าสู่ระบบด้วยอีเมล',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  // ✅ ปุ่มสำหรับทดสอบ - เข้าสู่หน้า main ทันที (ชั่วคราว)
                  buildLoginButton(
                    imagePath: 'assets/images/profile.png',
                    text: 'ทดสอบเข้าหน้าหลัก (ชั่วคราว)',
                    onTap: () async {
                      // สร้างบัญชีทดสอบชั่วคราวด้วยอีเมลและรหัสผ่านเดิม
                      try {
                        // ลองล็อกอินด้วยบัญชีทดสอบ
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: 'test@example.com',
                          password: 'test123',
                        );
                      } catch (e) {
                        // ถ้าไม่มีบัญชี ให้สร้างใหม่
                        try {
                          await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: 'test@example.com',
                            password: 'test123',
                          );
                          await FirebaseAuth.instance.currentUser?.updateDisplayName('ผู้ทดสอบ');
                        } catch (e2) {
                          debugPrint('Test account creation failed: $e2');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // ✅ ปุ่ม Google Sign-In (เวอร์ชันเรียบง่าย)
                  buildLoginButton(
                    imagePath: 'assets/images/google.png',
                    text: 'เข้าสู่ระบบด้วย Google',
                    onTap: () async {
                      // ตรวจสอบเครือข่ายก่อน
                      final hasNetwork = await AuthUtils.checkNetworkBeforeAuth(context);
                      if (!hasNetwork) return;

                      // แสดง loading dialog
                      LoadingUtils.showLoadingDialog(context);

                      try {
                        // ใช้ GoogleAuthService เวอร์ชันเรียบง่าย
                        final userCredential = await GoogleAuthService.signInWithGoogle();
                        
                        // ปิด loading dialog
                        LoadingUtils.hideLoadingDialog(context);
                        
                        if (userCredential != null) {
                          // สำเร็จ - AuthGuard จะจัดการ navigation ให้เอง
                          debugPrint('✅ Google Sign-In successful');
                        }
                      } catch (e) {
                        // ปิด loading dialog
                        LoadingUtils.hideLoadingDialog(context);
                        
                        debugPrint('❌ Google Sign-In failed: $e');
                        
                        // แสดงข้อความง่ายๆ
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ไม่สามารถเข้าสู่ระบบด้วย Google ได้: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ ปุ่ม Login ใช้รูปภาพอยู่ซ้ายสุด และข้อความอยู่ตรงกลาง
  Widget buildLoginButton({
    required String imagePath,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  imagePath,
                  height: 24,
                  width: 24,
                ),
              ),
            ),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
