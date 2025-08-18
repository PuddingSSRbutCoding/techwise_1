// lib/subject/electronics_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/services/score_stream_service.dart';
import 'package:techwisever1/services/user_service.dart';
import 'lesson_intro.dart'; // ใช้ LessonIntroPage (เวอร์ชัน integrated)

class ElectronicsPage extends StatelessWidget {
  final VoidCallback? onBack;

  const ElectronicsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    void goBack() {
      if (onBack != null) {
        onBack!();
      } else {
        Navigator.pop(context);
      }
    }

    void goLessons() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
        (r) => false,
      );
    }

    void goProfile() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
        (r) => false,
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

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
                    onPressed: goBack,
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
              child: FutureBuilder<bool>(
                future: uid != null ? UserService.isAdmin(uid) : Future.value(false),
                builder: (context, adminSnapshot) {
                  final isAdmin = adminSnapshot.data ?? false;
                  if (uid == null) {
                    return _ElectronicsList(
                      completedLessons: const <int>{},
                      isAdmin: false,
                      onOpenLesson: (l, title, intro, hero) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonIntroPage(
                              subject: 'electronics',
                              lesson: l,
                              title: title,
                              intro: intro,
                              heroAsset: hero,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return StreamBuilder<Map<int, Map<String, dynamic>>>(
                    stream: ScoreStreamService.instance.getAllLessonScoresStream(
                      uid: uid,
                      subject: 'electronics',
                    ),
                    builder: (context, snapshot) {
                      final lessonScores = snapshot.data ?? {};
                      final completedLessons = <int>{};
                      for (final entry in lessonScores.entries) {
                        final l = entry.key;
                        final scores = entry.value;
                        final completedStages = scores['completedStages'] as int? ?? 0;
                        final requiredStages = scores['requiredStages'] as int? ?? 5;
                        if (completedStages >= requiredStages) {
                          completedLessons.add(l);
                        }
                      }
                      return _ElectronicsList(
                        completedLessons: completedLessons,
                        isAdmin: isAdmin,
                        onOpenLesson: (l, title, intro, hero) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonIntroPage(
                                subject: 'electronics',
                                lesson: l,
                                title: title,
                                intro: intro,
                                heroAsset: hero,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) => i == 0 ? goLessons() : goProfile(),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'บทเรียน'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

class _ElectronicsList extends StatelessWidget {
  const _ElectronicsList({
    required this.completedLessons,
    required this.onOpenLesson,
    this.isAdmin = false,
  });

  final Set<int> completedLessons;
  final void Function(int lesson, String title, String intro, String heroAsset) onOpenLesson;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    bool isUnlocked(int lesson) {
      if (isAdmin) return true;
      if (lesson == 1) return true;
      return completedLessons.contains(lesson - 1);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _LessonCard(
            title: 'บทที่ 1\nอุปกรณ์อิเล็กทรอนิกส์เบื้องต้น',
            imagePath: 'assets/images/L1.jpg',
            locked: !isUnlocked(1),
            lockReason: null,
            onTap: () => onOpenLesson(
              1,
              'อุปกรณ์อิเล็กทรอนิกส์เบื้องต้น',
              'รู้จักกับอุปกรณ์พื้นฐาน เช่น ตัวต้านทาน ตัวเก็บประจุ ไดโอด และทรานซิสเตอร์ รวมถึงการอ่านค่าและการใช้งานเบื้องต้น เพื่อปูพื้นฐานก่อนลงมือปฏิบัติ',
              'assets/images/L1.jpg',
            ),
          ),
          const SizedBox(height: 20),
          _LessonCard(
            title: 'บทที่ 2\nอุปกรณ์ในงานไฟฟ้า',
            imagePath: 'assets/images/L2.jpg',
            locked: !isUnlocked(2),
            lockReason: 'ปลดล็อกเมื่อผ่านบทที่ 1',
            onTap: () => onOpenLesson(
              2,
              'อุปกรณ์ในงานไฟฟ้า',
              'ศึกษาประเภทของอุปกรณ์ในงานไฟฟ้า การเลือกใช้อย่างปลอดภัย มาตรฐานสัญลักษณ์ และแนวทางการดูแลรักษาเบื้องต้น',
              'assets/images/L2.jpg',
            ),
          ),
          const SizedBox(height: 20),
          _LessonCard(
            title: 'บทที่ 3\nสัญลักษณ์ทางอิเล็กทรอนิกส์',
            imagePath: 'assets/images/L3.png',
            locked: !isUnlocked(3),
            lockReason: 'ปลดล็อกเมื่อผ่านบทที่ 2',
            onTap: () => onOpenLesson(
              3,
              'สัญลักษณ์ทางอิเล็กทรอนิกส์',
              'ฝึกอ่านและทำความเข้าใจกับสัญลักษณ์อิเล็กทรอนิกส์ในแผงวงจร เพื่อใช้วิเคราะห์และออกแบบวงจรได้อย่างถูกต้อง',
              'assets/images/L3.png',
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final bool locked;
  final String? lockReason;

  const _LessonCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
    this.locked = false,
    this.lockReason,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
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
                  onPressed: locked ? null : onTap,
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
              if (locked)
                Container(
                  color: Colors.black.withOpacity(0.25),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        lockReason ?? 'ปลดล็อกเมื่อผ่านบทก่อนหน้า',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
