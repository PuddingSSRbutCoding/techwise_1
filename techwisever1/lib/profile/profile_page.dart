import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/auth_state_service.dart';
import '../services/fast_auth_service.dart';
import '../services/profile_image_service.dart';

import 'admin_page.dart';
import 'user_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังโหลดข้อมูลผู้ใช้...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 🔷 รูปภาพปกพื้นหลังเต็มด้านบน
          Container(
            height: 250,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔷 เนื้อหาบนภาพ (ชื่อ รูปโปรไฟล์ เมนู)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 140),

                // รูปโปรไฟล์ (ใช้ ProfileImageService แบบ global)
                FutureBuilder<Widget>(
                  future: ProfileImageService.getCurrentUserProfileImageWidget(
                    radius: 50,
                    backgroundColor: Colors.white,
                    iconColor: Colors.grey,
                    iconSize: 50,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      );
                    }

                    return snapshot.data ??
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                  },
                ),

                const SizedBox(height: 10),

                Text(
                  user.displayName ?? user.email ?? 'ผู้ใช้',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    user.email!,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 30),

                // 🔷 เมนูโปรไฟล์
                buildProfileMenu(
                  icon: Icons.person,
                  text: 'ข้อมูลส่วนตัว',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserProfilePage(),
                      ),
                    );
                  },
                ),
                buildProfileMenu(
                  icon: Icons.settings,
                  text: 'การตั้งค่า',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),

                buildProfileMenu(
                  icon: Icons.logout,
                  text: 'ออกจากระบบ',
                  onTap: () => _signOut(context),
                ),

                // แสดงปุ่มสิทธิแอดมินเฉพาะผู้ดูแลเท่านั้น
                FutureBuilder<bool>(
                  future: _checkAdminStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return buildProfileMenu(
                        icon: Icons.verified_user,
                        text: 'สิทธิแอดมิน',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminPrivilegePage(),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink(); // ซ่อนปุ่มถ้าไม่ใช่แอดมิน
                  },
                ),

                // ลบปุ่มแยกต่างๆ ของแอดมินออกไปแล้ว - รวมอยู่ในปุ่ม "สิทธิแอดมิน" แล้ว

                const Spacer(),

                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'เวอร์ชัน 0.1.1',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    // แสดง confirmation dialog ก่อน logout
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ออกจากระบบ'),
          content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    // แสดง loading dialog แบบเรียบง่าย
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('กำลังออกจากระบบ...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // ล้างข้อมูล AuthStateService ก่อน
      AuthStateService.instance.clearAllData();

      // ใช้ FastAuthService สำหรับ logout แบบเร็ว
      await FastAuthService.quickSignOut();

      // ออกจาก Google Sign-In แบบไม่รอ
      GoogleAuthService.signOut().catchError((e) {
        debugPrint('⚠️ Google signOut warning: $e');
      });

      debugPrint('✅ Logout completed successfully');

      // หยุด loading state ทันทีหลังจาก logout สำเร็จ
      AuthStateService.instance.isLoadingUser.value = false;

      // ปิด loading dialog และนำทางไป welcome page
      if (context.mounted) {
        Navigator.of(context).pop(); // ปิด loading dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      // ปิด loading dialog ถ้ายังเปิดอยู่
      if (context.mounted) {
        Navigator.of(context).pop(); // ปิด loading dialog
      }

      debugPrint('Logout Error: $e');

      // หยุด loading state เมื่อเกิด error
      AuthStateService.instance.isLoadingUser.value = false;

      // หากเป็น timeout หรือ error ก็ยังให้ออกจากระบบแบบบังคับ
      if (e is TimeoutException || e.toString().contains('timeout')) {
        debugPrint('🔄 Forcing logout due to timeout...');
        try {
          // Emergency logout - เฉพาะ Firebase Auth
          await FirebaseAuth.instance.signOut().timeout(
            const Duration(seconds: 3),
          );

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (route) => false,
            );
          }
          return;
        } catch (emergencyError) {
          debugPrint('❌ Emergency logout failed: $emergencyError');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เกิดข้อผิดพลาดในการออกจากระบบ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () => _signOut(context),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // ใช้ FastAuthService แบบเร็ว
        return await FastAuthService.isAdminQuick(user.uid);
      } catch (e) {
        // Fallback ไปใช้ UserService
        try {
          return await UserService.isAdmin(user.uid);
        } catch (e2) {
          return false;
        }
      }
    }
    return false;
  }

  Widget buildProfileMenu({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
