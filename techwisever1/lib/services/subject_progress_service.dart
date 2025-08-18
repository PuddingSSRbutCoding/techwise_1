// lib/services/subject_progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'progress_service.dart';

class SubjectProgressService {
  SubjectProgressService._();
  static final SubjectProgressService instance = SubjectProgressService._();
  
  final _db = FirebaseFirestore.instance;
  
  /// คำนวณความคืบหน้าของวิชา (เปอร์เซ็นต์)
  /// คำนวณจากทุกข้อในวิชานั้นรวมกัน ไม่ใช่แค่จากบทที่ทำไปแล้ว
  /// ส่งคืนข้อมูลในรูปแบบ {totalQuestions: int, answeredQuestions: int, percentage: double}
  Future<Map<String, dynamic>> getSubjectProgress({
    required String uid,
    required String subject,
  }) async {
    try {
      // ดึงข้อมูลความคืบหน้าทั้งหมดของวิชานี้
      final progressData = await ProgressService.I.getLessonsTotalScores(
        uid: uid,
        subject: subject,
        maxLessons: 10, // จำนวนบทสูงสุด
      );
      
      // คำนวณจำนวนข้อที่ตอบแล้ว (จากบทที่ทำไปแล้ว)
      int totalAnswered = 0;
      
      for (final entry in progressData.entries) {
        final scores = entry.value;
        final answered = scores['score'] ?? 0;
        totalAnswered += answered as int;
      }
      
      // ดึงจำนวนข้อสอบทั้งหมดในวิชานี้ (รวมทุกบท)
      final subjectQuestionCounts = await _getQuestionCounts(subject);
      int totalQuestions = 0;
      
      // รวมจำนวนข้อสอบจากทุกบทในวิชา (รวมบทที่ยังไม่ได้ทำด้วย)
      for (final questionCount in subjectQuestionCounts.values) {
        totalQuestions += questionCount;
      }
      
      // คำนวณเปอร์เซ็นต์จากจำนวนข้อทั้งหมดในวิชา
      // ตัวอย่าง: วิชาคอมพิวเตอร์มี 595 ข้อ ทำได้ 35 ข้อ = 35/595 = 5.9%
      final percentage = totalQuestions > 0 ? (totalAnswered / totalQuestions) * 100 : 0.0;
      
      return {
        'totalQuestions': totalQuestions,
        'answeredQuestions': totalAnswered,
        'percentage': double.parse(percentage.toStringAsFixed(2)),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting subject progress: $e');
      }
      return {
        'totalQuestions': 0,
        'answeredQuestions': 0,
        'percentage': 0.0,
      };
    }
  }
  
  /// ดึงจำนวนข้อสอบในแต่ละบทของวิชา
  Future<Map<int, int>> _getQuestionCounts(String subject) async {
    try {
      final result = <int, int>{};
      final subjectLower = subject.toLowerCase().trim();
      
      // กำหนดจำนวนข้อสอบในแต่ละบทตามที่มีในระบบ
      // ค่าเหล่านี้สามารถปรับแต่งได้ตามจำนวนข้อสอบจริงในฐานข้อมูล
      if (subjectLower == 'computer' || subjectLower == 'tech') {
        // ข้อมูลสำหรับวิชาเทคนิคคอมพิวเตอร์ (แก้ไขตามจำนวนข้อสอบจริง)
        result[1] = 35; // บทที่ 1 มี 35 ข้อ
        result[2] = 45; // บทที่ 2 มี 45 ข้อ
        result[3] = 35; // บทที่ 3 มี 35 ข้อ
        // รวมทั้งหมด: 115 ข้อ (ตามที่ user ระบุ)
      } else if (subjectLower == 'electronics' || subjectLower == 'elec') {
        // ข้อมูลสำหรับวิชาอิเล็กทรอนิกส์
        result[1] = 40; // บทที่ 1 มี 40 ข้อ
        result[2] = 40; // บทที่ 2 มี 40 ข้อ
        result[3] = 40; // บทที่ 3 มี 40 ข้อ
        // รวมทั้งหมด: 120 ข้อ (ตามที่ user ระบุ)
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting question counts: $e');
      }
      return {};
    }
  }
  
  /// ดึงจำนวนข้อสอบจริงจากฐานข้อมูล (สำหรับอนาคต)
  Future<Map<int, int>> _getActualQuestionCounts(String subject) async {
    try {
      final result = <int, int>{};
      final subjectLower = subject.toLowerCase().trim();
      
      // สร้าง document candidates ตามรูปแบบของ QuestionService
      List<String> docCandidates;
      if (subjectLower == 'computer' || subjectLower == 'tech') {
        docCandidates = ['questioncomputer1', 'questionscomputer1'];
      } else {
        docCandidates = ['questionelec1', 'questionelectronic1', 'questionelectronics1'];
      }
      
      // ตรวจสอบแต่ละบท (1-10)
      for (int lesson = 1; lesson <= 10; lesson++) {
        int totalQuestions = 0;
        
        for (final docCandidate in docCandidates) {
          final docId = docCandidate.replaceAll('1', lesson.toString());
          
          // ตรวจสอบแต่ละ stage (1-5)
          for (int stage = 1; stage <= 5; stage++) {
            final subcollections = [
              '$docId-$stage',
              'question$lesson-$stage',
            ];
            
            for (final subcollection in subcollections) {
              try {
                final snapshot = await _db
                    .collection('questions')
                    .doc(docId)
                    .collection(subcollection)
                    .get();
                
                if (snapshot.docs.isNotEmpty) {
                  totalQuestions += snapshot.docs.length;
                  break; // หา subcollection ที่มีข้อมูลแล้ว ไม่ต้องหาต่อ
                }
              } catch (_) {
                // ไม่มี subcollection นี้ ลองต่อไป
              }
            }
          }
        }
        
        if (totalQuestions > 0) {
          result[lesson] = totalQuestions;
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting actual question counts: $e');
      }
      return {};
    }
  }
}
