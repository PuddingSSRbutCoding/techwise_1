import 'package:flutter/material.dart';
import 'lesson_intro.dart';

class ComputerTechPage extends StatelessWidget {
  final VoidCallback? onBack;

  const ComputerTechPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลังภาพ
          SizedBox.expand(
            child: Image.asset(
              'assets/images/backgroundselect.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // หัวข้อด้านบน
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (onBack != null) {
                        onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'บทเรียนคอมพิวเตอร์',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // รายการบทเรียน
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    LessonCard(
                      title: 'บทที่ 1\nความรู้พื้นฐานคอมพิวเตอร์',
                      imagePath: 'assets/images/TC1.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonIntroPage(
                              subject: 'computer',
                              lesson: 1,
                              title: 'ความรู้พื้นฐานคอมพิวเตอร์',
                              intro:
                                  'เริ่มต้นทำความเข้าใจองค์ประกอบของคอมพิวเตอร์ ประเภทซอฟต์แวร์/ฮาร์ดแวร์ และแนวทางใช้งานอย่างปลอดภัย ก่อนเข้าสู่แบบฝึกหัดท้ายบท',
                              heroAsset: 'assets/images/TC1.png',
                              // ไม่ระบุ onStart เพื่อใช้ default ไปหน้าแผนที่ (ComputerLessonMapPage)
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    LessonCard(
                      title: 'บทที่ 2\nเครื่องมือพัฒนา',
                      imagePath: 'assets/images/TC2.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonIntroPage(
                              subject: 'computer',
                              lesson: 2,
                              title: 'เครื่องมือพัฒนา',
                              intro:
                                  'ทำความรู้จัก IDE, เวอร์ชันคอนโทรล (เช่น Git) และการตั้งค่าสภาพแวดล้อมการพัฒนา เพื่อเตรียมพร้อมสำหรับการสร้างโปรเจกต์จริง',
                              heroAsset: 'assets/images/TC2.jpg',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    LessonCard(
                      title: 'บทที่ 3\nการเขียนโปรแกรม',
                      imagePath: 'assets/images/TC3.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonIntroPage(
                              subject: 'computer',
                              lesson: 3,
                              title: 'การเขียนโปรแกรม',
                              intro:
                                  'ปูพื้นฐานแนวคิดการเขียนโปรแกรม ตัวแปร เงื่อนไข ลูป และโครงสร้างข้อมูลง่าย ๆ พร้อมตัวอย่างก่อนทำแบบฝึกหัด',
                              heroAsset: 'assets/images/TC3.png',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'เริ่มเรียน',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
