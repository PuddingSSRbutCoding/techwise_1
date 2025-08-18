// lib/services/progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'firebase_utils.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class ProgressService {
  ProgressService._();
  static final ProgressService I = ProgressService._();
  final _db = FirebaseFirestore.instance;

  String _docId(String subject, int lesson) =>
      '${subject.trim().toLowerCase()}_L$lesson';

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
      final list =
          (data?['completedStages'] as List?)?.whereType<int>().toList() ??
          const <int>[];
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

    // ตรวจสอบว่าควรบันทึกคะแนนใหม่หรือไม่
    bool shouldSave = false;
    if (existingScores != null && existingScores.containsKey('s$stage')) {
      final existingScore = existingScores['s$stage'] as Map<String, dynamic>?;
      final existingScoreValue = existingScore?['score'] as int? ?? 0;

      // บันทึกเฉพาะเมื่อคะแนนใหม่ดีกว่า (สูงกว่า)
      if (score > existingScoreValue) {
        shouldSave = true;
      } else {
        return;
      }
    } else {
      // ไม่มีคะแนนเดิม บันทึกใหม่
      shouldSave = true;
    }

    if (!shouldSave) return;

    // ตรวจสอบว่า score ไม่เกิน total
    final finalScore = score > total ? total : score;
    final finalTotal = total;

    final scoreData = {
      'score': finalScore,
      'total': finalTotal,
      'percent': finalTotal > 0 ? (finalScore / finalTotal) : 0.0,
      'ts': FieldValue.serverTimestamp(),
      'attempts': FieldValue.increment(1), // เพิ่มจำนวนครั้งที่ทำ
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
        'scores': {'s$stage': scoreData},
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

  /// คำนวณคะแนนรวมของแต่ละบทเรียนในวิชา (แยกคะแนนตามด่าน)
  Future<Map<int, Map<String, int>>> getLessonsTotalScores({
    required String uid,
    required String subject,
    int maxLessons = 10,
  }) async {
    final result = <int, Map<String, int>>{};

    for (int lesson = 1; lesson <= maxLessons; lesson++) {
      try {
        // ดึงคะแนนของทุกด่านในบทเรียนนี้
        final scores = await getAllLessonScores(
          uid: uid,
          subject: subject,
          lesson: lesson,
        );

        if (scores.isNotEmpty) {
          int totalScore = 0;
          int totalMaxScore = 0;

          // คำนวณคะแนนรวมจากทุกด่าน
          for (final stageScore in scores.values) {
            final score = stageScore['score'] as int? ?? 0;
            final maxScore = stageScore['total'] as int? ?? 0;

            // ตรวจสอบว่า score ไม่เกิน maxScore ของด่านนั้น
            final validScore = score > maxScore ? maxScore : score;

            totalScore += validScore;
            totalMaxScore += maxScore;
          }

          result[lesson] = {'score': totalScore, 'total': totalMaxScore};
        } else {
          // ถ้าไม่มีคะแนน ให้ดึงจำนวนข้อทั้งหมดจาก Firebase
          final totalQuestions = await getLessonsTotalQuestions(
            uid: uid,
            subject: subject,
            maxLessons: 1, // ดึงเฉพาะบทนี้
          );

          final maxScore = totalQuestions[lesson] ?? 0;
          result[lesson] = {'score': 0, 'total': maxScore};
        }
      } catch (e) {
        // ถ้าเกิด error ให้ดึงจำนวนข้อทั้งหมดจาก Firebase
        try {
          final totalQuestions = await getLessonsTotalQuestions(
            uid: uid,
            subject: subject,
            maxLessons: 1, // ดึงเฉพาะบทนี้
          );

          final maxScore = totalQuestions[lesson] ?? 45;
          result[lesson] = {'score': 0, 'total': maxScore};
        } catch (e2) {
          // ถ้าเกิด error ทั้งหมด ให้ใช้ข้อมูลจาก getLessonsTotalQuestions
          final totalQuestions = await getLessonsTotalQuestions(
            uid: uid,
            subject: subject,
            maxLessons: 1, // ดึงเฉพาะบทนี้
          );

          final maxScore = totalQuestions[lesson] ?? 45;
          result[lesson] = {'score': 0, 'total': maxScore};
        }
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
        query: collection.where(
          'subject',
          isEqualTo: subject.trim().toLowerCase(),
        ),
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
      final completedStages =
          (data?['completedStages'] as List?)?.whereType<int>().toList() ?? [];

      return completedStages.contains(stage);
    } catch (e) {
      return false;
    }
  }

  /// คำนวณจำนวนข้อทั้งหมดของทุกด่านในบทเรียน (ดึงข้อมูลจริงจาก Firebase)
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
        4: 40, // บทที่ 4: 40 ข้อ
        5: 30, // บทที่ 5: 30 ข้อ
        6: 35, // บทที่ 6: 35 ข้อ
        7: 25, // บทที่ 7: 25 ข้อ
        8: 30, // บทที่ 8: 30 ข้อ
        9: 20, // บทที่ 9: 20 ข้อ
        10: 25, // บทที่ 10: 25 ข้อ
      },
      'electronics': {
        1: 30, // บทที่ 1: 30 ข้อ
        2: 35, // บทที่ 2: 35 ข้อ
        3: 25, // บทที่ 3: 25 ข้อ
        4: 30, // บทที่ 4: 30 ข้อ
        5: 25, // บทที่ 5: 25 ข้อ
        6: 20, // บทที่ 6: 20 ข้อ
        7: 15, // บทที่ 7: 15 ข้อ
        8: 20, // บทที่ 8: 20 ข้อ
        9: 15, // บทที่ 9: 15 ข้อ
        10: 10, // บทที่ 10: 10 ข้อ
      },
    };

    for (int lesson = 1; lesson <= maxLessons; lesson++) {
      try {
        // ใช้จำนวนข้อที่กำหนดไว้ใน subjectQuestionMap
        final questionMap = subjectQuestionMap[subject.trim().toLowerCase()];
        if (questionMap != null && questionMap.containsKey(lesson)) {
          result[lesson] = questionMap[lesson]!;
          continue;
        }

        // วิธีที่ 1: ตรวจสอบจากคอลเล็กชัน questions (คำถามจริง)
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
          continue;
        }

        // วิธีที่ 2: ตรวจสอบจากคอลเล็กชัน lesson_elec (สำหรับ electronics)
        if (subject.trim().toLowerCase() == 'electronics') {
          final lessonQuery = await _db
              .collection('lesson_elec')
              .where('subject', isEqualTo: subject.trim().toLowerCase())
              .where('lesson', isEqualTo: lesson)
              .get();

          if (lessonQuery.docs.isNotEmpty) {
            int totalQuestions = 0;
            for (final doc in lessonQuery.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final questionCount = data['questionCount'] as int? ?? 5;
              totalQuestions += questionCount;
            }
            result[lesson] = totalQuestions;
            continue;
          }
        }

        // วิธีที่ 3: ตรวจสอบจากคอลเล็กชัน lesson_com (สำหรับ computer)
        if (subject.trim().toLowerCase() == 'computer') {
          final lessonQuery = await _db
              .collection('lesson_com')
              .where('subject', isEqualTo: subject.trim().toLowerCase())
              .where('lesson', isEqualTo: lesson)
              .get();

          if (lessonQuery.docs.isNotEmpty) {
            int totalQuestions = 0;
            for (final doc in lessonQuery.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final questionCount = data['questionCount'] as int? ?? 5;
              totalQuestions += questionCount;
            }
            result[lesson] = totalQuestions;
            continue;
          }
        }

        // วิธีที่ 4: ตรวจสอบจากคอลเล็กชัน stages (ด่าน)
        final stagesQuery = await _db
            .collection('stages')
            .where('subject', isEqualTo: subject.trim().toLowerCase())
            .where('lesson', isEqualTo: lesson)
            .get();

        if (stagesQuery.docs.isNotEmpty) {
          int totalQuestions = 0;
          for (final doc in stagesQuery.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final questionCount = data['questionCount'] as int? ?? 5;
            totalQuestions += questionCount;
          }
          result[lesson] = totalQuestions;
          continue;
        }

        // ถ้าไม่พบข้อมูลใดๆ ให้ใช้ค่า default ที่เหมาะสม
        result[lesson] = 45; // default 45 ข้อต่อบท (ตามที่ควรจะเป็น)
      } catch (e) {
        // ถ้าเกิด error ให้ใช้ค่า default ที่เหมาะสม
        result[lesson] = 45;
      }
    }

    return result;
  }

  /// ตรวจสอบและแก้ไขคะแนนที่ผิดปกติ (score > total)
  Future<void> validateAndFixScores({
    required String uid,
    required String subject,
    int maxLessons = 10,
  }) async {
    try {
      for (int lesson = 1; lesson <= maxLessons; lesson++) {
        final scores = await getAllLessonScores(
          uid: uid,
          subject: subject,
          lesson: lesson,
        );

        if (scores.isNotEmpty) {
          for (final entry in scores.entries) {
            final stageNum = entry.key;
            final stageData = entry.value as Map<String, dynamic>;

            final score = stageData['score'] as int? ?? 0;
            final total = stageData['total'] as int? ?? 0;

            // ตรวจสอบว่า score ไม่เกิน total
            if (score > total && total > 0) {
              final correctedScore = total;
              final correctedData = Map<String, dynamic>.from(stageData);
              correctedData['score'] = correctedScore;
              correctedData['percent'] = total > 0
                  ? (correctedScore / total)
                  : 0.0;
              correctedData['fixedAt'] = FieldValue.serverTimestamp();
              correctedData['originalScore'] = score; // เก็บคะแนนเดิมไว้

              // บันทึกคะแนนที่แก้ไขแล้ว
              final docRef = _db
                  .collection('users')
                  .doc(uid)
                  .collection('progress')
                  .doc(_docId(subject, lesson));

              await FirebaseUtils.setDocumentWithTimeout(
                documentRef: docRef,
                data: {
                  'scores': {stageNum: correctedData},
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                options: SetOptions(merge: true),
                timeout: const Duration(seconds: 10),
              );
            }
          }
        }
      }
    } catch (e) {
      // debugPrint('❌ Error validating scores: $e'); // Removed debugPrint
    }
  }

  /// ดึงคะแนนที่ดีที่สุดของแต่ละด่าน
  Future<Map<int, Map<String, dynamic>>> getBestStageScores({
    required String uid,
    required String subject,
    required int lesson,
  }) async {
    try {
      final scores = await getAllLessonScores(
        uid: uid,
        subject: subject,
        lesson: lesson,
      );

      final result = <int, Map<String, dynamic>>{};
      for (final entry in scores.entries) {
        final stageNum = entry.key;
        final stageData = Map<String, dynamic>.from(entry.value);

        // ตรวจสอบว่า score ไม่เกิน total
        final score = stageData['score'] as int? ?? 0;
        final total = stageData['total'] as int? ?? 0;

        if (score > total && total > 0) {
          stageData['score'] = total;
          stageData['percent'] = total > 0 ? (total / total) : 0.0;
          stageData['isCorrected'] = true;
        }

        result[stageNum] = stageData;
      }

      return result;
    } catch (e) {
      // debugPrint('❌ Error getting best stage scores: $e'); // Removed debugPrint
      return {};
    }
  }
}
