import 'package:cloud_firestore/cloud_firestore.dart';

class LessonContent {
  final String title;    // อาจว่างได้ ถ้า DB ไม่ได้ใส่
  final String content;  // อาจว่างได้ ถ้า DB ไม่ได้ใส่
  final String? hero;    // URL หรือ asset path จาก DB เท่านั้น

  LessonContent({
    required this.title,
    required this.content,
    this.hero,
  });

  factory LessonContent.fromJson(Map<String, dynamic> j) {
    final hero = (j['hero'] ?? j['image'] ?? j['img']);
    return LessonContent(
      title: (j['title'] ?? '').toString(),
      content: (j['content'] ?? '').toString(),
      hero: hero is String ? hero.trim() : null,
    );
  }
}

class LessonContentService {
  final FirebaseFirestore db;
  LessonContentService({required this.db});

  String _normalize(String subject) {
    final s = subject.toLowerCase().trim();
    if (s.startsWith('comp')) return 'computer';
    if (s.startsWith('elec')) return 'electronics';
    return s;
  }

  // ตรงกับที่คุณใช้อยู่ใน Firebase
  static const Map<String, String> _collectionBySubject = {
    'computer': 'lesson_com',
    'electronics': 'lesson_words',
  };

  static const Map<String, String> _docPatternBySubject = {
    'computer': 'computer_{lesson}_{stage}',
    'electronics': 'electronic_{lesson}_{stage}', // ไม่มี s
  };

  String _docIdFor(String s, int lesson, int stage) {
    final pattern = _docPatternBySubject[s]!;
    return pattern
        .replaceAll('{lesson}', lesson.toString())
        .replaceAll('{stage}', stage.toString());
  }

  Future<LessonContent> fetch({
    required String subject,
    required int lesson,
    required int stage,
  }) async {
    final s = _normalize(subject);
    final collection = _collectionBySubject[s]!;
    final docId = _docIdFor(s, lesson, stage);

    // 1) docId ตรงตัว
    final docRef = db.collection(collection).doc(docId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>;
      return LessonContent.fromJson(data);
    }

    // 2) Fallback แบบ query ตาม field (รองรับเคส electronics ที่มี subject/lesson/state)
    if (s == 'electronics') {
      final c = db.collection(collection);
      QuerySnapshot qs = await c
          .where('lesson', isEqualTo: lesson)
          .where('state', isEqualTo: stage)
          .where('subject', isEqualTo: 'elec')
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        qs = await c
            .where('lesson', isEqualTo: lesson)
            .where('state', isEqualTo: stage)
            .where('subject', isEqualTo: 'electronics')
            .limit(1)
            .get();
      }
      if (qs.docs.isNotEmpty) {
        final data = qs.docs.first.data() as Map<String, dynamic>;
        return LessonContent.fromJson(data);
      }
    }

    // 3) Fallback เผื่อ computer ก็เคยเก็บแบบ field
    if (s == 'computer') {
      final c = db.collection(collection);
      final qs = await c
          .where('lesson', isEqualTo: lesson)
          .where('state', isEqualTo: stage)
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty) {
        final data = qs.docs.first.data() as Map<String, dynamic>;
        return LessonContent.fromJson(data);
      }
    }

    throw Exception('ไม่พบเอกสาร $collection/$docId');
  }
}
