import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';
import '../services/profile_image_service.dart';
import 'edit_profile_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? user;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final data = await UserService.getUserData(currentUser.uid);
        setState(() {
          user = currentUser;
          userData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          user = currentUser;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลส่วนตัว'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปโปรไฟล์ (ใช้ ProfileImageService แบบ global)
                  Center(
                    child: FutureBuilder<Widget>(
                      future:
                          ProfileImageService.getCurrentUserProfileImageWidget(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            iconColor: Colors.grey,
                            iconSize: 60,
                          ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey,
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          );
                        }

                        return snapshot.data ??
                            const CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ข้อมูลผู้ใช้
                  _buildInfoCard('ชื่อ', user?.displayName ?? 'ไม่ระบุ'),
                  _buildInfoCard('อีเมล', user?.email ?? 'ไม่ระบุ'),
                  _buildInfoCard(
                    'ประเภทการเข้าสู่ระบบ',
                    GoogleAuthService.isGoogleUser(user)
                        ? 'Google Account'
                        : 'อีเมล/รหัสผ่าน',
                  ),
                  _buildInfoCard('บทบาท', userData?['userRole'] ?? 'ไม่ระบุ'),
                  _buildInfoCard('ระดับชั้น', userData?['grade'] ?? 'ไม่ระบุ'),
                  _buildInfoCard(
                    'สถานที่ศึกษา',
                    userData?['institution'] ?? 'ไม่ระบุ',
                  ),

                  const SizedBox(height: 30),

                  // ข้อมูลเพิ่มเติมสำหรับผู้ใช้ Google
                  if (GoogleAuthService.isGoogleUser(user))
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ข้อมูลสำหรับผู้ใช้ Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• คุณสามารถเปลี่ยนรูปโปรไฟล์ที่แสดงในแอปได้แม้ว่าจะเข้าสู่ระบบด้วย Google\n• รูปที่คุณเลือกจะแสดงแทนรูปจาก Google Account\n• ข้อมูลอื่นๆ สามารถแก้ไขได้ตามปกติ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ปุ่มแก้ไขข้อมูล
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                        // ถ้ามีการอัปเดตข้อมูล ให้โหลดข้อมูลใหม่
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('แก้ไขข้อมูลส่วนตัว'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
