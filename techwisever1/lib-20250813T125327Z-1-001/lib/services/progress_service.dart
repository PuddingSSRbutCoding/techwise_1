import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService I = ProgressService._();
  final _db = FirebaseFirestore.instance;

  String _docId(String subject, int lesson) => '${subject}_L$lesson';

  // โหลดด่านที่ผ่านแล้ว
  Future<Set<int>> loadCompletedStages({
    required String uid,
    required String subject,
    required int lesson,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_docId(subject, lesson))
        .get();

    final list = (doc.data()?['completedStages'] as List?)?.cast<int>() ?? <int>[];
    return list.toSet();
  }

  // บันทึกว่าผ่านด่าน (merge)
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
      'subject': subject,
      'lesson': lesson,
      'completedStages': FieldValue.arrayUnion([stage]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
