// lib/subject/lesson_intro.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'computer_lesson_map_page.dart';
import 'electronics_lesson_map_page.dart';

class LessonIntroPage extends StatelessWidget {
  final String subject; // 'computer' | 'electronics'
  final int lesson;     // 1,2,3,...

  const LessonIntroPage({
    super.key,
    required this.subject,
    required this.lesson,
  });

  bool _isNetwork(String p) => p.startsWith('http://') || p.startsWith('https://');

  /// รายชื่อ docId ที่จะลองอ่านใน /lessons
  /// - ลองชื่อตามวิชา+บทก่อน (computer1/2/3 … หรือ electronics1/2/3 …)
  /// - แล้ว fallback ไปบท 1 เผื่อยังไม่มีเอกสารของบทนั้น
  List<String> get _docIdCandidates {
    final s = subject.toLowerCase();
    final isElec = s.contains('elec');

    final primary = isElec
        ? ['electronics$lesson', 'electronic$lesson', 'elec$lesson']
        : ['computer$lesson', 'computers$lesson', 'comp$lesson'];

    final fallback = isElec
        ? ['electronics1', 'electronic1', 'elec1']
        : ['computer1', 'computers1', 'comp1'];

    return [...primary, ...fallback];
  }

  // ลองโหลดทีละชื่อจนเจอ
  Future<Map<String, dynamic>?> _loadLesson() async {
    final col = FirebaseFirestore.instance.collection('lessons');
    for (final id in _docIdCandidates) {
      final doc = await col.doc(id).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isElec = subject.toLowerCase().contains('elec');

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadLesson(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text('บท $lesson')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ไม่พบเอกสารบทเรียนของ $subject บท $lesson\n'
                'ที่ลองค้นหา: ${_docIdCandidates.join(", ")}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snap.data!;

        final title = (data['title'] ?? 'บท $lesson').toString();

        // ✅ รองรับทั้ง description และ descrition (กันพิมพ์ผิด)
        final description = (data['description'] ?? data['descrition'] ?? '').toString();

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
          body: Stack(children: [
            SizedBox.expand(
              child: Image.asset('assets/images/backgroundbock.jpg', fit: BoxFit.cover),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (cover != null) cover,
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          description.isEmpty ? '— ยังไม่มีคำอธิบาย —' : description,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isElec
                                ? ElectronicsLessonMapPage(lesson: lesson)
                                : ComputerLessonMapPage(lesson: lesson),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('ไปแผนที่บทเรียน'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
