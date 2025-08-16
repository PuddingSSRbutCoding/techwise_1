// lib/services/progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'firebase_utils.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService I = ProgressService._();
  final _db = FirebaseFirestore.instance;

  String _docId(String subject, int lesson) => '${subject.trim().toLowerCase()}_L$lesson';

  /// โหลดชุดด่านที่ผ่านแล้ว
  Future<Set<int>> loadCompletedStages({
    required String uid,
    required String subject,
    required int lesson,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(_docId(subject, lesson));
      
      final snap = await FirebaseUtils.getDocumentWithTimeout(
        documentRef: docRef,
        timeout: const Duration(seconds: 10),
      );
      
      if (!snap.exists) return <int>{};
      final data = snap.data() as Map<String, dynamic>?;
      final list = (data?['completedStages'] as List?)?.whereType<int>().toList() ?? const <int>[];
      return list.toSet();
    } catch (e) {
      // ถ้าเกิด timeout หรือ error ให้คืนค่า empty set
      return <int>{};
    }
  }

  /// เพิ่มด่านที่ผ่านแล้ว (ไม่แตะคะแนน)
  Future<void> addCompletedStage({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson));
    
    await FirebaseUtils.setDocumentWithTimeout(
      documentRef: docRef,
      data: {
        'subject': subject.trim().toLowerCase(),
        'lesson': lesson,
        'completedStages': FieldValue.arrayUnion([stage]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      options: SetOptions(merge: true),
      timeout: const Duration(seconds: 10),
    );
  }

  /// บันทึกคะแนนของด่าน (เฉพาะครั้งแรกเท่านั้น - first attempt only)
  Future<void> saveStageScore({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
    required int score,
    required int total,
    int? timeUsedSeconds,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson));
    
    // ตรวจสอบว่ามีคะแนนอยู่แล้วหรือไม่
    final doc = await FirebaseUtils.getDocumentWithTimeout(
      documentRef: docRef,
      timeout: const Duration(seconds: 10),
    );
    
    final data = doc.data() as Map<String, dynamic>?;
    final existingScores = data?['scores'] as Map<String, dynamic>?;
    if (existingScores != null && existingScores.containsKey('s$stage')) {
      // ถ้ามีคะแนนแล้ว ไม่บันทึกทับ
      return;
    }
    
    final scoreData = {
      'score': score,
      'total': total,
      'percent': total > 0 ? (score / total) : 0.0,
      'ts': FieldValue.serverTimestamp(),
    };
    
    // เพิ่มเวลาที่ใช้ถ้ามี
    if (timeUsedSeconds != null) {
      scoreData['timeUsedSeconds'] = timeUsedSeconds;
    }
    
    await FirebaseUtils.setDocumentWithTimeout(
      documentRef: docRef,
      data: {
        'subject': subject.trim().toLowerCase(),
        'lesson': lesson,
        'updatedAt': FieldValue.serverTimestamp(),
        'scores': {
          's$stage': scoreData,
        },
      },
      options: SetOptions(merge: true),
      timeout: const Duration(seconds: 10),
    );
  }

  /// อ่านคะแนนของด่าน (ถ้ามี)
  Future<Map<String, dynamic>?> getStageScore({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(_docId(subject, lesson));
      
      final snap = await FirebaseUtils.getDocumentWithTimeout(
        documentRef: docRef,
        timeout: const Duration(seconds: 10),
      );
      
      final data = snap.data() as Map<String, dynamic>?;
      final scores = data?['scores'] as Map<String, dynamic>?;
      return scores?['s$stage'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// อ่านคะแนนทั้งหมดของบทเรียน (สำหรับแสดงในหน้าแผนที่)
  Future<Map<int, Map<String, dynamic>>> getAllLessonScores({
    required String uid,
    required String subject,
    required int lesson,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(_docId(subject, lesson));
      
      final snap = await FirebaseUtils.getDocumentWithTimeout(
        documentRef: docRef,
        timeout: const Duration(seconds: 10),
      );
      
      if (!snap.exists) return {};
      
      final data = snap.data() as Map<String, dynamic>?;
      final scores = data?['scores'] as Map<String, dynamic>?;
      if (scores == null) return {};
      
      final result = <int, Map<String, dynamic>>{};
      for (final entry in scores.entries) {
        // แปลง 's1', 's2', etc. กลับเป็น int
        if (entry.key.startsWith('s')) {
          final stageNum = int.tryParse(entry.key.substring(1));
          if (stageNum != null && entry.value is Map<String, dynamic>) {
            result[stageNum] = Map<String, dynamic>.from(entry.value);
          }
        }
      }
      
      return result;
    } catch (e) {
      return {};
    }
  }

  /// คำนวณคะแนนรวมของแต่ละบทเรียนในวิชา (สำหรับแสดงในหน้าเลือกบทเรียน)
  Future<Map<int, Map<String, int>>> getLessonsTotalScores({
    required String uid,
    required String subject,
    int maxLessons = 10, // จำนวนบทสูงสุดที่จะตรวจ
  }) async {
    final result = <int, Map<String, int>>{};
    
    for (int lesson = 1; lesson <= maxLessons; lesson++) {
      try {
        final scores = await getAllLessonScores(
          uid: uid,
          subject: subject,
          lesson: lesson,
        );
        
        if (scores.isNotEmpty) {
          int totalScore = 0;
          int totalMaxScore = 0;
          
          for (final stageScore in scores.values) {
            final score = stageScore['score'] as int? ?? 0;
            final maxScore = stageScore['total'] as int? ?? 0;
            totalScore += score;
            totalMaxScore += maxScore;
          }
          
          result[lesson] = {
            'score': totalScore,
            'total': totalMaxScore,
          };
        }
      } catch (_) {
        // ถ้าไม่มีข้อมูลสำหรับบทนี้ ข้ามไป
      }
    }
    
    return result;
  }

  /// รีเซ็ตความคืบหน้าทั้งหมดของวิชา (ลบทุกบทเรียนในวิชานั้น)
  Future<void> resetSubjectProgress({
    required String uid,
    required String subject,
  }) async {
    try {
      final collection = _db
          .collection('users')
          .doc(uid)
          .collection('progress');
      
      // หาทุกเอกสารที่เริ่มต้นด้วย {subject}_L
      final querySnapshot = await FirebaseUtils.queryWithTimeout(
        query: collection.where('subject', isEqualTo: subject.trim().toLowerCase()),
        timeout: const Duration(seconds: 15),
      );
      
      // รวบรวม document references
      final docRefs = <DocumentReference>[];
      for (final doc in querySnapshot.docs) {
        docRefs.add(doc.reference);
      }
      
      // ถ้าไม่มีเอกสารจาก query ข้างต้น ให้ลองสแกนด้วย prefix
      if (docRefs.isEmpty) {
        final allDocs = await FirebaseUtils.queryWithTimeout(
          query: collection,
          timeout: const Duration(seconds: 10),
        );
        
        final prefix = '${subject.trim().toLowerCase()}_L';
        for (final doc in allDocs.docs) {
          if (doc.id.startsWith(prefix)) {
            docRefs.add(doc.reference);
          }
        }
      }
      
      // ลบเอกสารทั้งหมดพร้อม batch operation
      if (docRefs.isNotEmpty) {
        await FirebaseUtils.deleteMultipleDocuments(
          documentRefs: docRefs,
          timeout: const Duration(seconds: 20),
        );
      }
      
      // รอสักครู่เพื่อให้ Firebase อัปเดต
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      // ถ้าเกิด timeout หรือ error ให้ throw exception
      throw Exception('การรีเซ็ทล้มเหลว: $e');
    }
  }

  /// รีเซ็ตความคืบหน้าของบทเรียนเดียว
  Future<void> resetLessonProgress({
    required String uid,
    required String subject,
    required int lesson,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(_docId(subject, lesson));
      
      await FirebaseUtils.deleteDocumentWithTimeout(
        documentRef: docRef,
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      throw Exception('การรีเซ็ทบทเรียนล้มเหลว: $e');
    }
  }

  /// รีเซ็ตความคืบหน้าของด่านเดียว
  Future<void> resetStageProgress({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(_docId(subject, lesson));
      
      final doc = await FirebaseUtils.getDocumentWithTimeout(
        documentRef: docRef,
        timeout: const Duration(seconds: 10),
      );
      
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      // ลบด่านออกจาก completedStages
      final completedStages = List<int>.from(data['completedStages'] ?? []);
      completedStages.remove(stage);
      
      // ลบคะแนนของด่าน
      final scores = Map<String, dynamic>.from(data['scores'] ?? {});
      scores.remove('s$stage');
      
      // อัปเดตเอกสาร
      await FirebaseUtils.setDocumentWithTimeout(
        documentRef: docRef,
        data: {
          'completedStages': completedStages,
          'scores': scores,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        options: SetOptions(merge: true),
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      throw Exception('การรีเซ็ทด่านล้มเหลว: $e');
    }
  }

  /// ตรวจสอบว่าด่านนั้นทำแบบทดสอบแล้วหรือยัง
  Future<bool> isStageCompleted({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(_docId(subject, lesson));
      
      final snap = await FirebaseUtils.getDocumentWithTimeout(
        documentRef: docRef,
        timeout: const Duration(seconds: 10),
      );
      
      if (!snap.exists) return false;
      
      final data = snap.data() as Map<String, dynamic>?;
      final completedStages = (data?['completedStages'] as List?)?.whereType<int>().toList() ?? [];
      
      return completedStages.contains(stage);
    } catch (e) {
      return false;
    }
  }

  /// คำนวณจำนวนข้อทั้งหมดของทุกด่านในบทเรียน (รวมด่านที่ยังไม่ได้ทำ)
  Future<Map<int, int>> getLessonsTotalQuestions({
    required String uid,
    required String subject,
    int maxLessons = 10,
  }) async {
    final result = <int, int>{};
    
    // กำหนดจำนวนข้อที่แท้จริงตามโครงสร้างของแต่ละวิชา
    final Map<String, Map<int, int>> subjectQuestionMap = {
      'computer': {
        1: 35, // บทที่ 1: 35 ข้อ
        2: 45, // บทที่ 2: 45 ข้อ
        3: 35, // บทที่ 3: 35 ข้อ
        // รวมทั้งหมด: 115 ข้อ
      },
      'electronics': {
        1: 30, // บทที่ 1: 30 ข้อ
        2: 35, // บทที่ 2: 35 ข้อ
        3: 25, // บทที่ 3: 25 ข้อ
        // รวมทั้งหมด: 90 ข้อ
      },
    };
    
    for (int lesson = 1; lesson <= maxLessons; lesson++) {
      try {
        // ใช้จำนวนข้อที่กำหนดไว้ใน subjectQuestionMap
        final questionMap = subjectQuestionMap[subject.trim().toLowerCase()];
        if (questionMap != null && questionMap.containsKey(lesson)) {
          result[lesson] = questionMap[lesson]!;
        } else {
          // Fallback: ตรวจสอบจากคอลเล็กชัน questions
          final questionsQuery = await _db
              .collection('questions')
              .where('subject', isEqualTo: subject.trim().toLowerCase())
              .where('lesson', isEqualTo: lesson)
              .get();
          
          if (questionsQuery.docs.isNotEmpty) {
            int totalQuestions = 0;
            for (final doc in questionsQuery.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final questionCount = data['questionCount'] as int? ?? 1;
              totalQuestions += questionCount;
            }
            result[lesson] = totalQuestions;
          } else {
            // Fallback: ตรวจสอบจากคอลเล็กชัน lesson_com
            final lessonQuery = await _db
                .collection('lesson_com')
                .where('subject', isEqualTo: subject.trim().toLowerCase())
                .where('lesson', isEqualTo: lesson)
                .get();
            
            if (lessonQuery.docs.isNotEmpty) {
              int totalQuestions = 0;
              for (final doc in lessonQuery.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final questionCount = data['questionCount'] as int? ?? 5; // default 5 ข้อต่อด่าน
                totalQuestions += questionCount;
              }
              result[lesson] = totalQuestions;
            }
          }
        }
      } catch (_) {
        // ถ้าไม่มีข้อมูลสำหรับบทนี้ ข้ามไป
      }
    }
    
    return result;
  }
}
