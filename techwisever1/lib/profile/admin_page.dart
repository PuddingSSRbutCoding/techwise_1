import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/ui_constants.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';
import 'admin_lesson_management_page.dart';
import 'admin_quiz_management_page.dart';

class AdminPrivilegePage extends StatelessWidget {
  const AdminPrivilegePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: UIConstants.surfaceColor,
        elevation: UIConstants.cardElevation,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: UIConstants.surfaceColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: UIConstants.primaryColor,
            foregroundColor: UIConstants.surfaceColor,
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(44, 44),
          ),
        ),
        title: Text(
          'สิทธิแอดมิน',
          style: TextStyle(
            color: UIConstants.textPrimaryColor, 
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // 🔵 รูปโปรไฟล์ (ซ้ำแบบหน้าโปรไฟล์ปกติ)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.asset(
                    'assets/images/profile.png', // เปลี่ยนตามภาพที่คุณใช้
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  child: Icon(Icons.camera_alt, size: 24),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),

          FutureBuilder<User?>(
            future: Future.value(FirebaseAuth.instance.currentUser),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Text(
                user?.displayName ?? user?.email ?? 'ผู้ใช้',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
            },
          ),

          const SizedBox(height: 30),

          // 🔵 ปุ่ม: แดชบอร์ดแอดมิน
          AdminOptionButton(
            icon: Icons.dashboard,
            label: 'แดชบอร์ดแอดมิน',
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final isAdmin = await UserService.isAdmin(user.uid);
                if (isAdmin) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณไม่มีสิทธิ์เข้าถึงหน้านี้'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 16),

          // 🔵 ปุ่ม: จัดการผู้ใช้
          AdminOptionButton(
            icon: Icons.people,
            label: 'จัดการผู้ใช้',
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final isAdmin = await UserService.isAdmin(user.uid);
                if (isAdmin) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminUserManagementPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณไม่มีสิทธิ์เข้าถึงหน้านี้'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 16),

          // 🔵 ปุ่ม: รีเซ็ตบทเรียน (สำหรับแอดมิน)
          AdminOptionButton(
            icon: Icons.refresh,
            label: 'รีเซ็ตบทเรียน (ทดสอบ)',
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final isAdmin = await UserService.isAdmin(user.uid);
                if (isAdmin) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminLessonManagementPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณไม่มีสิทธิ์เข้าถึงฟีเจอร์นี้'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 16),

          // 🔵 ปุ่ม: สร้างบททดสอบ
          AdminOptionButton(
            icon: Icons.quiz,
            label: 'สร้างบททดสอบ',
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final isAdmin = await UserService.isAdmin(user.uid);
                if (isAdmin) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminQuizManagementPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณไม่มีสิทธิ์เข้าถึงฟีเจอร์นี้'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 16),

          // 🔵 ปุ่ม: จัดการบททดสอบ
          AdminOptionButton(
            icon: Icons.manage_accounts,
            label: 'จัดการบททดสอบ',
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final isAdmin = await UserService.isAdmin(user.uid);
                if (isAdmin) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminQuizManagementPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คุณไม่มีสิทธิ์เข้าถึงฟีเจอร์นี้'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),


        ],
      ),
    );
  }
}

class AdminOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AdminOptionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 