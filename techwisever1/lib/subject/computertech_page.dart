// lib/subject/computertech_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:techwisever1/main_screen.dart'; // ✅ กลับรากที่ MainScreen เสมอ
import 'package:techwisever1/services/app_nav.dart';
import 'package:techwisever1/services/progress_service.dart';
import 'package:techwisever1/services/loading_utils.dart';
import 'package:techwisever1/services/lesson_score_service.dart';
import 'package:techwisever1/services/score_stream_service.dart'; // เพิ่ม import สำหรับ ScoreStreamService
import 'package:techwisever1/services/user_service.dart'; // เพิ่ม import สำหรับ UserService
import 'package:techwisever1/profile/lesson_reset_page.dart'; // เพิ่ม import สำหรับ LessonResetPage
import 'lesson_intro.dart';

class ComputerTechPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ComputerTechPage({super.key, this.onBack});

  @override
  State<ComputerTechPage> createState() => _ComputerTechPageState();
}

class _ComputerTechPageState extends State<ComputerTechPage> with AutomaticKeepAliveClientMixin {
  // ✅ จำนวนด่านที่ต้องผ่าน "ต่อบท" ตาม Firebase: บท 1=4, บท 2=5, บท 3=4
  static const Map<int, int> _requiredStagesPerLessonMap = {1: 4, 2: 5, 3: 4};
  static int _requiredFor(int lesson) =>
      _requiredStagesPerLessonMap[lesson] ?? 4;
  
  // เพิ่ม key สำหรับ StreamBuilder เพื่อให้รีเฟรชได้
  final GlobalKey _lessonScoresKey = GlobalKey();
  
  // เพิ่มตัวแปรสำหรับการ refresh อัตโนมัติ
  Timer? _autoRefreshTimer;
  bool _isPageActive = true;

  // ✅ รายการบท (ปรับเพิ่มได้ตามต้องการ)
  List<_LessonMeta> get _lessons => const [
    _LessonMeta(
      lesson: 1,
      title: 'บทที่ 1\nความรู้พื้นฐานคอมพิวเตอร์',
      image: 'assets/images/TC1.png',
      intro:
          'เริ่มต้นทำความเข้าใจองค์ประกอบของคอมพิวเตอร์ ประเภทซอฟต์แวร์/ฮาร์ดแวร์ และแนวทางใช้งานอย่างปลอดภัย ก่อนเข้าสู่แบบฝึกหัดท้ายบท',
    ),
    _LessonMeta(
      lesson: 2,
      title: 'บทที่ 2\nเครื่องมือพัฒนา',
      image: 'assets/images/TC2.jpg',
      intro:
          'ทำความรู้จัก IDE, เวอร์ชันคอนโทรล (เช่น Git) และการตั้งค่าสภาพแวดล้อมการพัฒนา เพื่อเตรียมพร้อมสำหรับการสร้างโปรเจกต์จริง',
    ),
    _LessonMeta(
      lesson: 3,
      title: 'บทที่ 3\nการเขียนโปรแกรม',
      image: 'assets/images/TC3.png',
      intro:
          'ปูพื้นฐานแนวคิดการเขียนโปรแกรม ตัวแปร เงื่อนไข ลูป และโครงสร้างข้อมูลง่าย ๆ พร้อมตัวอย่างก่อนทำแบบฝึกหัด',
    ),
    // 👉 เพิ่มบท 4,5,... ได้โดยเติมบล็อกด้านบน
  ];

  /// ดึงคะแนนรวมของทุกบทเรียนในวิชาคอมพิวเตอร์
  Future<Map<int, Map<String, dynamic>>> _getLessonScores(String uid) async {
    try {
      return await LessonScoreService.instance.getAllLessonScores(
        uid: uid,
        subject: 'computer',
      );
    } catch (e) {
      debugPrint('Error getting lesson scores: $e');
      return {};
    }
  }

