// lib/services/progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson))
        .get();
    if (!snap.exists) return <int>{};
    final data = snap.data();
    final list = (data?['completedStages'] as List?)?.whereType<int>().toList() ?? const <int>[];
    return list.toSet();
  }

  /// เพิ่มด่านที่ผ่านแล้ว (ไม่แตะคะแนน)
  Future<void> addCompletedStage({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson))
        .set({
      'subject': subject.trim().toLowerCase(),
      'lesson': lesson,
      'completedStages': FieldValue.arrayUnion([stage]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// บันทึกคะแนนของด่าน (เก็บไว้ใต้ scores.s{stage})
  Future<void> saveStageScore({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
    required int score,
    required int total,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson))
        .set({
      'subject': subject.trim().toLowerCase(),
      'lesson': lesson,
      'updatedAt': FieldValue.serverTimestamp(),
      'scores': {
        's$stage': {
          'score': score,
          'total': total,
          'percent': total > 0 ? (score / total) : 0.0,
          'ts': FieldValue.serverTimestamp(),
        }
      },
    }, SetOptions(merge: true));
  }

  /// อ่านคะแนนของด่าน (ถ้ามี)
  Future<Map<String, dynamic>?> getStageScore({
    required String uid,
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson))
        .get();
    final data = snap.data();
    final scores = data?['scores'] as Map<String, dynamic>?;
    return scores?['s$stage'] as Map<String, dynamic>?;
  }
}
