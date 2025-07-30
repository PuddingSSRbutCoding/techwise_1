import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';
import 'admin_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleAuthService.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchGoogleAccount(BuildContext context) async {
    try {
      // แสดง loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // ใช้ GoogleAuthService สำหรับการเปลี่ยนบัญชี
      final userCredential = await GoogleAuthService.switchGoogleAccount();
      
      // ปิด loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (userCredential != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปลี่ยนบัญชี Google สำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // รีเฟรชหน้า
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      // ปิด loading dialog ถ้ายังเปิดอยู่
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      debugPrint('Switch Google Account Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเปลี่ยนบัญชี: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
            child: Column(
              children: [
                const SizedBox(height: 140),

                // รูปโปรไฟล์แบบซ้อนทับ
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : const AssetImage('assets/images/google.png') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  user?.displayName ?? user?.email ?? 'ผู้ใช้',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                if (user?.email != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    user!.email!,
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
                    // TODO: ไปยังหน้าข้อมูลส่วนตัว
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้')),
                    );
                  }
                ),
                buildProfileMenu(
                  icon: Icons.settings,
                  text: 'การตั้งค่า',
                  onTap: () {
                    // TODO: ไปยังหน้าการตั้งค่า
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้')),
                    );
                  }
                ),
                // เพิ่มปุ่มเปลี่ยนบัญชี Google (แสดงเฉพาะเมื่อ login ด้วย Google)
                if (GoogleAuthService.isGoogleUser(user))
                  buildProfileMenu(
                    icon: Icons.swap_horiz,
                    text: 'เปลี่ยนบัญชี Google',
                    onTap: () => _switchGoogleAccount(context),
                  ),
                buildProfileMenu(
                  icon: Icons.logout,
                  text: 'ออกจากระบบ',
                  onTap: () => _signOut(context),
                ),
                buildProfileMenu(
                  icon: Icons.verified_user,
                  text: 'สิทธิแอดมิน',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPrivilegePage()),
                    );
                  }
                ),

                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('เวอร์ชัน 0.1.1', style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
        ],
      ),
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