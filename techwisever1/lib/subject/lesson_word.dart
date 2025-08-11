import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonWordPage extends StatelessWidget {
  final String subject; // 'computer' | 'electronics' | 'elec' ฯลฯ
  final int lesson;     // 1..n
  final int stage;      // 1..5

  const LessonWordPage({
    super.key,
    required this.subject,
    required this.lesson,
    required this.stage,
  });

  bool _isNetwork(String p) => p.startsWith('http://') || p.startsWith('https://');

  /// ชื่อเอกสารที่เป็นไปได้ตามวิชา
  List<String> get _docIdCandidates {
    final s = subject.toLowerCase();
    final isElec = s.contains('elec'); // elec / electronic / electronics

    if (isElec) {
      return [
        'electronic_${lesson}_$stage',
        'electronics_${lesson}_$stage',
        'elec_${lesson}_$stage',
      ];
    } else {
      return [
        'computer_${lesson}_$stage',
        'computers_${lesson}_$stage',
        'comp_${lesson}_$stage',
      ];
    }
  }

  /// คอลเลกชันที่เป็นไปได้ (เจอทั้ง lesson_words และ lesson_com)
  List<String> get _collections => const ['lesson_words', 'lesson_com'];

  /// ลองโหลดเอกสารจากหลายชื่อ/หลายคอลเลกชัน จนกว่าจะเจอ
  Future<({String col, String id, Map<String, dynamic> data})?> _load() async {
    final db = FirebaseFirestore.instance;
    for (final col in _collections) {
      final ref = db.collection(col);
      for (final id in _docIdCandidates) {
        try {
          final doc = await ref.doc(id).get();
          if (doc.exists) {
            debugPrint('[LESSON_WORD] HIT $col/$id');
            return (col: col, id: id, data: doc.data() as Map<String, dynamic>);
          } else {
            debugPrint('[LESSON_WORD] MISS $col/$id');
          }
        } catch (e) {
          debugPrint('[LESSON_WORD] ERROR $col/$id -> $e');
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String col, String id, Map<String, dynamic> data})?>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(
                  child: Image.asset('assets/images/backgroundbock.jpg', fit: BoxFit.cover),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'ไม่พบเนื้อหา\nลองค้นหา: ${_docIdCandidates.join(", ")}\nในคอลเลกชัน: ${_collections.join(", ")}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final found = snap.data!;
        final data = found.data;

        final title = (data['title'] ?? 'บทที่ $lesson ด่าน $stage').toString();
        // รองรับทั้ง content และ text
        final content = (data['content'] ?? data['text'] ?? '').toString();
        final imagePath = (data['image'] ?? '').toString();

        Widget? cover;
        if (imagePath.isNotEmpty) {
          final img = _isNetwork(imagePath)
              ? Image.network(imagePath, fit: BoxFit.cover)
              : Image.asset(imagePath, fit: BoxFit.cover);
          cover = ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 180, width: double.infinity, child: img),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              SizedBox.expand(
                child: Image.asset('assets/images/backgroundbock.jpg', fit: BoxFit.cover),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      if (cover != null) cover,
                      const SizedBox(height: 12),

                      // เนื้อหา
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text(
                            content.isEmpty ? '— ยังไม่มีเนื้อหา —' : content,
                            style: const TextStyle(fontSize: 16, height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ปุ่มไปทำแบบทดสอบ
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.quiz),
                        label: const Text('ไปทำแบบทดสอบ'),
                      ),
                      const SizedBox(height: 8),

                      // ปุ่มกลับ (ถ้าไม่อยากทำ)
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('กลับ'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
