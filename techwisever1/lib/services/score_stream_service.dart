// lib/services/score_stream_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ScoreStreamService {
  ScoreStreamService._();
  static final ScoreStreamService instance = ScoreStreamService._();
  
  final _db = FirebaseFirestore.instance;
  
  /// Stream คะแนนของบทเรียนที่ระบุแบบ real-time
  Stream<Map<String, dynamic>> getLessonScoreStream({
    required String uid,
    required String subject,
    required int lesson,
  }) {
    try {
      return _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('${subject.trim().toLowerCase()}_L$lesson')
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return _getDefaultScore(subject, lesson);
        }

        final data = snapshot.data() as Map<String, dynamic>?;
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
          'lastUpdated': snapshot.metadata.hasPendingWrites ? 'pending' : 'synced',
        };
      }).handleError((error) {
        if (kDebugMode) {
          debugPrint('Error in lesson score stream: $error');
        }
        return _getDefaultScore(subject, lesson);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating lesson score stream: $e');
      }
      // ส่งคืน stream ที่มีค่า default
      return Stream.value(_getDefaultScore(subject, lesson));
    }
  }

  /// Stream คะแนนของทุกบทเรียนในวิชาที่ระบุแบบ real-time
  Stream<Map<int, Map<String, dynamic>>> getAllLessonScoresStream({
    required String uid,
    required String subject,
  }) {
    try {
      final lessonCount = _getLessonCount(subject);
      
      // สร้าง stream ที่อัปเดตเมื่อมีการเปลี่ยนแปลงใน Firebase
      return _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .where('subject', isEqualTo: subject.trim().toLowerCase())
          .snapshots()
          .map((snapshot) {
        final result = <int, Map<String, dynamic>>{};
        
        for (int lesson = 1; lesson <= lessonCount; lesson++) {
          // หาเอกสารที่ตรงกับบทเรียนนี้
          final lessonDoc = snapshot.docs.where(
            (doc) => doc.id == '${subject.trim().toLowerCase()}_L$lesson',
          ).firstOrNull;
          
          if (lessonDoc != null) {
            final data = lessonDoc.data();
            final scoresData = data['scores'] as Map<String, dynamic>?;
            final completedStages = data['completedStages'] as List<dynamic>? ?? [];
            
            // ตรวจสอบว่าบทเรียนนี้เสร็จสมบูรณ์หรือไม่
            final requiredStages = _getRequiredStagesForLesson(subject, lesson);
            final isCompleted = completedStages.length >= requiredStages;
            
            if (scoresData != null && scoresData.isNotEmpty) {
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
              
              result[lesson] = {
                'score': totalScore,
                'total': maxScore,
                'percentage': double.parse(percentage.toStringAsFixed(1)),
                'isCompleted': isCompleted,
                'completedStages': completedStages.length,
                'requiredStages': requiredStages,
                'lastUpdated': 'synced',
              };
            } else {
              result[lesson] = _getDefaultScore(subject, lesson, isCompleted: isCompleted);
            }
          } else {
            result[lesson] = _getDefaultScore(subject, lesson);
          }
        }
        
        return result;
      }).handleError((error) {
        if (kDebugMode) {
          debugPrint('Error in all lesson scores stream: $error');
        }
        return {};
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating all lesson scores stream: $e');
      }
      return Stream.value({});
    }
  }

  /// Stream ความคืบหน้าของด่านที่ระบุแบบ real-time
  Stream<Map<String, dynamic>?> getStageProgressStream({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) {
    try {
      return _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('${subject.trim().toLowerCase()}_L$lesson')
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return null;

        final data = snapshot.data() as Map<String, dynamic>?;
        final scores = data?['scores'] as Map<String, dynamic>?;
        final completedStages = data?['completedStages'] as List<dynamic>? ?? [];
        
        final stageScore = scores?['s$stage'] as Map<String, dynamic>?;
        final isCompleted = completedStages.contains(stage);
        
        if (stageScore != null) {
          return {
            ...stageScore,
            'isCompleted': isCompleted,
            'lastUpdated': snapshot.metadata.hasPendingWrites ? 'pending' : 'synced',
          };
        }
        
        return {
          'isCompleted': isCompleted,
          'lastUpdated': snapshot.metadata.hasPendingWrites ? 'pending' : 'synced',
        };
      }).handleError((error) {
        if (kDebugMode) {
          debugPrint('Error in stage progress stream: $error');
        }
        return null;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating stage progress stream: $e');
      }
      return Stream.value(null);
    }
  }

  /// Stream สถานะการเสร็จสมบูรณ์ของวิชาแบบ real-time
  Stream<bool> getSubjectCompletionStream({
    required String uid,
    required String subject,
  }) {
    try {
      return getAllLessonScoresStream(uid: uid, subject: subject)
          .map((lessonScores) {
        for (final score in lessonScores.values) {
          if (!(score['isCompleted'] as bool? ?? false)) {
            return false;
          }
        }
        return lessonScores.isNotEmpty;
      }).handleError((error) {
        if (kDebugMode) {
          debugPrint('Error in subject completion stream: $error');
        }
        return false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating subject completion stream: $e');
      }
      return Stream.value(false);
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
      'lastUpdated': 'default',
    };
  }

  /// Force refresh ข้อมูลคะแนน (สำหรับกรณีที่ต้องการ refresh ทันที)
  Future<void> forceRefresh({
    required String uid,
    required String subject,
    int? lesson,
  }) async {
    try {
      if (lesson != null) {
        // Refresh เฉพาะบทเรียนที่ระบุ
        final docRef = _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc('${subject.trim().toLowerCase()}_L$lesson');
        
        // อ่านข้อมูลใหม่เพื่อ trigger stream
        await docRef.get();
      } else {
        // Refresh ทุกบทเรียนในวิชา
        final lessonCount = _getLessonCount(subject);
        for (int l = 1; l <= lessonCount; l++) {
          final docRef = _db
              .collection('users')
              .doc(uid)
              .collection('progress')
              .doc('${subject.trim().toLowerCase()}_L$l');
          
          await docRef.get();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error force refreshing scores: $e');
      }
    }
  }
}


