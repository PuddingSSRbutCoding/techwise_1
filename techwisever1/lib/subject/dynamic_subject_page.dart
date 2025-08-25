import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/services/app_nav.dart';
import 'package:techwisever1/services/score_stream_service.dart';
import 'package:techwisever1/services/user_service.dart';
import 'package:techwisever1/profile/lesson_reset_page.dart';
import 'lesson_intro.dart';

class DynamicSubjectPage extends StatefulWidget {
  final String subjectId;
  final Map<String, dynamic> subjectData;
  final VoidCallback? onBack;

  const DynamicSubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectData,
    this.onBack,
  });

  @override
  State<DynamicSubjectPage> createState() => _DynamicSubjectPageState();
}

class _DynamicSubjectPageState extends State<DynamicSubjectPage> with AutomaticKeepAliveClientMixin {
  // จำนวนด่านที่ต้องผ่าน "ต่อบท" (ค่าเริ่มต้น)
  static const Map<int, int> _defaultRequiredStagesPerLessonMap = {1: 4, 2: 5, 3: 4};
  
  // เพิ่ม key สำหรับ StreamBuilder เพื่อให้รีเฟรชได้
  final GlobalKey _lessonScoresKey = GlobalKey();
  
  // เพิ่มตัวแปรสำหรับการ refresh อัตโนมัติ
  Timer? _autoRefreshTimer;
  bool _isPageActive = true;

  // รายการบทเรียนแบบไดนามิก
  List<_LessonMeta> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _startAutoRefresh();
  }

  Future<void> _loadLessons() async {
    try {
      // โหลดบทเรียนจาก Firebase
      final lessonsSnapshot = await FirebaseFirestore.instance
          .collection('subjects/${widget.subjectId}/lessons')
          .orderBy('order', descending: false)
          .get();
      
      final lessons = <_LessonMeta>[];
      for (final doc in lessonsSnapshot.docs) {
        final data = doc.data();
        final lessonNumber = int.tryParse(doc.id.substring(1)) ?? 1;
        
        lessons.add(_LessonMeta(
          lesson: lessonNumber,
          title: data['title'] ?? 'บทที่ $lessonNumber',
          image: data['image'] ?? 'assets/images/TC$lessonNumber.png',
          intro: data['intro'] ?? 'เนื้อหาบทเรียนที่ $lessonNumber',
          requiredStages: data['requiredStages'] ?? _getRequiredStages(lessonNumber),
        ));
      }
      
      // ถ้าไม่มีบทเรียนใน Firebase ให้ใช้บทเรียนเริ่มต้น
      if (lessons.isEmpty) {
        lessons.addAll(_getDefaultLessons());
      }
      
      if (mounted) {
        setState(() {
          _lessons = lessons;
        });
      }
    } catch (e) {
      debugPrint('Error loading lessons: $e');
      // ใช้บทเรียนเริ่มต้น
      if (mounted) {
        setState(() {
          _lessons = _getDefaultLessons();
        });
      }
    }
  }

  List<_LessonMeta> _getDefaultLessons() {
    return [
      _LessonMeta(
        lesson: 1,
        title: 'บทที่ 1\n${widget.subjectData['title'] ?? 'บทเรียน'}',
        image: 'assets/images/TC1.png',
        intro: 'เริ่มต้นเรียนรู้พื้นฐานของ ${widget.subjectData['title'] ?? 'วิชานี้'}',
        requiredStages: _getRequiredStages(1),
      ),
      _LessonMeta(
        lesson: 2,
        title: 'บทที่ 2\n${widget.subjectData['title'] ?? 'บทเรียน'}',
        image: 'assets/images/TC2.jpg',
        intro: 'เรียนรู้เพิ่มเติมเกี่ยวกับ ${widget.subjectData['title'] ?? 'วิชานี้'}',
        requiredStages: _getRequiredStages(2),
      ),
      _LessonMeta(
        lesson: 3,
        title: 'บทที่ 3\n${widget.subjectData['title'] ?? 'บทเรียน'}',
        image: 'assets/images/TC3.png',
        intro: 'สรุปและประยุกต์ความรู้ ${widget.subjectData['title'] ?? 'วิชานี้'}',
        requiredStages: _getRequiredStages(3),
      ),
    ];
  }

  int _getRequiredStages(int lesson) {
    return _defaultRequiredStagesPerLessonMap[lesson] ?? 4;
  }

  /// ดึงคะแนนรวมของทุกบทเรียนในวิชานี้
  Future<Map<int, Map<String, dynamic>>> _getLessonScores(String uid) async {
    try {
      // ใช้ stream และแปลงเป็น future
      final stream = ScoreStreamService.instance.getAllLessonScoresStream(
        uid: uid,
        subject: widget.subjectId,
      );
      
      // รอข้อมูลแรกจาก stream
      final result = await stream.first;
      return result;
    } catch (e) {
      debugPrint('Error getting lesson scores: $e');
      return {};
    }
  }

  // ✅ ไปแท็บ "หน้าหลัก" โดยให้ MainScreen เป็นรากเสมอ
  void _goHome(BuildContext context) {
    AppNav.bottomIndex.value = 0;
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
      
      final completedStages = scores['completedStages'] as int? ?? 0;
      final requiredStages = scores['requiredStages'] as int? ?? _getRequiredStages(lesson);
      
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
      if (_isPageActive && mounted) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
                    onPressed: () => _goBack(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'บทเรียน${widget.subjectData['title'] ?? widget.subjectId}',
                        style: const TextStyle(
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
                future: uid != null ? _checkAdminStatus() : Future.value(false),
                builder: (context, adminSnapshot) {
                  final isAdmin = adminSnapshot.data ?? false;
                  
                  if (uid == null) {
                    return _buildLessonsList(
                      completedLessons: const <int>{},
                      isAdmin: false,
                    );
                  }
                  
                  return StreamBuilder<Map<int, Map<String, dynamic>>>(
                    key: _lessonScoresKey,
                    stream: ScoreStreamService.instance.getAllLessonScoresStream(
                      uid: uid,
                      subject: widget.subjectId,
                    ),
                    builder: (context, snapshot) {
                      final lessonScores = snapshot.data ?? {};
                      final completedLessons = _computeCompletedLessons(lessonScores);
                      
                      return _buildLessonsList(
                        completedLessons: completedLessons,
                        isAdmin: isAdmin,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList({
    required Set<int> completedLessons,
    required bool isAdmin,
  }) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.school,
                color: widget.subjectData['color'] ?? Colors.blue,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subjectData['title'] ?? 'บทเรียน',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'เลือกบทเรียนที่ต้องการศึกษา',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lessons Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              final isCompleted = completedLessons.contains(lesson.lesson);
              
              return _buildLessonCard(
                lesson: lesson,
                isCompleted: isCompleted,
                isAdmin: isAdmin,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard({
    required _LessonMeta lesson,
    required bool isCompleted,
    required bool isAdmin,
  }) {
    return GestureDetector(
      onTap: () => _openLesson(lesson),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: DecorationImage(
                    image: AssetImage(lesson.image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.intro,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (isAdmin)
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'แอดมิน',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLesson(_LessonMeta lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonIntroPage(
          subject: widget.subjectId,
          lesson: lesson.lesson,
          title: lesson.title,
          intro: lesson.intro,
          heroAsset: lesson.image,
        ),
      ),
    );
  }
}

class _LessonMeta {
  final int lesson;
  final String title;
  final String image;
  final String intro;
  final int requiredStages;

  const _LessonMeta({
    required this.lesson,
    required this.title,
    required this.image,
    required this.intro,
    required this.requiredStages,
  });
}
