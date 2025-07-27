import 'package:flutter/material.dart';
import 'admin_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    backgroundImage: AssetImage('assets/images/google.png'),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'นาย กิติ ศิริติ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // 🔷 เมนูโปรไฟล์
                buildProfileMenu(icon: Icons.settings, text: 'การตั้งค่า', onTap: () {
                  // TODO: ไปยังหน้าการตั้งค่า
                }),
                buildProfileMenu(icon: Icons.logout, text: 'ออกจากระบบ', onTap: () {
                  // TODO: ดำเนินการออกจากระบบ
                }),
                buildProfileMenu(icon: Icons.verified_user, text: 'สิทธิแอดมิน', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPrivilegePage()),
                  );
                }),

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