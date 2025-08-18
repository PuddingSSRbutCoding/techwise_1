// lib/services/lesson_score_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LessonScoreService {
  LessonScoreService._();
  static final LessonScoreService instance = LessonScoreService._();
  
  final _db = FirebaseFirestore.instance;
  
  /// ดึงคะแนนรวมของบทเรียนที่ระบุ
  /// ส่งคืนข้อมูลในรูปแบบ {score: int, total: int, percentage: double, isCompleted: bool}
  Future<Map<String, dynamic>> getLessonScore({
    required String uid,
    required String subject,
    required int lesson,
  }) async {
    try {
      // ดึงคะแนนจากทุกด่านในบทเรียนนี้
      final scores = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('${subject.trim().toLowerCase()}_L$lesson')
          .get();

      if (!scores.exists) {
        return _getDefaultScore(subject, lesson);
      }

      final data = scores.data() as Map<String, dynamic>?;
      final scoresData = data?['scores'] as Map<String, dynamic>?;
      final completedStages = data?['completedStages'] as List<dynamic>? ?? [];

      // ตรวจสอบว่าบทเรียนนี้เสร็จสมบูรณ์หรือไม่
      final requiredStages = _getRequiredStagesForLesson(subject, lesson);
      final isCompleted = completedStages.length >= requiredStages;

      if (scoresData == null || scoresData.isEmpty) {
        return _getDefaultScore(subject, lesson, isCompleted: isCompleted);
      }

      // รวมคะแนนจากทุกด่าน
      int totalScore = 0;
      for (final stageScore in scoresData.values) {
        if (stageScore is Map<String, dynamic>) {
          final score = stageScore['score'] as int? ?? 0;
          totalScore += score;
        }
      }

      // กำหนดคะแนนสูงสุดตามวิชาและบท
      final maxScore = _getMaxScoreForLesson(subject, lesson);
      
      // คำนวณเปอร์เซ็นต์
      final percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0.0;

      return {
        'score': totalScore,
        'total': maxScore,
        'percentage': double.parse(percentage.toStringAsFixed(1)),
        'isCompleted': isCompleted,
        'completedStages': completedStages.length,
        'requiredStages': requiredStages,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting lesson score: $e');
      }
      return _getDefaultScore(subject, lesson);
    }
  }

  /// ดึงคะแนนของทุกบทเรียนในวิชาที่ระบุ
  Future<Map<int, Map<String, dynamic>>> getAllLessonScores({
    required String uid,
    required String subject,
  }) async {
    try {
      final result = <int, Map<String, dynamic>>{};
      
      // กำหนดจำนวนบทตามวิชา
      final lessonCount = _getLessonCount(subject);
      
      for (int lesson = 1; lesson <= lessonCount; lesson++) {
        final score = await getLessonScore(
          uid: uid,
          subject: subject,
          lesson: lesson,
        );
        result[lesson] = score;
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all lesson scores: $e');
      }
      return {};
    }
  }

  /// ตรวจสอบว่าวิชานี้เสร็จสมบูรณ์แล้วหรือไม่
  Future<bool> isSubjectCompleted({
    required String uid,
    required String subject,
  }) async {
    try {
      final lessonScores = await getAllLessonScores(uid: uid, subject: subject);
      
      for (final score in lessonScores.values) {
        if (!(score['isCompleted'] as bool? ?? false)) {
          return false;
        }
      }
      
      return lessonScores.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking subject completion: $e');
      }
      return false;
    }
  }

  /// กำหนดคะแนนสูงสุดสำหรับแต่ละบทเรียน
  int _getMaxScoreForLesson(String subject, int lesson) {
    final subjectLower = subject.toLowerCase().trim();
    
    if (subjectLower == 'computer' || subjectLower == 'tech') {
      switch (lesson) {
        case 1: return 35;
        case 2: return 45;
        case 3: return 35;
        default: return 35;
      }
    } else if (subjectLower == 'electronics' || subjectLower == 'elec') {
      switch (lesson) {
        case 1: return 40;
        case 2: return 40;
        case 3: return 40;
        default: return 40;
      }
    }
    
    return 35; // ค่าเริ่มต้น
  }

  /// กำหนดจำนวนด่านที่ต้องผ่านสำหรับแต่ละบทเรียน
  int _getRequiredStagesForLesson(String subject, int lesson) {
    final subjectLower = subject.toLowerCase().trim();
    
    if (subjectLower == 'computer' || subjectLower == 'tech') {
      switch (lesson) {
        case 1: return 4; // บทที่ 1 ต้องผ่าน 4 ด่าน
        case 2: return 5; // บทที่ 2 ต้องผ่าน 5 ด่าน
        case 3: return 4; // บทที่ 3 ต้องผ่าน 4 ด่าน
        default: return 4;
      }
    } else if (subjectLower == 'electronics' || subjectLower == 'elec') {
      switch (lesson) {
        case 1: return 5; // บทที่ 1 ต้องผ่าน 5 ด่าน
        case 2: return 5; // บทที่ 2 ต้องผ่าน 5 ด่าน
        case 3: return 5; // บทที่ 3 ต้องผ่าน 5 ด่าน
        default: return 5;
      }
    }
    
    return 4; // ค่าเริ่มต้น
  }

  /// กำหนดจำนวนบทตามวิชา
  int _getLessonCount(String subject) {
    final subjectLower = subject.toLowerCase().trim();
    
    if (subjectLower == 'computer' || subjectLower == 'tech') {
      return 3; // วิชาคอมพิวเตอร์มี 3 บท
    } else if (subjectLower == 'electronics' || subjectLower == 'elec') {
      return 3; // วิชาอิเล็กทรอนิกส์มี 3 บท
    }
    
    return 3; // ค่าเริ่มต้น
  }

  /// ส่งคืนคะแนนเริ่มต้นสำหรับบทเรียนที่ยังไม่ได้ทำ
  Map<String, dynamic> _getDefaultScore(String subject, int lesson, {bool isCompleted = false}) {
    final maxScore = _getMaxScoreForLesson(subject, lesson);
    final requiredStages = _getRequiredStagesForLesson(subject, lesson);
    
    return {
      'score': 0,
      'total': maxScore,
      'percentage': 0.0,
      'isCompleted': isCompleted,
      'completedStages': 0,
      'requiredStages': requiredStages,
    };
  }
}
