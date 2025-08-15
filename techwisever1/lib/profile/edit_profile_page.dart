import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _institutionController = TextEditingController();
  
  String _selectedUserRole = 'นักศึกษา';
  String _selectedGrade = 'ม.1';
  File? _selectedImage;
  String? _currentPhotoURL; // เก็บ photo URL ปัจจุบัน
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _userRoles = ['ครู-อาจารย์', 'นักศึกษา', 'อื่นๆ'];
  final List<String> _grades = [
    'ม.1', 'ม.2', 'ม.3', 'ม.4', 'ม.5', 'ม.6',
    'ปวช.1', 'ปวช.2', 'ปวช.3',
    'ปวส.1', 'ปวส.2',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await UserService.getUserData(user.uid);
        final photoURL = await UserService.getUserPhotoURL(user.uid);
        if (mounted) {
          setState(() {
            _nameController.text = userData?['displayName'] ?? user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _selectedUserRole = userData?['userRole'] ?? 'นักศึกษา';
            _selectedGrade = userData?['grade'] ?? 'ม.1';
            _institutionController.text = userData?['institution'] ?? '';
            _currentPhotoURL = photoURL;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // อัปโหลดรูปภาพใหม่ถ้ามีการเลือก
      if (_selectedImage != null) {
        await UserService.updateProfileImage(user.uid, _selectedImage!);
      }

      // อัปเดต display name ใน Firebase Auth
      if (_nameController.text.isNotEmpty && _nameController.text != user.displayName) {
        await user.updateDisplayName(_nameController.text);
      }

      // อัปเดตข้อมูลใน Firestore
      await UserService.createOrUpdateUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: _nameController.text,
        photoURL: user.photoURL,
        userRole: _selectedUserRole,
        grade: _selectedGrade,
        institution: _institutionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ส่งผลลัพธ์กลับว่าได้อัปเดตข้อมูลแล้ว
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลส่วนตัว'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'บันทึก',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // รูปโปรไฟล์
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_currentPhotoURL != null
                                  ? NetworkImage(_currentPhotoURL!)
                                  : null), // แสดงรูป custom หรือรูป Google
                          child: _selectedImage == null && _currentPhotoURL == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // แสดงสถานะการล็อกอิน
                    if (user != null && GoogleAuthService.isGoogleUser(user))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_circle, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              'เข้าสู่ระบบด้วย Google',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (user != null && GoogleAuthService.isGoogleUser(user))
                      const SizedBox(height: 4),
                    if (user != null && GoogleAuthService.isGoogleUser(user))
                      Text(
                        'คุณสามารถเปลี่ยนรูปโปรไฟล์ที่แสดงในแอปได้',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ชื่อ
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // อีเมล (แสดงเพื่อให้ดูเท่านั้น)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // บทบาท (ครู-อาจารย์/นักศึกษา)
              DropdownButtonFormField<String>(
                value: _selectedUserRole,
                decoration: const InputDecoration(
                  labelText: 'บทบาท',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: _userRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedUserRole = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // ระดับชั้น
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'ระดับชั้น',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: _grades.map((String grade) {
                  return DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGrade = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // สถานที่ศึกษา
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'สถานที่ศึกษา',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกสถานที่ศึกษา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
