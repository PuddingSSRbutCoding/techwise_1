// lib/subject/electronics_page.dart
import 'package:flutter/material.dart';
import 'lesson_intro.dart'; // ใช้ LessonIntroPage (เวอร์ชัน integrated)

class ElectronicsPage extends StatelessWidget {
  final VoidCallback? onBack;

  const ElectronicsPage({super.key, this.onBack});

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

          // 🔵 หัวข้อ
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
                        'บทเรียนอิเล็กทรอนิกส์',
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

          // 🔵 เนื้อหา
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    LessonCard(
                      title: 'บทที่ 1\nอุปกรณ์อิเล็กทรอนิกส์เบื้องต้น',
                      imagePath: 'assets/images/L1.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LessonIntroPage(
                              subject: 'electronics',
                              lesson: 1,
                              title: 'อุปกรณ์อิเล็กทรอนิกส์เบื้องต้น',
                              intro:
                                  'รู้จักกับอุปกรณ์พื้นฐาน เช่น ตัวต้านทาน ตัวเก็บประจุ ไดโอด และทรานซิสเตอร์ รวมถึงการอ่านค่าและการใช้งานเบื้องต้น เพื่อปูพื้นฐานก่อนลงมือปฏิบัติ',
                              heroAsset: 'assets/images/L1.jpg',
                              // ไม่ระบุ onStart -> ใช้ default ไป ElectronicsLessonMapPage(lesson: 1)
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    LessonCard(
                      title: 'บทที่ 2\nอุปกรณ์ในงานไฟฟ้า',
                      imagePath: 'assets/images/L2.jpg',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LessonIntroPage(
                              subject: 'electronics',
                              lesson: 2,
                              title: 'อุปกรณ์ในงานไฟฟ้า',
                              intro:
                                  'ศึกษาประเภทของอุปกรณ์ในงานไฟฟ้า การเลือกใช้อย่างปลอดภัย มาตรฐานสัญลักษณ์ และแนวทางการดูแลรักษาเบื้องต้น',
                              heroAsset: 'assets/images/L2.jpg',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    LessonCard(
                      title: 'บทที่ 3\nสัญลักษณ์ทางอิเล็กทรอนิกส์',
                      imagePath: 'assets/images/L3.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LessonIntroPage(
                              subject: 'electronics',
                              lesson: 3,
                              title: 'สัญลักษณ์ทางอิเล็กทรอนิกส์',
                              intro:
                                  'ฝึกอ่านและทำความเข้าใจกับสัญลักษณ์อิเล็กทรอนิกส์ในแผงวงจร เพื่อใช้วิเคราะห์และออกแบบวงจรได้อย่างถูกต้อง',
                              heroAsset: 'assets/images/L3.png',
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
