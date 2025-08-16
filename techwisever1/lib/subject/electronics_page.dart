import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techwisever1/main_screen.dart'; // ✅ เพิ่ม: กลับรากที่ MainScreen เสมอ
import 'package:techwisever1/services/app_nav.dart';
import 'package:techwisever1/services/progress_service.dart';
import 'package:techwisever1/services/loading_utils.dart';
import 'lesson_intro.dart';

class ElectronicsPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ElectronicsPage({super.key, this.onBack});

  @override
  State<ElectronicsPage> createState() => _ElectronicsPageState();
}

class _ElectronicsPageState extends State<ElectronicsPage> {
  static const int _requiredStagesPerLesson = 5;

  List<_LessonMeta> get _lessons => const [
        _LessonMeta(
          lesson: 1,
          title: 'บทที่ 1\nอุปกรณ์อิเล็กทรอนิกส์เบื้องต้น',
          image: 'assets/images/L1.jpg',
          intro:
              'รู้จักกับอุปกรณ์พื้นฐาน เช่น ตัวต้านทาน ตัวเก็บประจุ ไดโอด และทรานซิสเตอร์ รวมถึงการอ่านค่าและการใช้งานเบื้องต้น เพื่อปูพื้นฐานก่อนลงมือปฏิบัติ',
        ),
        _LessonMeta(
          lesson: 2,
          title: 'บทที่ 2\nอุปกรณ์ในงานไฟฟ้า',
          image: 'assets/images/L2.jpg',
          intro:
              'ศึกษาประเภทของอุปกรณ์ในงานไฟฟ้า การเลือกใช้อย่างปลอดภัย มาตรฐานสัญลักษณ์ และแนวทางการดูแลรักษาเบื้องต้น',
        ),
        _LessonMeta(
          lesson: 3,
          title: 'บทที่ 3\nสัญลักษณ์ทางอิเล็กทรอนิกส์',
          image: 'assets/images/L3.png',
          intro:
              'ฝึกอ่านและทำความเข้าใจกับสัญลักษณ์อิเล็กทรอนิกส์ในแผงวงจร เพื่อใช้วิเคราะห์และออกแบบวงจรได้อย่างถูกต้อง',
        ),
      ];

