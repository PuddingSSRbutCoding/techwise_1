import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../profile/lesson_reset_page.dart'; // เพิ่ม import สำหรับ LessonResetPage

class LessonProgressPage extends StatefulWidget {
  final String subject;
  final int lesson;

  const LessonProgressPage({
    super.key,
    required this.subject,
    required this.lesson,
  });

  @override
  State<LessonProgressPage> createState() => _LessonProgressPageState();
}

class _LessonProgressPageState extends State<LessonProgressPage> {
  bool _loading = true;
  Map<String, dynamic>? _lessonData;
  List<Map<String, dynamic>> _stagesData = [];

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  /// โหลดข้อมูลบทเรียนจาก Firebase
  Future<void> _loadLessonData() async {
    try {
      setState(() => _loading = true);

      // ดึงข้อมูลบทเรียนจาก lesson_words collection
      final lessonDoc = await FirebaseFirestore.instance
          .collection('lesson_words')
          .doc('${widget.subject}_${widget.lesson}_1')
          .get();

      if (lessonDoc.exists) {
        _lessonData = lessonDoc.data();
      }

      // ดึงข้อมูลด่านทั้งหมดของบทเรียนนี้
      final stagesQuery = await FirebaseFirestore.instance
          .collection('lesson_words')
          .where('subject', isEqualTo: widget.subject)
          .where('lesson', isEqualTo: widget.lesson)
          .orderBy('state')
          .get();

      _stagesData = stagesQuery.docs
          .map((doc) => {'id': doc.id, 'data': doc.data()})
          .toList();

      setState(() => _loading = false);
    } catch (e) {
      print('Error loading lesson data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/images/backgroundselect.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // หัวข้อบทเรียน
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(
                        _lessonData?['title'] ??
                            'บทที่ ${widget.lesson} ${widget.subject}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          // ปุ่มรีเซ็ตบทเรียนสำหรับแอดมิน (ซ่อนไว้เสมอ)
          Positioned(
            top: 40,
            right: 20,
            child: FutureBuilder<bool>(
              future: _checkAdminStatus(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LessonResetPage(),
                          ),
                        );
                      },
                      tooltip: 'รีเซ็ตบทเรียน (สำหรับแอดมิน)',
                    ),
                  );
                }
                return const SizedBox.shrink(); // ซ่อนปุ่มถ้าไม่ใช่แอดมิน
              },
            ),
          ),

          // ด่าน
          Positioned.fill(
            top: 120,
            bottom: 100,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < _stagesData.length; i++) ...[
                          _buildStageButton(
                            context,
                            i + 1,
                            _stagesData[i],
                            isUnlocked:
                                i == 0 ||
                                _stagesData[i - 1]['data']['completed'] == true,
                          ),
                          if (i < _stagesData.length - 1) _buildConnector(),
                        ],
                      ],
                    ),
                  ),
          ),

          // ตัวละครล่างซ้าย-ขวา
          Positioned(
            bottom: 0,
            left: 10,
            child: Image.asset('assets/images/TC student.png', height: 120),
          ),
          Positioned(
            bottom: 0,
            right: 10,
            child: Image.asset('assets/images/TC student.png', height: 120),
          ),
        ],
      ),

      // BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        onTap: (index) {
          // TODO: เพิ่มการนำทางตาม index
        },
      ),
    );
  }

  Widget _buildStageButton(
    BuildContext context,
    int stage,
    Map<String, dynamic> stageData, {
    required bool isUnlocked,
  }) {
    final data = stageData['data'] as Map<String, dynamic>;
    final title = data['title'] ?? 'ด่าน $stage';
    final completed = data['completed'] == true;

    return GestureDetector(
      onTap: isUnlocked
          ? () {
              // นำทางไปยังหน้าด่านที่เลือก
              _navigateToStage(stage, stageData);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
        ), // ✅ เพิ่ม margin ให้กว้างขึ้น
        padding: const EdgeInsets.all(12), // ✅ เพิ่ม padding ให้กว้างขึ้น
        decoration: BoxDecoration(
          color: isUnlocked
              ? (completed ? Colors.green : Colors.white)
              : Colors.grey.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(15),
          // ✅ ลบ shadow ออก
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withValues(alpha: 0.2),
          //     blurRadius: 4,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            Text(
              'ด่าน $stage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isUnlocked ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (completed)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Container(width: 4, height: 20, color: Colors.black);
  }

  /// นำทางไปยังหน้าด่านที่เลือก
  void _navigateToStage(int stage, Map<String, dynamic> stageData) {
    // TODO: นำทางไปยังหน้าด่านที่เลือก
    print('Navigating to stage $stage: ${stageData['id']}');

    // แสดงข้อมูลด่าน
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ด่าน $stage'),
          content: Text('คุณต้องการไปยังด่าน $stage ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: นำทางไปยังหน้าด่าน
              },
              child: const Text('ไป'),
            ),
          ],
        );
      },
    );
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
}