  // ✅ ไปแท็บ "หน้าหลัก" โดยให้ MainScreen เป็นรากเสมอ
  void _goHome(BuildContext context) {
    AppNav.bottomIndex.value = 0; // คงค่าไว้ให้สอดคล้องทั้งแอป
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
      (r) => false,
    );
  }

  // ✅ ไปแท็บ "โปรไฟล์" โดยให้ MainScreen เป็นรากเสมอ
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

  /// คำนวณบทเรียนที่ผ่านแล้วจากคะแนน
  Set<int> _computeCompletedLessons(Map<int, Map<String, dynamic>> lessonScores) {
    final done = <int>{};
    
    for (final entry in lessonScores.entries) {
      final lesson = entry.key;
      final scores = entry.value;
      
      // ตรวจสอบจาก completedStages แทนที่จะดูจาก isCompleted
      final completedStages = scores['completedStages'] as int? ?? 0;
      final requiredStages = scores['requiredStages'] as int? ?? 5;
      
      // ถ้าผ่านด่านที่จำเป็นครบแล้ว ถือว่าบทเรียนนั้นเสร็จสมบูรณ์
      if (completedStages >= requiredStages) {
        done.add(lesson);
      }
    }
    
    return done;
  }

  /// ตรวจสอบสิทธิ์แอดมิน
  Future<bool> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        return await UserService.isAdmin(user.uid);
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;
  
  /// เริ่มการ refresh อัตโนมัติ
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isPageActive) {
        setState(() {
          // Trigger rebuild เพื่อ refresh ข้อมูล
        });
      }
    });
  }
  
  /// หยุดการ refresh อัตโนมัติ
  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
  
  /// เรียกใช้เมื่อหน้าได้รับ focus
  void _onPageResume() {
    _isPageActive = true;
    _startAutoRefresh();
    setState(() {
      // Refresh ข้อมูลเมื่อกลับมาหน้า
    });
  }
  
  /// เรียกใช้เมื่อหน้าสูญเสีย focus
  void _onPagePause() {
    _isPageActive = false;
    _stopAutoRefresh();
  }

  /// รีเฟรชคะแนนแบบ force refresh
  Future<void> _refreshScores(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // แสดง loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('กำลังรีเฟรชคะแนน...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Force refresh ข้อมูลคะแนน
      await ScoreStreamService.instance.forceRefresh(
        uid: user.uid,
        subject: 'computer',
      );
      
      // รอสักครู่เพื่อให้ Firebase อัปเดตข้อมูล
      await Future.delayed(const Duration(milliseconds: 500));
      
      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // แสดงข้อความสำเร็จ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รีเฟรชคะแนนสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('การรีเฟรชคะแนนล้มเหลว: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool get allLessonsCompleted {
    // ตรวจสอบว่าผ่านทุกบทเรียนแล้วหรือไม่
    // ต้องมีบทเรียนอย่างน้อย 1 บท
    return _lessons.isNotEmpty;
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
          'คุณต้องการรีเซ็ตความคืบหน้าทั้งหมดของวิชาคอมพิวเตอร์หรือไม่?\n\n'
          '• ด่านที่ผ่านแล้วจะถูกล็อกใหม่\n'
          '• คะแนนจะถูกลบทั้งหมด\n'
          '• จะต้องเริ่มทำใหม่ตั้งแต่บทที่ 1 ด่านที่ 1\n\n'
          '⚠️ การดำเนินการนี้ไม่สามารถยกเลิกได้',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
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
            child: const Text(
              'ใช่',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
        subject: 'computer',
      );

      // รอสักครู่เพื่อให้ Firebase อัปเดตข้อมูล
      await Future.delayed(const Duration(milliseconds: 500));

      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // แสดงข้อความสำเร็จ
      if (context.mounted) {
        LoadingUtils.showSuccess(context, 'รีเซ็ตความคืบหน้าสำเร็จ');

        // รีเฟรชหน้าเพื่อแสดงข้อมูลใหม่
        setState(() {});
        
        // รอ 3 วินาทีแล้วรีเฟรชหน้าทันที
        await Future.delayed(const Duration(seconds: 3));
        if (context.mounted) {
          setState(() {});
        }
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
            // ✅ ปรับปรุงพื้นหลังให้โหลดเร็วขึ้นและสวยงาม
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3C72), // สีน้ำเงินเข้ม
                    Color(0xFF2A5298), // สีน้ำเงินกลาง
                    Color(0xFF4A90E2), // สีน้ำเงินอ่อน
                  ],
                ),
              ),
            ),

            // ✅ เพิ่มพื้นหลังแบบ pattern เพื่อความสวยงาม
            Positioned.fill(
              child: CustomPaint(painter: BackgroundPatternPainter()),
            ),

            // AppBar (สไตล์เดียวกับ electronics_page)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _goBack(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'วิชาเทคนิคคอมพิวเตอร์',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // ปุ่มรีเฟรชคะแนน
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.indigo),
                        onPressed: () => _refreshScores(context),
                        tooltip: 'รีเฟรชคะแนน',
                      ),
                      // ปุ่มรีเซ็ตบทเรียนสำหรับแอดมิน (ซ่อนไว้เสมอ)
                      FutureBuilder<bool>(
                        future: _checkAdminStatus(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.orange),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LessonResetPage(),
                                  ),
                                );
                              },
                              tooltip: 'รีเซ็ตบทเรียน (สำหรับแอดมิน)',
                            );
                          }
                          return const SizedBox.shrink(); // ซ่อนปุ่มถ้าไม่ใช่แอดมิน
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // เนื้อหาหน้า
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              bottom: 0,
              child: StreamBuilder<Map<int, Map<String, dynamic>>>(
                key: _lessonScoresKey,
                stream: uid != null ? ScoreStreamService.instance.getAllLessonScoresStream(uid: uid, subject: 'computer') : Stream.value({}),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  final lessonScores = snapshot.data ?? {};
                  final completed = _computeCompletedLessons(lessonScores);

                  return StreamBuilder<bool>(
                    stream: uid != null 
                        ? ScoreStreamService.instance.getSubjectCompletionStream(uid: uid, subject: 'computer')
                        : Stream.value(false),
                    builder: (context, subjectSnapshot) {
                      final allLessonsCompleted = subjectSnapshot.data ?? false;

                      return FutureBuilder<bool>(
                        future: _checkAdminStatus(),
                        builder: (context, adminSnapshot) {
                          final isAdmin = adminSnapshot.data ?? false;

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                ..._lessons.map((meta) {
                                  final l = meta.lesson;
                                  final isUnlocked = isAdmin || l == 1 || completed.contains(l - 1);
                                  final lockReason = l == 1 ? null : 'ปลดล็อกเมื่อผ่านบทที่ ${l - 1}';
                                  final scores = lessonScores[l];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _LessonCard(
                                      title: meta.title,
                                      imagePath: meta.image,
                                      locked: !isUnlocked,
                                      lockReason: lockReason,
                                      scores: scores,
                                      onTap: () {
                                        if (!isUnlocked) return;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => LessonIntroPage(
                                              subject: 'computer',
                                              lesson: l,
                                              title: meta.cleanTitle,
                                              intro: meta.intro,
                                              heroAsset: meta.image,
                                            ),
                                          ),
                                        );
                                      },
                                      allLessonsCompleted: allLessonsCompleted, // ส่งค่าไปยัง _LessonCard
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
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================ Models/Widgets ========================== */

class _LessonMeta {
  final int lesson;
  final String title;
  final String image;
  final String intro;
  const _LessonMeta({
    required this.lesson,
    required this.title,
    required this.image,
    required this.intro,
  });
  String get cleanTitle => title.replaceAll('\n', ' ');
}

class _LessonCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final bool locked;
  final String? lockReason;
  final Map<String, dynamic>? scores;
  final bool allLessonsCompleted; // เพิ่ม parameter ใหม่
  const _LessonCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    this.locked = false,
    this.lockReason,
    this.scores,
    this.allLessonsCompleted = false, // ค่าเริ่มต้นเป็น false
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
              Opacity(
                opacity: locked ? 0.6 : 1.0,
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
              // แสดงคะแนนรวมตรงด้านซ้ายล่าง
              if (scores != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      // แสดงคะแนนจริงเฉพาะเมื่อผ่านเงื่อนไขและปลดล็อกปุ่มรีเซ็ตแล้ว
                      scores!['isCompleted'] == true && allLessonsCompleted
                          ? 'ได้คะแนน ${scores!['score']}/${scores!['total']}'
                          : '??/${scores!['total']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black,
                          ),
                        ],
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

// ✅ เพิ่ม BackgroundPatternPainter สำหรับพื้นหลังแบบ pattern
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.5;

    // วาดเส้นแนวทแยงแบบ modern
    for (double i = -size.height; i < size.width + size.height; i += 80) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // วาดเส้นแนวทแยงกลับ
    for (double i = 0; i < size.width + size.height; i += 80) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }

    // วาดวงกลมแบบ floating
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // วงกลมใหญ่
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      100,
      circlePaint,
    );

    // วงกลมกลาง
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      80,
      circlePaint,
    );

    // วงกลมเล็ก
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      50,
      circlePaint,
    );

    // วงกลมเพิ่มเติม
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.3),
      40,
      circlePaint,
    );

    // วาดสี่เหลี่ยมเล็กๆ
    final rectPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, 25, 25),
      rectPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.6, 20, 20),
      rectPaint,
    );

    // วาดสี่เหลี่ยมเพิ่มเติม
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.8, size.height * 0.1, 15, 15),
      rectPaint,
    );

    // วาดเส้นโค้งแบบ modern
    final curvePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // วาดเส้นโค้งด้านบน
    final path1 = Path()
      ..moveTo(0, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.05,
        size.width,
        size.height * 0.1,
      );
    canvas.drawPath(path1, curvePaint);

    // วาดเส้นโค้งด้านล่าง
    final path2 = Path()
      ..moveTo(0, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.95,
        size.width,
        size.height * 0.9,
      );
    canvas.drawPath(path2, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
