// lib/question/question_service.dart
// Patch: บังคับ map['options'] = map['option'] (ถ้ามี) ก่อนส่งเข้า Question.fromMap
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'question_model.dart';

class QuestionService {
  final FirebaseFirestore db;
  QuestionService({required this.db});

  Future<List<Question>> loadQuestions({
    required String subject, // 'computer' | 'electronics'
    required int lesson,
    required int stage,
    String? docIdOverride,
  }) async {
    final setNo = stage;

    final List<String> docCandidates =
        (docIdOverride != null && docIdOverride.trim().isNotEmpty)
            ? [docIdOverride.trim()]
            : _buildDocIdCandidates(subject: subject, lesson: lesson);

    for (final docId in docCandidates) {
      final subCandidates =
          _buildSubcollectionCandidates(docId: docId, lesson: lesson, stage: setNo);
      for (final sub in subCandidates) {
        final qs = await _tryLoadOne(docId: docId, subcollection: sub);
        if (qs != null && qs.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('[QuestionService] Using path: /questions/$docId/$sub (count=${qs.length})');
          }
          return qs;
        }
      }
    }

    throw Exception(
      'ไม่พบคำถาม subject=$subject lesson=$lesson stage=$stage '
      'ลองตรวจเส้นทาง: ${docCandidates.map((d) => "/questions/$d/{${d}-$setNo หรือ question$lesson-$setNo}").join(", ")}',
    );
  }

  // เข้ากันได้กับโค้ดเดิม
  Future<List<Question>> fetchByLessonStage({
    required String subject,
    required int lesson,
    required int stage,
    String? docId,
    int? setNo,
  }) {
    return loadQuestions(
      subject: subject,
      lesson: lesson,
      stage: setNo ?? stage,
      docIdOverride: docId,
    );
  }

  List<String> _buildDocIdCandidates({required String subject, required int lesson}) {
    final L = lesson;
    final s = subject.toLowerCase().trim();

    if (s == 'computer' || s == 'com' || s == 'tc' || s == 'tech') {
      return <String>[
        'questioncomputer$L',
        'questionscomputer$L',
      ];
    }

    return <String>[
      'questionelec$L',
      'questionelectronic$L',
      'questionelectronics$L',
      'questionselec$L',
    ];
  }

  List<String> _buildSubcollectionCandidates({
    required String docId,
    required int lesson,
    required int stage,
  }) {
    final L = lesson;
    final S = stage;
    final list = <String>[
      '$docId-$S',
      'question$L-$S',
      '${docId}_$S',
      '${docId}_S$S',
    ];

    final seen = <String>{};
    final dedup = <String>[];
    for (final v in list) {
      if (seen.add(v)) dedup.add(v);
    }
    return dedup;
  }

  Future<List<Question>?> _tryLoadOne({
    required String docId,
    required String subcollection,
  }) async {
    try {
      final snap = await db
          .collection('questions')
          .doc(docId)
          .collection(subcollection)
          .get();
      if (snap.docs.isEmpty) return null;

      final docs = snap.docs.toList()
        ..sort((a, b) {
          int num(String id) {
            final m = RegExp(r'(?:^|[_-])(\d+)$').firstMatch(id);
            if (m == null) return 0;
            return int.tryParse(m.group(1) ?? '0') ?? 0;
          }
          final na = num(a.id);
          final nb = num(b.id);
          if (na != nb) return na.compareTo(nb);
          return a.id.compareTo(b.id);
        });

      final out = <Question>[];
      for (final d in docs) {
        final raw = d.data();
        final map = Map<String, dynamic>.from(raw);

        // 🔧 สำคัญ: ถ้ามี 'option' แต่ไม่มี 'options' ให้แมปเป็น 'options'
        if (!map.containsKey('options') && map.containsKey('option')) {
          final opt = map['option'];

          if (opt is List) {
            map['options'] = opt.map((e) => (e ?? '').toString()).toList();
          } else if (opt is Map) {
            final om = Map<String, dynamic>.from(opt);
            final keys = om.keys.toList()
              ..sort((a, b) {
                int toNum(String x) => int.tryParse(x) ?? 0;
                return toNum(a.toString()).compareTo(toNum(b.toString()));
              });
            map['options'] = keys.map((k) => (om[k] ?? '').toString()).toList();
          }
        }

        final q = Question.fromMap(map, id: d.id);
        if (q.isValid) out.add(q);
      }
      return out;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[QuestionService] _tryLoadOne error at /questions/$docId/$subcollection: $e');
      }
      return null;
    }
  }
}
