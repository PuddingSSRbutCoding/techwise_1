import 'package:flutter/material.dart';
import 'subject_card.dart';
import 'electronics_page.dart';
import 'computertech_page.dart';

class SelectSubjectPage extends StatefulWidget {
  const SelectSubjectPage({super.key});

  @override
  State<SelectSubjectPage> createState() => _SelectSubjectPageState();
}

class _SelectSubjectPageState extends State<SelectSubjectPage> {
  int _selectedIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectSubjectPage()),
      );
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไปยังหน้าโปรไฟล์")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔵 พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/images/backgroundselect.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔵 กล่องสีขาวด้านบน (เหมือนขอบด้านล่าง)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center
            ),
          ),

          // 🔵 เนื้อหา
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ฉันอยากจะเรียน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SubjectCard(
                        title: 'อิเล็กทรอนิกส์',
                        imagePath: 'assets/images/energy.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ElectronicsPage(),
                            ),
                          );
                        },
                      ),
                      SubjectCard(
                        title: 'เทคนิคคอมพิวเตอร์',
                        imagePath: 'assets/images/hacker.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ComputerTechPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}