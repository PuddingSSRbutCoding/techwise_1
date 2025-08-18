import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import 'admin_lesson_management_page.dart';
import 'lesson_reset_page.dart'; // เพิ่ม import สำหรับ LessonResetPage

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int totalUsers = 0;
  int adminUsers = 0;
  int regularUsers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final users = await UserService.getAllUsers();
      setState(() {
        totalUsers = users.length;
        adminUsers = users.where((user) => user['role'] == 'admin').length;
        regularUsers = users.where((user) => user['role'] == 'user').length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดแอดมิน'),
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
                  // สถิติโดยรวม
                  _buildStatsSection(),
                  const SizedBox(height: 24),

                  // เมนูการจัดการ
                  _buildManagementSection(),
                  const SizedBox(height: 24),

                  // กิจกรรมล่าสุด
                  _buildRecentActivitySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถิติโดยรวม',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'ผู้ใช้ทั้งหมด',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'แอดมิน',
                    adminUsers.toString(),
                    Icons.admin_panel_settings,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'ผู้ใช้ทั่วไป',
                    regularUsers.toString(),
                    Icons.person,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'การจัดการระบบ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildManagementOption(
              'จัดการผู้ใช้',
              'ดู แก้ไข และลบผู้ใช้ในระบบ',
              Icons.people,
              () {
                Navigator.pushNamed(context, '/admin/users');
              },
            ),
            const SizedBox(height: 12),
            _buildManagementOption(
              'จัดการบทเรียน',
              'เพิ่ม แก้ไข และลบบทเรียน',
              Icons.book,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLessonManagementPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildManagementOption(
              'รายงานสถิติ',
              'ดูสถิติการใช้งานระบบ',
              Icons.analytics,
              () {
                // TODO: Implement analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildManagementOption(
              'รีเซ็ตบทเรียน',
              'รีเซ็ตคะแนนและการทำข้อสอบของผู้ใช้ทั่วไป',
              Icons.refresh,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LessonResetPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption(String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กิจกรรมล่าสุด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'ยังไม่มีข้อมูลกิจกรรม',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 