import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/login/login_page1.dart';
import 'package:techwisever1/main_screen.dart';
import '../services/validation_utils.dart';
import '../services/auth_utils.dart';

class UserInfoFormPage extends StatefulWidget {
  const UserInfoFormPage({super.key});

  @override
  State<UserInfoFormPage> createState() => _UserInfoFormPageState();
}

class _UserInfoFormPageState extends State<UserInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createUserWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // ตรวจสอบเครือข่ายก่อน
    final hasNetwork = await AuthUtils.checkNetworkBeforeAuth(context);
    if (!hasNetwork) return;

    // ตรวจสอบว่ารหัสผ่านตรงกัน
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // สร้างบัญชีผู้ใช้ใหม่
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // อัปเดตข้อมูลผู้ใช้
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สร้างบัญชีสำเร็จ! ยินดีต้อนรับ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // AuthGuard จะจัดการ navigation อัตโนมัติเมื่อ auth state เปลี่ยน
        // ไม่ต้อง navigate เอง เพื่อป้องกัน loading ค้าง
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาดในการสร้างบัญชี';
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'รหัสผ่านอ่อนเกินไป กรุณาใช้รหัสผ่านที่แข็งแกร่งกว่า';
          break;
        case 'email-already-in-use':
          errorMessage = 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
          break;
        case 'invalid-email':
          errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
          break;
        case 'operation-not-allowed':
          errorMessage = 'การสร้างบัญชีด้วยอีเมลถูกปิดใช้งาน';
          break;
        case 'network-request-failed':
          errorMessage = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อ';
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ปิด',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                child: Form(
                  key: _formKey,
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
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'สร้างบัญชีใหม่',
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
                      buildTextField(
                        _nameController, 
                        'ชื่อ-นามสกุล', 
                        validator: ValidationUtils.validateDisplayName,
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        _emailController, 
                        'ที่อยู่อีเมล', 
                        keyboardType: TextInputType.emailAddress,
                        validator: ValidationUtils.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        _passwordController, 
                        'รหัสผ่าน', 
                        isPassword: true,
                        validator: (value) => ValidationUtils.validatePassword(value),
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        _confirmPasswordController, 
                        'ยืนยันรหัสผ่าน', 
                        isPassword: true,
                        isConfirmPassword: true,
                        validator: (value) => ValidationUtils.validateConfirmPassword(value, _passwordController.text),
                      ),
                      const SizedBox(height: 16),
                      buildTextField(
                        _schoolController, 
                        'สถานศึกษา', 
                        validator: ValidationUtils.validateInstitution,
                      ),
                      const SizedBox(height: 30),

                      // 🔷 ปุ่มสร้างบัญชี
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _createUserWithEmail,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'สร้างบัญชี',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🔷 ลิงก์กลับไปหน้า login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'มีบัญชีอยู่แล้ว? ',
                            style: TextStyle(color: Colors.black),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                            child: const Text(
                              'เข้าสู่ระบบ',
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
            ),
          ),
        ],
      ),
    );
  }

  // 🔵 ช่องกรอกข้อความ
  Widget buildTextField(
    TextEditingController controller, 
    String hint, 
    {
      bool isPassword = false,
      bool isConfirmPassword = false,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
    }
  ) {
    // กำหนด obscureText ตาม type ของ field
    bool obscureText = false;
    if (isPassword && !isConfirmPassword) {
      obscureText = _obscurePassword;
    } else if (isPassword && isConfirmPassword) {
      obscureText = _obscureConfirmPassword;
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: isPassword 
            ? const Icon(Icons.lock)
            : keyboardType == TextInputType.emailAddress
                ? const Icon(Icons.email)
                : const Icon(Icons.person),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    if (!isConfirmPassword) {
                      _obscurePassword = !_obscurePassword;
                    } else {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
