import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../question/question_model.dart';
import '../services/firebase_utils.dart';

class AdminQuizCreationPage extends StatefulWidget {
  const AdminQuizCreationPage({super.key});

  @override
  State<AdminQuizCreationPage> createState() => _AdminQuizCreationPageState();
}

class _AdminQuizCreationPageState extends State<AdminQuizCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _subjectController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _selectedAnswerIndex = 0;
  String _selectedSubject = 'computer';
  String _selectedLesson = 'L1';
  bool _isLoading = false;
  bool _isCustomSubject = false;

  // รายการวิชาและบทเรียนที่มีอยู่
  final Map<String, List<String>> _existingSubjectLessons = {
    'computer': ['L1', 'L2', 'L3'],
    'electronics': ['L1', 'L2', 'L3'],
    'programming': ['L1', 'L2', 'L3'],
  };

  @override
  void initState() {
    super.initState();
    _subjectController.text = 'computer';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _subjectController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    _selectedAnswerIndex = 0;
    setState(() {});
  }

  void _toggleCustomSubject() {
    setState(() {
      _isCustomSubject = !_isCustomSubject;
      if (_isCustomSubject) {
        _subjectController.clear();
      } else {
        _subjectController.text = _selectedSubject;
      }
    });
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ไม่พบผู้ใช้');

      final isAdmin = await UserService.isAdmin(user.uid);
      if (!isAdmin) throw Exception('คุณไม่มีสิทธิ์แอดมิน');

      // ตรวจสอบว่าวิชาและบทเรียนถูกต้อง
      final subject = _isCustomSubject ? _subjectController.text.trim() : _selectedSubject;
      final lesson = _selectedLesson;
      
      if (subject.isEmpty) throw Exception('กรุณาระบุชื่อวิชา');
      if (lesson.isEmpty) throw Exception('กรุณาเลือกบทเรียน');

      // สร้าง Question object
      final question = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _questionController.text.trim(),
        options: _optionControllers.map((c) => c.text.trim()).toList(),
        answerIndex: _selectedAnswerIndex,
      );

      if (!question.isValid) {
        throw Exception('ข้อมูลคำถามไม่ถูกต้อง');
      }

      // บันทึกลง Firebase
      await FirebaseUtils.saveQuestion(
        subject: subject,
        lesson: lesson,
        question: question,
      );

      // อัปเดตรายการวิชาและบทเรียนในหน่วยความจำ
      if (_isCustomSubject && !_existingSubjectLessons.containsKey(subject)) {
        _existingSubjectLessons[subject] = [lesson];
      } else if (_isCustomSubject && !_existingSubjectLessons[subject]!.contains(lesson)) {
        _existingSubjectLessons[subject]!.add(lesson);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกคำถามสำเร็จในวิชา $subject บทเรียน $lesson!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'สร้างบททดสอบ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ส่วนเลือกวิชา
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'เลือกวิชา',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isCustomSubject,
                            onChanged: (value) => _toggleCustomSubject(),
                          ),
                          Text(
                            _isCustomSubject ? 'วิชาใหม่' : 'วิชาที่มีอยู่',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isCustomSubject) ...[
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อวิชาใหม่',
                            hintText: 'เช่น คณิตศาสตร์, วิทยาศาสตร์, ภาษาไทย',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.add_circle_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณาระบุชื่อวิชา';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: const InputDecoration(
                            labelText: 'วิชา',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.book),
                          ),
                          items: _existingSubjectLessons.keys.map((subject) {
                            String displayName;
                            switch (subject) {
                              case 'computer':
                                displayName = 'คอมพิวเตอร์';
                                break;
                              case 'electronics':
                                displayName = 'อิเล็กทรอนิกส์';
                                break;
                              case 'programming':
                                displayName = 'การเขียนโปรแกรม';
                                break;
                              default:
                                displayName = subject;
                            }
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSubject = value;
                                _selectedLesson = _existingSubjectLessons[value]!.first;
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLesson,
                        decoration: const InputDecoration(
                          labelText: 'บทเรียน',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                        ),
                        items: (_isCustomSubject 
                          ? ['L1', 'L2', 'L3'] 
                          : _existingSubjectLessons[_selectedSubject] ?? ['L1', 'L2', 'L3']
                        ).map((lesson) {
                          return DropdownMenuItem(
                            value: lesson,
                            child: Text('บทที่ ${lesson.substring(1)}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLesson = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ส่วนสร้างคำถาม
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.quiz, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'สร้างคำถาม',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'คำถาม',
                          hintText: 'พิมพ์คำถามของคุณที่นี่...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณาพิมพ์คำถาม';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ส่วนตัวเลือก
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list_alt, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'ตัวเลือกคำตอบ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(4, (index) {
                        final letter = String.fromCharCode(65 + index); // A, B, C, D
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: _selectedAnswerIndex,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedAnswerIndex = value);
                                  }
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'ตัวเลือก $letter',
                                    hintText: 'พิมพ์ตัวเลือก $letter...',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _selectedAnswerIndex == index 
                                          ? Colors.green 
                                          : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          letter,
                                          style: TextStyle(
                                            color: _selectedAnswerIndex == index 
                                              ? Colors.white 
                                              : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'กรุณาพิมพ์ตัวเลือก $letter';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'บันทึกคำถาม',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

