import 'package:flutter/material.dart';

class AdminPrivilegePage extends StatelessWidget {
  const AdminPrivilegePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สิทธิแอดมิน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

          const Text(
            'นาย กิติ กิจดี',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          // 🔵 ปุ่ม: สร้างบทเรียน
          AdminOptionButton(
            icon: Icons.create,
            label: 'สร้างบทเรียน',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ไปยังหน้าสร้างบทเรียน")),
              );
            },
          ),

          const SizedBox(height: 16),

          // 🔵 ปุ่ม: ดูคะแนน
          AdminOptionButton(
            icon: Icons.bar_chart,
            label: 'ดูคะแนน',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ไปยังหน้าดูคะแนน")),
              );
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
                color: Colors.black.withOpacity(0.05),
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