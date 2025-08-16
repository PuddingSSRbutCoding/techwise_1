import 'package:flutter/material.dart';
import 'dart:async';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/loading_utils.dart';
import '../services/auth_utils.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // ✅ ช่วยเคลียร์ stack แล้วเข้า Main เป็นราก
  void _goMainRoot(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

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
                              Shadow(blurRadius: 10, color: Colors.white, offset: Offset(0, 0)),
                              Shadow(blurRadius: 20, color: Colors.white, offset: Offset(0, 0)),
                              Shadow(blurRadius: 30, color: Color.fromARGB(255, 156, 184, 241), offset: Offset(0, 0)),
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

                  // ✅ ปุ่ม Login ด้วย Google
                  buildLoginButton(
                    imagePath: 'assets/images/google.png',
                    text: 'เข้าสู่ระบบด้วย Google',
                    onTap: () async {
                      // แสดง loading dialog
                      LoadingUtils.showSimpleLoading(context, message: 'กำลังเข้าสู่ระบบ...');

                      try {
                        // ใช้ GoogleAuthService สำหรับการ sign in พร้อม timeout
                        final userCredential = await GoogleAuthService.signInWithGoogle().timeout(
                          const Duration(seconds: 30),
                          onTimeout: () => throw TimeoutException('การเข้าสู่ระบบใช้เวลานานเกินไป'),
                        );

                        if (userCredential != null && userCredential.user != null) {
                          final user = userCredential.user!;
                          
                          try {
                            // สร้างหรืออัปเดตข้อมูลผู้ใช้ใน Firestore ทันที
                            await UserService.createOrUpdateUser(
                              uid: user.uid,
                              email: user.email ?? '',
                              displayName: user.displayName,
                              photoURL: user.photoURL,
                            ).timeout(
                              const Duration(seconds: 10),
                              onTimeout: () => throw TimeoutException('การสร้างข้อมูลผู้ใช้ใช้เวลานานเกินไป'),
                            );
                            
                            debugPrint('✅ User data created/updated successfully');
                          } catch (userDataError) {
                            debugPrint('⚠️ User data creation failed (continuing anyway): $userDataError');
                            // ไม่ throw error ที่นี่ เพราะ authentication สำเร็จแล้ว
                          }

                          // ปิด loading dialog
                          LoadingUtils.hideLoading(context);

                          // นำทางทันที - AuthStateService จะจัดการโหลดข้อมูลเองในพื้นหลัง
                          if (context.mounted) {
                            // ใช้ Future.microtask เพื่อให้การนำทางเกิดขึ้นทันทีหลังจากปิด loading
                            Future.microtask(() => _goMainRoot(context));
                          }
                        } else {
                          // ปิด loading dialog
                          LoadingUtils.hideLoading(context);
                        }
                      } catch (e) {
                        // ปิด loading dialog
                        LoadingUtils.hideLoading(context);

                        debugPrint('Google Sign-In Error: $e');
                        
                        // แสดง error message ที่เหมาะสม
                        String errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
                        
                        if (e is TimeoutException || e.toString().contains('timeout')) {
                          errorMessage = 'การเข้าสู่ระบบใช้เวลานานเกินไป กรุณาลองใหม่';
                        } else if (e.toString().contains('network')) {
                          errorMessage = 'ปัญหาการเชื่อมต่อเครือข่าย กรุณาตรวจสอบอินเทอร์เน็ต';
                        } else if (e.toString().contains('ApiException: 10')) {
                          errorMessage = 'ปัญหาการตั้งค่า Google Sign-In กรุณาติดต่อผู้ดูแลระบบ';
                        }
                        
                        // ใช้ AuthUtils สำหรับการแสดง error
                        if (context.mounted) {
                          AuthUtils.showAuthError(context, errorMessage);
                        }
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
