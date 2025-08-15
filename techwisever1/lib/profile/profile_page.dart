import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/google_auth_service.dart';
import '../services/user_service.dart';
import '../services/auth_state_service.dart';
import 'admin_page.dart';
import 'user_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
      // ออกจากระบบ พร้อม timeout 8 วินาที
      await GoogleAuthService.signOut().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⚠️ Logout timeout - continuing anyway');
          return;
        },
      );
      
      debugPrint('✅ Logout completed successfully');
      
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
      
      // หากเป็น timeout หรือ error ก็ยังให้ออกจากระบบแบบบังคับ
      if (e is TimeoutException || e.toString().contains('timeout')) {
        debugPrint('🔄 Forcing logout due to timeout...');
        try {
          // Emergency logout - เฉพาะ Firebase Auth
          await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 3));
          
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
        return await UserService.isAdmin(user.uid);
      } catch (e) {
        return false;
      }
    }
    return false;
  }



  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
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
            child: user == null 
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังโหลดข้อมูลผู้ใช้...'),
                    ],
                  ),
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: AuthStateService.instance.isLoadingUser,
                  builder: (context, isLoading, child) {
                    // ถ้ากำลังโหลด แต่ใช้เวลาไม่นาน ให้แสดง UI ปกติพร้อม loading indicator เล็กๆ
                    if (isLoading) {
                      // แสดง UI ปกติแต่มี loading overlay เบาๆ
                      return Stack(
                        children: [
                          // แสดง UI หลักให้ดูไม่ว่าง
                          _buildMainProfileUI(user, context),
                          // Loading overlay แบบใส
                          Container(
                            color: Colors.white.withOpacity(0.8),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'กำลังโหลดข้อมูล...',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return ValueListenableBuilder<String?>(
                      valueListenable: AuthStateService.instance.error,
                      builder: (context, error, child) {
                        if (error != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text(
                                  'เกิดข้อผิดพลาด',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => AuthStateService.instance.refreshUserData(),
                                  child: const Text('ลองใหม่'),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ValueListenableBuilder<Map<String, dynamic>?>(
                          valueListenable: AuthStateService.instance.userData,
                          builder: (context, userData, child) {
                            return _buildMainProfileUI(user, context);
                          },
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProfileUI(User user, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 140),

        // รูปโปรไฟล์แบบซ้อนทับ
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: FutureBuilder<String?>(
            future: UserService.getUserPhotoURL(user.uid),
            builder: (context, snapshot) {
              final photoURL = snapshot.data;
              return CircleAvatar(
                radius: 46,
                backgroundImage: photoURL != null
                    ? NetworkImage(photoURL)
                    : null,
                child: photoURL == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              );
            },
          ),
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
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
              MaterialPageRoute(builder: (context) => const UserProfilePage()),
            );
          }
        ),
        buildProfileMenu(
          icon: Icons.settings,
          text: 'การตั้งค่า',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }
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
                    MaterialPageRoute(builder: (context) => const AdminPrivilegePage()),
                  );
                }
              );
            }
            return const SizedBox.shrink(); // ซ่อนปุ่มถ้าไม่ใช่แอดมิน
          },
        ),

        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('เวอร์ชัน 0.1.1', style: TextStyle(color: Colors.grey)),
        )
      ],
    );
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