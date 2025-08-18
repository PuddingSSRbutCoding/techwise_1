import 'package:flutter/material.dart';
import 'dart:async';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/loading_utils.dart';
import '../services/auth_utils.dart';
import '../services/fast_auth_service.dart';
import '../services/auth_state_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isBackgroundLoaded = false;

  @override
  void initState() {
    super.initState();

    // ✅ สร้าง Animation Controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // ✅ สร้าง Animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    // ✅ เริ่ม Animations
    _startAnimations();

    // ✅ Simulate background loading
    _simulateBackgroundLoading();

    // หยุด loading state ทันทีหลังจากเข้าหน้า welcome สำเร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthStateService.instance.stopLoadingAndClearData();
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  void _simulateBackgroundLoading() {
    // ✅ Simulate background loading time
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isBackgroundLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

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
          AnimatedOpacity(
            opacity: _isBackgroundLoaded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ✅ Loading Background (แสดงก่อนพื้นหลังโหลดเสร็จ)
          if (!_isBackgroundLoaded)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3C72),
                    Color(0xFF2A5298),
                    Color(0xFF4A90E2),
                  ],
                ),
              ),
            ),

          // ✅ Loading Pattern (แสดงก่อนพื้นหลังโหลดเสร็จ)
          if (!_isBackgroundLoaded)
            Positioned.fill(
              child: CustomPaint(painter: LoadingPatternPainter()),
            ),

          // ✅ เนื้อหาอยู่ตรงกลาง
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ โลโก้ + ข้อความ "ยินดีต้อนรับ"
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Image.asset(
                              'assets/images/RElogo.png',
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                            ),
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
                    ),
                  ),

                  const SizedBox(height: 5),

                  // ✅ คำอธิบาย
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: const Text(
                        'วัดระดับความรู้และความเข้าใจ\nอิเล็กทรอนิกส์ และ เทคโนโลยีคอมพิวเตอร์\nเพื่อการเรียนรู้ทุกเวลา',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ Loading Indicator (แสดงก่อนพื้นหลังโหลดเสร็จ)
                  if (!_isBackgroundLoaded)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.indigo.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'กำลังโหลด...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ✅ ปุ่ม Login ด้วย Google (แสดงหลังจากพื้นหลังโหลดเสร็จ)
                  if (_isBackgroundLoaded)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: buildLoginButton(
                          imagePath: 'assets/images/google.png',
                          text: 'เข้าสู่ระบบด้วย Google',
                          onTap: () async {
                            // แสดง loading dialog
                            LoadingUtils.showSimpleLoading(
                              context,
                              message: 'กำลังเข้าสู่ระบบ...',
                            );

                            try {
                              // ใช้ GoogleAuthService สำหรับการ sign in พร้อม timeout ที่สั้นลง
                              final userCredential =
                                  await GoogleAuthService.signInWithGoogle()
                                      .timeout(
                                        const Duration(
                                          seconds: 15,
                                        ), // ลดจาก 30 เป็น 15 วินาที
                                        onTimeout: () => throw TimeoutException(
                                          'การเข้าสู่ระบบใช้เวลานานเกินไป',
                                        ),
                                      );

                              if (userCredential != null &&
                                  userCredential.user != null) {
                                final user = userCredential.user!;

                                try {
                                  // ใช้ FastAuthService เพื่อบันทึกข้อมูลในพื้นหลังแบบไม่บล็อก UI
                                  FastAuthService.saveUserDataInBackground(
                                    user,
                                  );

                                  debugPrint(
                                    '✅ User data being saved in background',
                                  );
                                } catch (userDataError) {
                                  debugPrint(
                                    '⚠️ User data creation failed (continuing anyway): $userDataError',
                                  );
                                  // ไม่ throw error ที่นี่ เพราะ authentication สำเร็จแล้ว
                                }

                                // ปิด loading dialog
                                LoadingUtils.hideLoading(context);

                                // นำทางทันที - ไม่ต้องรอข้อมูล
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
                              String errorMessage =
                                  'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';

                              if (e is TimeoutException ||
                                  e.toString().contains('timeout')) {
                                errorMessage =
                                    'การเข้าสู่ระบบใช้เวลานานเกินไป กรุณาลองใหม่';
                              } else if (e.toString().contains('network')) {
                                errorMessage =
                                    'ปัญหาการเชื่อมต่อเครือข่าย กรุณาตรวจสอบอินเทอร์เน็ต';
                              } else if (e.toString().contains(
                                'ApiException: 10',
                              )) {
                                errorMessage =
                                    'ปัญหาการตั้งค่า Google Sign-In กรุณาติดต่อผู้ดูแลระบบ';
                              }

                              // ใช้ AuthUtils สำหรับการแสดง error
                              if (context.mounted) {
                                AuthUtils.showAuthError(context, errorMessage);
                              }
                            }
                          },
                        ),
                      ),
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
                child: Image.asset(imagePath, height: 24, width: 24),
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

// ✅ Loading Pattern Painter สำหรับพื้นหลัง loading
class LoadingPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    // วาดเส้นแนวตั้ง
    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // วาดเส้นแนวนอน
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // วาดวงกลมเล็กๆ
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += 120) {
      for (double j = 0; j < size.height; j += 120) {
        canvas.drawCircle(Offset(i, j), 3, circlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
