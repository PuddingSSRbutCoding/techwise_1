import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../question/question_model.dart';
import '../services/firebase_utils.dart';

class AdminQuizManagementPage extends StatefulWidget {
  const AdminQuizManagementPage({super.key});

  @override
  State<AdminQuizManagementPage> createState() => _AdminQuizManagementPageState();
}

class _AdminQuizManagementPageState extends State<AdminQuizManagementPage> {
  String _selectedSubject = 'computer';
  String _selectedLesson = 'L1';
  bool _isLoading = false;
  List<String> _availableSubjects = [];
  List<String> _availableLessons = [];

  // รายการวิชาและบทเรียนที่มีอยู่
  final Map<String, List<String>> _existingSubjectLessons = {
    'computer': ['L1', 'L2', 'L3'],
    'electronics': ['L1', 'L2', 'L3'],
    'programming': ['L1', 'L2', 'L3'],
  };

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects();
  }

  Future<void> _loadAvailableSubjects() async {
    setState(() => _isLoading = true);
    try {
      // โหลดวิชาจาก Firebase
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .get();
      
      final subjects = <String>[];
      for (final doc in subjectsSnapshot.docs) {
        subjects.add(doc.id);
      }
      
      // รวมกับวิชาที่มีอยู่แล้ว
      final allSubjects = <String>{...subjects, ..._existingSubjectLessons.keys};
      _availableSubjects = allSubjects.toList()..sort();
      
      // โหลดบทเรียนของวิชาที่เลือก
      await _loadLessonsForSubject(_selectedSubject);
      
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      // ใช้ข้อมูลที่มีอยู่แล้ว
      _availableSubjects = _existingSubjectLessons.keys.toList();
      _loadLessonsForSubject(_selectedSubject);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLessonsForSubject(String subject) async {
    try {
      final lessonsSnapshot = await FirebaseFirestore.instance
          .collection('subjects/$subject/lessons')
          .get();
      
      final lessons = <String>[];
      for (final doc in lessonsSnapshot.docs) {
        lessons.add(doc.id);
      }
      
      // รวมกับบทเรียนที่มีอยู่แล้ว
      final existingLessons = _existingSubjectLessons[subject] ?? [];
      final allLessons = <String>{...lessons, ...existingLessons};
      _availableLessons = allLessons.toList()..sort();
      
      // เลือกบทเรียนแรกถ้าบทเรียนปัจจุบันไม่มี
      if (!_availableLessons.contains(_selectedLesson)) {
        _selectedLesson = _availableLessons.isNotEmpty ? _availableLessons.first : 'L1';
      }
      
    } catch (e) {
      debugPrint('Error loading lessons: $e');
      // ใช้ข้อมูลที่มีอยู่แล้ว
      _availableLessons = _existingSubjectLessons[subject] ?? ['L1', 'L2', 'L3'];
    }
    setState(() {});
  }

  String _getSubjectDisplayName(String subject) {
    switch (subject) {
      case 'computer':
        return 'คอมพิวเตอร์';
      case 'electronics':
        return 'อิเล็กทรอนิกส์';
      case 'programming':
        return 'การเขียนโปรแกรม';
      default:
        return subject;
    }
  }

  String _getLessonDisplayName(String lesson) {
    return 'บทที่ ${lesson.substring(1)}';
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
          'จัดการบททดสอบ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/quiz/create');
            },
            tooltip: 'สร้างคำถามใหม่',
          ),
        ],
      ),
      body: Column(
        children: [
          // ตัวเลือกวิชาและบทเรียน
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'ตัวกรอง',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            decoration: const InputDecoration(
                              labelText: 'วิชา',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school),
                            ),
                            items: _availableSubjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject,
                                child: Text(_getSubjectDisplayName(subject)),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setState(() => _selectedSubject = value);
                                await _loadLessonsForSubject(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLesson,
                            decoration: const InputDecoration(
                              labelText: 'บทเรียน',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                            ),
                            items: _availableLessons.map((lesson) {
                              return DropdownMenuItem(
                                value: lesson,
                                child: Text(_getLessonDisplayName(lesson)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLesson = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // รายการคำถาม
          Expanded(
            child: _buildQuestionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects/$_selectedSubject/lessons/$_selectedLesson/questions')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final questions = snapshot.data?.docs ?? [];

        if (questions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่มีคำถามในบทเรียนนี้',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'กดปุ่ม + เพื่อสร้างคำถามใหม่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final questionData = questions[index].data() as Map<String, dynamic>;
            final question = Question.fromMap(questionData, id: questions[index].id);
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หัวข้อคำถาม
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'คำถามที่ ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) => _handleQuestionAction(value, question, questions[index].reference),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('แก้ไข'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('ลบ'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // เนื้อหาคำถาม
                    Text(
                      question.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    
                    // ตัวเลือก
                    ...List.generate(question.options.length, (optionIndex) {
                      final option = question.options[optionIndex];
                      final letter = String.fromCharCode(65 + optionIndex);
                      final isCorrect = optionIndex == question.answerIndex;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green[50] : Colors.grey[50]!,
                          border: Border.all(
                            color: isCorrect ? Colors.green : Colors.grey[300]!,
                            width: isCorrect ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCorrect ? Colors.green : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    color: isCorrect ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCorrect)
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                      );
                    }),
                    
                    // ข้อมูลเพิ่มเติม
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'สร้างเมื่อ: ${_formatTimestamp(questionData['createdAt'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (questionData['createdBy'] != null)
                          Text(
                            'โดย: ${questionData['createdBy']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Future<void> _handleQuestionAction(String action, Question question, DocumentReference docRef) async {
    switch (action) {
      case 'edit':
        _showEditQuestionDialog(question, docRef);
        break;
      case 'delete':
        _showDeleteConfirmation(question, docRef);
        break;
    }
  }

  void _showEditQuestionDialog(Question question, DocumentReference docRef) {
    // TODO: Implement edit question dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ฟีเจอร์แก้ไขคำถามจะเปิดให้ใช้งานเร็วๆ นี้'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Question question, DocumentReference docRef) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบคำถามนี้หรือไม่?\n\n"${question.text}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseUtils.deleteDocumentWithTimeout(documentRef: docRef);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบคำถามสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

