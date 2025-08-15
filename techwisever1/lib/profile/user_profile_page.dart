import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/google_auth_service.dart';
import 'edit_profile_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        final data = await UserService.getUserData(user!.uid);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
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
                  // รูปโปรไฟล์
                  Center(
                    child: FutureBuilder<String?>(
                      future: user != null ? UserService.getUserPhotoURL(user!.uid) : null,
                      builder: (context, snapshot) {
                        final photoURL = snapshot.data;
                        return CircleAvatar(
                          radius: 60,
                          backgroundImage: photoURL != null
                              ? NetworkImage(photoURL)
                              : const AssetImage('assets/images/profile.png') as ImageProvider,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ข้อมูลผู้ใช้
                  _buildInfoCard('ชื่อ', user?.displayName ?? 'ไม่ระบุ'),
                  _buildInfoCard('อีเมล', user?.email ?? 'ไม่ระบุ'),
                  _buildInfoCard('ประเภทการเข้าสู่ระบบ', 
                    GoogleAuthService.isGoogleUser(user) ? 'Google Account' : 'อีเมล/รหัสผ่าน'),
                  _buildInfoCard('บทบาท (ระบบ)', userData?['role'] == 'admin' ? 'แอดมิน' : 'ผู้ใช้'),
                  _buildInfoCard('บทบาท', userData?['userRole'] ?? 'ไม่ระบุ'),
                  _buildInfoCard('ระดับชั้น', userData?['grade'] ?? 'ไม่ระบุ'),
                  _buildInfoCard('สถานที่ศึกษา', userData?['institution'] ?? 'ไม่ระบุ'),
                  _buildInfoCard('วันที่สร้าง', userData?['createdAt'] != null 
                      ? _formatDate(userData!['createdAt'])
                      : 'ไม่ระบุ'),
                  _buildInfoCard('อัปเดตล่าสุด', userData?['updatedAt'] != null 
                      ? _formatDate(userData!['updatedAt'])
                      : 'ไม่ระบุ'),

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
                              Icon(Icons.info, color: Colors.blue[700], size: 20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    }
    return 'ไม่ระบุ';
  }
} 