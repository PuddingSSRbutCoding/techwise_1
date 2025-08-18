import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';
import '../services/lesson_score_service.dart';
import '../services/user_service.dart';

class LessonResetPage extends StatefulWidget {
  const LessonResetPage({super.key});

  @override
  State<LessonResetPage> createState() => _LessonResetPageState();
}

class _LessonResetPageState extends State<LessonResetPage> {
  bool _isLoading = false;
  String? _resetStatus;
  final Map<String, bool> _subjectResetStatus = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  /// ตรวจสอบสิทธิ์การเข้าถึง
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAccessDeniedDialog();
      return;
    }

    // ตรวจสอบสิทธิ์: เฉพาะ techwiseofficialth@gmail.com หรือ admin
    final userEmail = user.email;
    bool isAdmin = false;
    
    try {
      isAdmin = await UserService.isAdmin(user.uid);
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }

    if (userEmail != 'techwiseofficialth@gmail.com' && !isAdmin) {
      _showAccessDeniedDialog();
      return;
    }

    // ถ้ามีสิทธิ์ ให้โหลดสถานะ
    _loadResetStatus();
  }

  /// แสดง dialog ปฏิเสธการเข้าถึง
  void _showAccessDeniedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('ไม่มีสิทธิ์เข้าถึง'),
            content: const Text(
              'คุณไม่มีสิทธิ์เข้าถึงฟีเจอร์นี้\n'
              'ฟีเจอร์รีเซ็ตบทเรียนใช้สำหรับผู้ดูแลระบบเท่านั้น',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด dialog
                  Navigator.of(context).pop(); // กลับไปหน้าหลัง
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _loadResetStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ตรวจสอบสถานะของแต่ละวิชา
      final subjects = ['electronics', 'computer'];
      for (final subject in subjects) {
        final scores = await LessonScoreService.instance.getAllLessonScores(
          uid: user.uid,
          subject: subject,
        );
        
        // ตรวจสอบว่ามีความคืบหน้าหรือไม่
        bool hasProgress = false;
        for (final score in scores.values) {
          if (score['score'] > 0 || score['completedStages'] > 0) {
            hasProgress = true;
            break;
          }
        }
        
        _subjectResetStatus[subject] = hasProgress;
      }
    } catch (e) {
      debugPrint('Error loading reset status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetSubjectProgress(String subject, String subjectName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // แสดง confirmation dialog
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('รีเซ็ตความคืบหน้า $subjectName'),
          content: Text(
            'คุณต้องการรีเซ็ตความคืบหน้าทั้งหมดของวิชา $subjectName ใช่หรือไม่?\n\n'
            '⚠️ การดำเนินการนี้จะลบ:\n'
            '• คะแนนทั้งหมด\n'
            '• ด่านที่ผ่านแล้ว\n'
            '• ความคืบหน้าทั้งหมด\n\n'
            '❌ ไม่สามารถยกเลิกได้!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('รีเซ็ต'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _resetStatus = 'กำลังรีเซ็ตความคืบหน้า $subjectName...';
      });
    }

    try {
      // เพิ่ม timeout เพื่อป้องกันการค้าง
      await ProgressService.I.resetSubjectProgress(
        uid: user.uid,
        subject: subject,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('การรีเซ็ตใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
        },
      );

      if (mounted) {
        setState(() {
          _resetStatus = '✅ รีเซ็ตความคืบหน้า $subjectName สำเร็จ';
          _subjectResetStatus[subject] = false;
        });
      }

      // รีเฟรชหน้าหลังจากรีเซ็ตสำเร็จ
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _resetStatus = null;
          });
        }
      });
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _resetStatus = '⏰ ${e.message}';
        });
      }
      
      // ล้างข้อความ timeout หลังจาก 4 วินาที
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _resetStatus = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _resetStatus = '❌ เกิดข้อผิดพลาด: $e';
        });
      }
      
      // ล้างข้อความ error หลังจาก 3 วินาที
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _resetStatus = null;
          });
        }
      });
    } finally {
      // หยุด loading หลังจากรีเซ็ตเสร็จ (ไม่ว่าจะสำเร็จหรือไม่)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetAllProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // แสดง confirmation dialog
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('รีเซ็ตความคืบหน้าทั้งหมด'),
          content: const Text(
            'คุณต้องการรีเซ็ตความคืบหน้าทั้งหมดของทุกวิชาใช่หรือไม่?\n\n'
            '⚠️ การดำเนินการนี้จะลบ:\n'
            '• คะแนนทั้งหมดของทุกวิชา\n'
            '• ด่านที่ผ่านแล้วทั้งหมด\n'
            '• ความคืบหน้าทั้งหมด\n\n'
            '❌ ไม่สามารถยกเลิกได้!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('รีเซ็ตทั้งหมด'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _resetStatus = 'กำลังรีเซ็ตความคืบหน้าทั้งหมด...';
      });
    }

    try {
      // รีเซ็ตทั้งสองวิชาพร้อม timeout
      await Future.wait([
        ProgressService.I.resetSubjectProgress(
          uid: user.uid,
          subject: 'electronics',
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('การรีเซ็ตวิชาอิเล็กทรอนิกส์ใช้เวลานานเกินไป');
          },
        ),
        ProgressService.I.resetSubjectProgress(
          uid: user.uid,
          subject: 'computer',
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException('การรีเซ็ตวิชาคอมพิวเตอร์ใช้เวลานานเกินไป');
          },
        ),
      ]);

      if (mounted) {
        setState(() {
          _resetStatus = '✅ รีเซ็ตความคืบหน้าทั้งหมดสำเร็จ';
          _subjectResetStatus['electronics'] = false;
          _subjectResetStatus['computer'] = false;
        });
      }

      // รีเฟรชหน้าหลังจากรีเซ็ตสำเร็จ
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _resetStatus = null;
          });
        }
      });
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _resetStatus = '⏰ ${e.message}';
        });
      }
      
      // ล้างข้อความ timeout หลังจาก 4 วินาที
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _resetStatus = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _resetStatus = '❌ เกิดข้อผิดพลาด: $e';
        });
      }
      
      // ล้างข้อความ error หลังจาก 3 วินาที
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _resetStatus = null;
          });
        }
      });
    } finally {
      // หยุด loading หลังจากรีเซ็ตเสร็จ (ไม่ว่าจะสำเร็จหรือไม่)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รีเซ็ตบทเรียน (สำหรับทดสอบ)'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9800), // สีส้ม
              Color(0xFFFF5722), // สีแดงส้ม
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // คำเตือน
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'คำเตือน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'หน้านี้ใช้สำหรับการทดสอบเท่านั้น การรีเซ็ตจะลบความคืบหน้าทั้งหมดและไม่สามารถกู้คืนได้',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // สถานะการรีเซ็ต
                if (_resetStatus != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _resetStatus!.contains('สำเร็จ') 
                          ? Colors.green.shade50 
                          : _resetStatus!.contains('ข้อผิดพลาด')
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _resetStatus!.contains('สำเร็จ')
                            ? Colors.green.shade200
                            : _resetStatus!.contains('ข้อผิดพลาด')
                                ? Colors.red.shade200
                                : Colors.blue.shade200,
                      ),
                    ),
                    child: Text(
                      _resetStatus!,
                      style: TextStyle(
                        color: _resetStatus!.contains('สำเร็จ')
                            ? Colors.green.shade700
                            : _resetStatus!.contains('ข้อผิดพลาด')
                                ? Colors.red.shade700
                                : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                if (_resetStatus != null) const SizedBox(height: 24),

                // ปุ่มรีเซ็ตแต่ละวิชา
                Text(
                  'รีเซ็ตแต่ละวิชา:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // วิชาอิเล็กทรอนิกส์
                _buildSubjectResetCard(
                  'electronics',
                  'อิเล็กทรอนิกส์',
                  Icons.bolt,
                  Colors.blue,
                ),

                const SizedBox(height: 12),

                // วิชาคอมพิวเตอร์
                _buildSubjectResetCard(
                  'computer',
                  'คอมพิวเตอร์',
                  Icons.computer,
                  Colors.indigo,
                ),

                const SizedBox(height: 24),

                // ปุ่มรีเซ็ตทั้งหมด
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _resetAllProgress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text(
                      'รีเซ็ตความคืบหน้าทั้งหมด',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const Spacer(),

                // หมายเหตุ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'หมายเหตุ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• การรีเซ็ตจะลบความคืบหน้าทั้งหมดของวิชานั้น\n'
                        '• คะแนนและด่านที่ผ่านแล้วจะหายไป\n'
                        '• สามารถเริ่มเรียนใหม่ได้ทันทีหลังรีเซ็ต\n'
                        '• ใช้สำหรับการทดสอบหรือเริ่มต้นใหม่เท่านั้น',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectResetCard(String subject, String subjectName, IconData icon, Color color) {
    final hasProgress = _subjectResetStatus[subject] ?? false;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasProgress ? 'มีความคืบหน้า' : 'ไม่มีความคืบหน้า',
                  style: TextStyle(
                    color: hasProgress ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _resetSubjectProgress(subject, subjectName),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasProgress ? Colors.red : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(hasProgress ? 'รีเซ็ต' : 'ไม่มีข้อมูล'),
          ),
        ],
      ),
    );
  }
}
