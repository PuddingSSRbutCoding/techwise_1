// lib/question/question_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint

class QuestionService {
  final FirebaseFirestore db;
  QuestionService({required this.db});

  /// ดึงคำถามตามโครง Firestore ที่ยืดหยุ่น:
  /// - Computer:
  ///     /questions/questioncomputer{L}/{questioncomputer{L}-{S}}/level_*
  ///     /questions/questionscomputer{L}/{questionscomputer{L}-{S}}/level_*
  /// - Electronics:
  ///     /questions/questionelec{L}/{questionelec{L}-{S}}/level_*
  ///     /questions/questionelectronic{L}/{questionelectronic{L}-{S}}/level_*
  ///     /questions/questionelectronics{L}/{questionelectronics{L}-{S}}/level_*
  ///   และรูปแบบพิเศษที่คุณใช้:
  ///     /questions/questionelec{L}/question{L}-{S}/level_*
  Future<List<Question>> fetchByLessonStage({
    required String docId,   // ex: questionelec3 หรือ questioncomputer2/3
    required int setNo,      // 1..N
    required int lesson,     // เลขบท
    required int stage,      // = setNo (ไว้แสดงผล/validate)
  }) async {
    final lower = docId.toLowerCase();

    // -------- 1) กำหนดผู้สมัครชื่อ "เอกสารบนสุด" (ไม่ข้ามวิชา) --------
    late final List<String> docCandidates;
    if (lower.contains('computer')) {
      final baseA = 'questioncomputer$lesson';
      final baseB = 'questionscomputer$lesson';
      docCandidates = {docId, baseA, baseB}.toList();
    } else if (lower.contains('elec')) {
      final baseA = 'questionelec$lesson';
      final baseB = 'questionelectronic$lesson';
      final baseC = 'questionelectronics$lesson';
      docCandidates = {docId, baseA, baseB, baseC}.toList();
    } else {
      // กรณีไม่รู้วิชา → ไม่ fallback
      docCandidates = [docId];
    }

    // ฟังก์ชันผู้ช่วย: ลองโหลดคอลเลกชันหนึ่งชุด
    Future<List<Question>?> _tryLoad(String d, String sub) async {
      final col = db.collection('questions').doc(d).collection(sub);
      try {
        final snap = await col.orderBy(FieldPath.documentId).get();
        if (snap.docs.isNotEmpty) {
          debugPrint('[QS] HIT $d/$sub (${snap.size} docs, ordered)');
          return snap.docs.map((e) => Question.fromMap(e.data())).toList();
        }
      } catch (_) {
        final snap = await col.get();
        if (snap.docs.isNotEmpty) {
          debugPrint('[QS] HIT $d/$sub (${snap.size} docs, unordered)');
          return snap.docs.map((e) => Question.fromMap(e.data())).toList();
        }
      }
      return null;
    }

    // -------- 2) ลองทุก combination ของ docId/subcollection --------
    for (final d in docCandidates) {
      final isComputer = d.contains('computer');
      final isElec = d.contains('elec');

      // ผู้สมัครชื่อ subcollection
      final subs = <String>{
        // มาตรฐาน: {docId}-{setNo}
        '$d-$setNo',
        // canonical ของแต่ละกลุ่ม (กันกรณี docId ส่งมาไม่ตรง)
        if (isComputer) 'questioncomputer$lesson-$setNo',
        if (isComputer) 'questionscomputer$lesson-$setNo',
        if (isElec) 'questionelec$lesson-$setNo',
        if (isElec) 'questionelectronic$lesson-$setNo',
        if (isElec) 'questionelectronics$lesson-$setNo',
        // เคสพิเศษของอิเล็กฯบท 3 ในโปรเจ็กต์คุณ
        if (isElec) 'question$lesson-$setNo', // ex: question3-1
      }.toList();

      for (final sub in subs) {
        final res = await _tryLoad(d, sub);
        if (res != null) return res;
      }
    }

    // -------- 3) ไม่พบจริง ๆ → โยน error เพื่อ debug --------
    throw Exception(
      'ไม่พบคำถาม (lesson=$lesson, stage=$stage) '
      'ที่ doc: ${docCandidates.join(", ")}; '
      'ตรวจชื่อ subcollection ให้เป็น {docId}-$setNo หรือ question$lesson-$setNo',
    );
  }
}
