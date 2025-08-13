import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';
import 'admin_page.dart';
import 'user_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleAuthService.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
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
    bool isDialogOpen = false;
    
    try {
      // แสดง loading indicator แบบปลอดภัย
      isDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'กำลังเปลี่ยนบัญชี...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      // ใช้ GoogleAuthService สำหรับการเปลี่ยนบัญชี
      final userCredential = await GoogleAuthService.switchGoogleAccount();
      
      // ปิด loading dialog อย่างปลอดภัย
      if (context.mounted && isDialogOpen && Navigator.canPop(context)) {
        Navigator.pop(context);
        isDialogOpen = false;
      }
      
      if (userCredential != null && context.mounted) {
        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปลี่ยนบัญชี Google สำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // ลดเวลาการรอลง
        await Future.delayed(const Duration(milliseconds: 100));
        
        // ไม่ต้อง navigate เองเพราะ AuthGuard จะจัดการให้
        // AuthGuard จะตรวจสอบ auth state และ navigate อัตโนมัติ
      } else if (context.mounted) {
        // ผู้ใช้ยกเลิกการเปลี่ยนบัญชี
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกเลิกการเปลี่ยนบัญชี'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // ปิด loading dialog ถ้ายังเปิดอยู่
      if (context.mounted && isDialogOpen && Navigator.canPop(context)) {
        Navigator.pop(context);
        isDialogOpen = false;
      }
      
      debugPrint('Switch Google Account Error: $e');
      if (context.mounted) {
        String errorMessage = 'เกิดข้อผิดพลาดในการเปลี่ยนบัญชี';
        if (e.toString().contains('network')) {
          errorMessage = 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
        } else if (e.toString().contains('cancelled')) {
          errorMessage = 'ยกเลิกการเปลี่ยนบัญชี';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: () => _switchGoogleAccount(context),
            ),
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