import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/firebase_utils.dart';
import 'admin_quiz_creation_page.dart';
import 'admin_quiz_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = false;
  Map<String, dynamic> _systemStats = {};
  List<Map<String, dynamic>> _recentSubjects = [];
  List<Map<String, dynamic>> _recentQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSystemStats(),
        _loadRecentSubjects(),
        _loadRecentQuestions(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      // นับจำนวนวิชา
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('isActive', isEqualTo: true)
          .get();
      
      // นับจำนวนบทเรียน
      int totalLessons = 0;
      int totalQuestions = 0;
      
      for (final subjectDoc in subjectsSnapshot.docs) {
        final lessonsSnapshot = await FirebaseFirestore.instance
            .collection('subjects/${subjectDoc.id}/lessons')
            .where('isActive', isEqualTo: true)
            .get();
        
        totalLessons += lessonsSnapshot.docs.length;
        
        for (final lessonDoc in lessonsSnapshot.docs) {
          final questionsSnapshot = await FirebaseFirestore.instance
              .collection('subjects/${subjectDoc.id}/lessons/${lessonDoc.id}/questions')
              .where('isActive', isEqualTo: true)
              .get();
          
          totalQuestions += questionsSnapshot.docs.length;
        }
      }

      if (mounted) {
        setState(() {
          _systemStats = {
            'totalSubjects': subjectsSnapshot.docs.length,
            'totalLessons': totalLessons,
            'totalQuestions': totalQuestions,
            'lastUpdated': DateTime.now(),
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading system stats: $e');
    }
  }

  Future<void> _loadRecentSubjects() async {
    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      final subjects = <Map<String, dynamic>>[];
      for (final doc in subjectsSnapshot.docs) {
        final data = doc.data();
        subjects.add({
          'id': doc.id,
          'title': data['title'] ?? doc.id,
          'lessonCount': data['lessonCount'] ?? 0,
          'questionCount': data['questionCount'] ?? 0,
          'createdAt': data['createdAt'],
        });
      }
      
      if (mounted) {
        setState(() {
          _recentSubjects = subjects;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent subjects: $e');
    }
  }

  Future<void> _loadRecentQuestions() async {
    try {
      // ดึงคำถามล่าสุดจากทุกวิชา
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('isActive', isEqualTo: true)
          .get();
      
      final allQuestions = <Map<String, dynamic>>[];
      
      for (final subjectDoc in subjectsSnapshot.docs) {
        final lessonsSnapshot = await FirebaseFirestore.instance
            .collection('subjects/${subjectDoc.id}/lessons')
            .where('isActive', isEqualTo: true)
            .get();
        
        for (final lessonDoc in lessonsSnapshot.docs) {
          final questionsSnapshot = await FirebaseFirestore.instance
              .collection('subjects/${subjectDoc.id}/lessons/${lessonDoc.id}/questions')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .get();
          
          for (final questionDoc in questionsSnapshot.docs) {
            final data = questionDoc.data();
            allQuestions.add({
              'id': questionDoc.id,
              'text': data['text'] ?? '',
              'subject': subjectDoc.id,
              'lesson': lessonDoc.id,
              'createdAt': data['createdAt'],
            });
          }
        }
      }
      
      // เรียงตามวันที่สร้างและเลือก 5 อันแรก
      allQuestions.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      if (mounted) {
        setState(() {
          _recentQuestions = allQuestions.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading recent questions: $e');
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุ';
    
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แดชบอร์ดแอดมิน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // สถิติระบบ
                    _buildSystemStats(),
                    const SizedBox(height: 24),
                    
                    // การดำเนินการ
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    
                    // วิชาล่าสุด
                    _buildRecentSubjects(),
                    const SizedBox(height: 24),
                    
                    // คำถามล่าสุด
                    _buildRecentQuestions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSystemStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'สถิติระบบ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'วิชา',
                    value: '${_systemStats['totalSubjects'] ?? 0}',
                    icon: Icons.school,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'บทเรียน',
                    value: '${_systemStats['totalLessons'] ?? 0}',
                    icon: Icons.book,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'คำถาม',
                    value: '${_systemStats['totalQuestions'] ?? 0}',
                    icon: Icons.quiz,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'การดำเนินการด่วน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    title: 'สร้างคำถาม',
                    subtitle: 'เพิ่มคำถามใหม่',
                    icon: Icons.add_circle,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/quiz/create');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    title: 'จัดการคำถาม',
                    subtitle: 'ดูและแก้ไข',
                    icon: Icons.edit,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/quiz/manage');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSubjects() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.purple[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'วิชาล่าสุด',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentSubjects.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'ยังไม่มีวิชาในระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ..._recentSubjects.map((subject) => _buildSubjectItem(subject)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(Map<String, dynamic> subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.school,
              color: Colors.blue[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['title'] ?? 'ไม่ระบุ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'บทเรียน: ${subject['lessonCount'] ?? 0} | คำถาม: ${subject['questionCount'] ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQuestions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Colors.teal[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'คำถามล่าสุด',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentQuestions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'ยังไม่มีคำถามในระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ..._recentQuestions.map((question) => _buildQuestionItem(question)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.quiz,
                  color: Colors.teal[600],
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'วิชา: ${question['subject'] ?? 'ไม่ระบุ'} | บทเรียน: ${question['lesson'] ?? 'ไม่ระบุ'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question['text'] ?? 'ไม่ระบุ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'สร้างเมื่อ: ${_formatTimestamp(question['createdAt'])}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 