  // ✅ ไปแท็บ "หน้าหลัก" โดยให้ MainScreen เป็นรากเสมอ
  void _goHome(BuildContext context) {
    AppNav.bottomIndex.value = 0; // ไม่จำเป็นแต่เก็บไว้สอดคล้องทั้งแอป
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
      (r) => false,
    );
  }

  // ✅ ไปแท็บ "โปรไฟล์" โดยให้ MainScreen เป็นรากเสมอ (แก้ปัญหาที่คุณเจอ)
  void _goProfile(BuildContext context) {
    AppNav.bottomIndex.value = 1;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
      (r) => false,
    );
  }

  // ✅ Back ปกติ (ถอย 1 ชั้น)
  void _goBack(BuildContext context) {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

  Set<int> _computeCompletedLessons(QuerySnapshot qs) {
    final done = <int>{};
    final re = RegExp(r'^electronics_L(\d+)$');
    for (final d in qs.docs) {
      final m = re.firstMatch(d.id);
      if (m == null) continue;
      final n = int.tryParse(m.group(1)!);
      if (n == null) continue;
      final data = d.data() as Map<String, dynamic>;
      final raw = data['completedStages'];
      final list = raw is List ? List.of(raw) : <dynamic>[];
      final uniqueInts = <int>{};
      for (final e in list) {
        if (e is int) uniqueInts.add(e);
      }
      if (uniqueInts.length >= _requiredStagesPerLesson) done.add(n);
    }
    return done;
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดด้วยการแตะพื้นหลัง
      builder: (context) => AlertDialog(
        title: const Text(
          'รีเซ็ตความคืบหน้า',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'คุณต้องการรีเซ็ตความคืบหน้าทั้งหมดของวิชาอิเล็กทรอนิกส์หรือไม่?\n\n'
          '• ด่านที่ผ่านแล้วจะถูกล็อกใหม่\n'
          '• คะแนนจะถูกลบทั้งหมด\n'
          '• จะต้องเริ่มทำใหม่ตั้งแต่บทที่ 1 ด่านที่ 1\n\n'
          '⚠️ การดำเนินการนี้ไม่สามารถยกเลิกได้',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('ไม่ใช่', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performReset(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('ใช่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('กำลังรีเซ็ตความคืบหน้า...')),
            ],
          ),
        ),
      );

      // ทำการรีเซ็ท
      await ProgressService.I.resetSubjectProgress(
        uid: uid,
        subject: 'electronics',
      );

      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // แสดงข้อความสำเร็จ
      if (context.mounted) {
        LoadingUtils.showSuccess(context, 'รีเซ็ตความคืบหน้าสำเร็จ');
        
        // รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่
        setState(() {});
      }

    } catch (e) {
      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // แสดงข้อความผิดพลาด
      if (context.mounted) {
        LoadingUtils.showError(context, 'การรีเซ็ทล้มเหลว: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return WillPopScope(
      onWillPop: () async {
        _goBack(context); // ✅ ถอย 1 ชั้น
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox.expand(child: Image.asset('assets/images/backgroundselect.jpg', fit: BoxFit.cover)),

            // AppBar
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _goBack(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('บทเรียนอิเล็กทรอนิกส์',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 100, bottom: 20),
                child: uid == null
                    ? _buildList(context, const <int>{}, {}, {})
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('progress')
                            .snapshots(),
                        builder: (context, snap) {
                          final completed = snap.hasData ? _computeCompletedLessons(snap.data!) : <int>{};
                          return FutureBuilder<Map<int, Map<String, int>>>(
                            future: ProgressService.I.getLessonsTotalScores(
                              uid: uid,
                              subject: 'electronics',
                              maxLessons: _lessons.length,
                            ),
                            builder: (context, scoreSnap) {
                              final lessonScores = scoreSnap.data ?? <int, Map<String, int>>{};
                              return FutureBuilder<Map<int, int>>(
                                future: ProgressService.I.getLessonsTotalQuestions(
                                  uid: uid,
                                  subject: 'electronics',
                                  maxLessons: _lessons.length,
                                ),
                                builder: (context, questionSnap) {
                                  final lessonQuestions = questionSnap.data ?? <int, int>{};
                                  return _buildList(context, completed, lessonScores, lessonQuestions);
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
          onTap: (i) => i == 0 ? _goHome(context) : _goProfile(context),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, Set<int> completed, Map<int, Map<String, int>> lessonScores, Map<int, int> lessonQuestions) {
    final allLessonsCompleted = completed.length >= _lessons.length;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          ..._lessons.map((meta) {
            final l = meta.lesson;
            final isUnlocked = l == 1 ? true : completed.contains(l - 1);
            final lockReason = l == 1 ? null : 'ปลดล็อกเมื่อผ่านบทที่ ${l - 1}';
            final scores = lessonScores[l];
            final questions = lessonQuestions[l];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _LessonCard(
                title: meta.title,
                imagePath: meta.image,
                locked: !isUnlocked,
                lockReason: lockReason,
                scores: scores,
                questions: questions,
                onTap: () {
                  if (!isUnlocked) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonIntroPage(
                        subject: 'electronics',
                        lesson: l,
                        title: meta.cleanTitle,
                        intro: meta.intro,
                        heroAsset: meta.image,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
          
          // ปุ่มรีเซ็ต - แสดงเมื่อผ่านทุกบทเรียนแล้ว
          if (allLessonsCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _showResetDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'รีเซ็ตเพื่อทำใหม่ทั้งหมด',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

class _LessonMeta {
  final int lesson;
  final String title;
  final String image;
  final String intro;
  const _LessonMeta({required this.lesson, required this.title, required this.image, required this.intro});
  String get cleanTitle => title.replaceAll('\n', ' ');
}

class _LessonCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final bool locked;
  final String? lockReason;
  final Map<String, int>? scores;
  final int? questions;
  const _LessonCard({
    required this.title, required this.imagePath, required this.onTap, this.locked = false, this.lockReason, this.scores, this.questions,
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Opacity(opacity: locked ? 0.6 : 1.0,
                child: Image.asset(imagePath, width: double.infinity, height: 160, fit: BoxFit.cover),
              ),
              Positioned(
                left: 12, top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              // แสดงคะแนนรวมที่มุมซ้ายล่าง
              if (scores != null)
                Positioned(
                  left: 12, bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ได้คะแนน ${scores!['score']}/${questions ?? scores!['total']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 12, right: 12,
                child: ElevatedButton(
                  onPressed: locked ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('เริ่มเรียน', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              if (locked)
                Container(
                  color: Colors.black.withOpacity(0.25),
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock, color: Colors.white), const SizedBox(width: 8),
                    Text(lockReason ?? 'ปลดล็อกเมื่อผ่านบทก่อนหน้า',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
