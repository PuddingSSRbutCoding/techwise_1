// lib/question/question_tc1_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/services/progress_service.dart';

class QuestionTC1Page extends StatefulWidget {
  final int lesson;
  final int stage;
  final String subject; // 'computer' | 'electronics' | ...
  final String? docId;  // ใช้ระบุ doc ตรงๆ (ถ้าต้องการ)

  const QuestionTC1Page({
    super.key,
    required this.lesson,
    required this.stage,
    required this.subject,
    this.docId,
  });

  @override
  State<QuestionTC1Page> createState() => _QuestionTC1PageState();
}

/* ====================== Models ====================== */

class _QuizItem {
  final String text;
  final List<String> choices;
  final int correctIndex;
  final String? imageUrl;

  _QuizItem({
    required this.text,
    required this.choices,
    required this.correctIndex,
    this.imageUrl,
  });
}

class _QuizData {
  final String title;
  final List<_QuizItem> items;
  const _QuizData({required this.title, required this.items});
}

/* ====================== State ======================= */

class _QuestionTC1PageState extends State<QuestionTC1Page> {
  _QuizData? _quiz;
  int _index = 0;
  int _score = 0;
  int _selected = -1;

  static const double _passRate = 0.60; // ผ่านที่ 60%

  @override
  void initState() {
    super.initState();
    _load();
  }

  // สร้าง docId ให้ตรงกับหลังบ้านของคุณ
  String _docIdFor(String subject, int lesson) {
    final s = subject.trim().toLowerCase();
    if (s.startsWith('comp')) return 'questioncomputer$lesson';
    if (s.startsWith('elec')) return 'questionelec$lesson';
    return 'question${s}$lesson';
  }

  /// โหลดข้อสอบจาก Firestore:
  ///  A) questions/{docId}/{docId}-{stage}/level_*   (ตามโครงของคุณ)
  ///  B) ถ้าไม่เจอ → fallback: ค้นใน 'questions' ด้วย lesson+stage (single doc ที่มี list)
  Future<void> _load() async {
    try {
      Map<String, dynamic>? data;

      final subj = widget.subject.trim().toLowerCase();
      final baseDocId = widget.docId?.trim().isNotEmpty == true
          ? widget.docId!.trim()
          : _docIdFor(subj, widget.lesson);

      /* ---- A) Nested path (ตามรูป) ---- */
      try {
        final subcolName = '$baseDocId-${widget.stage}';
        final qs = await FirebaseFirestore.instance
            .collection('questions')
            .doc(baseDocId)
            .collection(subcolName)
            .get();

        if (qs.docs.isNotEmpty) {
          final docs = qs.docs.toList();
          int _num(String id) {
            final m = RegExp(r'(\d+)$').firstMatch(id);
            return m == null ? 0 : int.tryParse(m.group(1)!) ?? 0;
          }
          docs.sort((a, b) => _num(a.id).compareTo(_num(b.id)));

          data = {
            'title': 'แบบฝึกหัด',
            'questions': docs.map((d) => d.data()).toList(),
          };
        }
      } catch (_) {}

      /* ---- B) Fallback: single doc ใน 'questions' (มี list ภายใน) ---- */
      if (data == null) {
        final col = FirebaseFirestore.instance.collection('questions');
        final qs = await col
            .where('lesson', isEqualTo: widget.lesson)
            .where('stage', isEqualTo: widget.stage)
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty) {
          data = qs.docs.first.data();
        }
      }

      if (data == null) {
        setState(() => _quiz = const _QuizData(title: 'ยังไม่มีข้อสอบสำหรับด่านนี้', items: []));
        return;
      }

      // แปลงเป็นโมเดล
      final title = (data['title'] as String?) ?? 'แบบฝึกหัด';
      final raw = (data['questions'] ?? data['items'] ?? data['qs'] ?? []) as List<dynamic>;
      final items = <_QuizItem>[];
      for (final it in raw) {
        if (it is! Map) continue;
        final m = Map<String, dynamic>.from(it as Map);
        final text = (m['question'] ?? m['q'] ?? '').toString();
        final rawChoices = (m['options'] ?? m['choices'] ?? []) as List<dynamic>;
        final choices = rawChoices.map((e) => e.toString()).toList();
        int correct = 0;
        final ans = m['answerIndex'] ?? m['answer'] ?? m['ans'];
        if (ans is int && ans >= 0 && ans < choices.length) {
          correct = ans;
        } else if (ans is String) {
          final idx = choices.indexOf(ans);
          if (idx >= 0) correct = idx;
        }
        items.add(_QuizItem(
          text: text,
          choices: choices,
          correctIndex: correct,
          imageUrl: (m['image'] ?? m['imageUrl'] ?? m['imageUrl1']) as String?,
        ));
      }

      setState(() => _quiz = _QuizData(title: title, items: items));
    } catch (e) {
      setState(() => _quiz = const _QuizData(title: 'โหลดข้อมูลผิดพลาด', items: []));
    }
  }

  Future<void> _saveScore({required int score, required int total}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await ProgressService.I.saveStageScore(
        uid: user.uid,
        subject: widget.subject,
        lesson: widget.lesson,
        stage: widget.stage,
        score: score,
        total: total,
      );
    } catch (_) {}
  }

  void _onChoiceTap(int i) {
    setState(() => _selected = i);
  }

  void _onSubmit() {
    final quiz = _quiz;
    if (quiz == null || quiz.items.isEmpty) return;

    // ต้องเลือกคำตอบก่อน
    if (_selected < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกคำตอบก่อน'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // ประเมินคำตอบโดยไม่เฉลยทันที
    final item = quiz.items[_index];
    if (_selected == item.correctIndex) _score++;

    if (_index < quiz.items.length - 1) {
      setState(() {
        _index++;
        _selected = -1; // รีเซ็ตการเลือกสำหรับข้อถัดไป
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final quiz = _quiz;
    if (quiz == null) return;
    final total = quiz.items.isEmpty ? 1 : quiz.items.length;
    final passed = _score / total >= _passRate;

    await _saveScore(score: _score, total: total);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'ผ่านแบบฝึกหัด 🎉' : 'ยังไม่ผ่าน'),
        content: Text('คะแนนของคุณ: $_score / $total'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด dialog
              setState(() {
                _index = 0;
                _score = 0;
                _selected = -1;
              });
            },
            child: const Text('ทำใหม่'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);         // ปิด dialog
              Navigator.pop(context, passed); // กลับแผนที่ (true เฉพาะผ่าน)
            },
            child: const Text('กลับแผนที่'),
          ),
        ],
      ),
    );
  }

  String _titleText() {
    final s = widget.subject.toLowerCase();
    final subjectLabel = s.startsWith('elec')
        ? 'อิเล็กทรอนิกส์เบื้องต้น'
        : (s.startsWith('comp') ? 'คอมพิวเตอร์' : widget.subject);
    return 'บทที่ ${widget.lesson} $subjectLabel';
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;

    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundselect.jpg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: quiz == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      // ป้ายหัว (แคปซูลน้ำเงินเข้ม + ขอบดำ)
                      _TitleCapsule(text: _titleText()),
                      const SizedBox(height: 16),

                      // การ์ตูน (ขวา) + กล่องคำพูด (ซ้าย) — ตำแหน่งคงที่
                      if (quiz.items.isNotEmpty)
                        _SpeechBlockRight(
                          text: quiz.items[_index].text,
                          characterAsset: 'assets/images/TC_student.png', // เปลี่ยนพาธตามไฟล์คุณ
                          height: 160,
                          characterWidth: 100,
                        ),

                      const SizedBox(height: 14),

                      // ตัวเลือกแบบแคปซูล
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                          itemCount: quiz.items.isNotEmpty ? quiz.items[_index].choices.length : 0,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final item = quiz.items[_index];
                            final isSelected = _selected == i;
                            return _ChoiceCapsule(
                              label: '${String.fromCharCode(65 + i)})  ${item.choices[i]}',
                              selected: isSelected,
                              onTap: () => _onChoiceTap(i),
                            );
                          },
                        ),
                      ),

                      // ปุ่มล่าง (ส่งคำตอบเท่านั้น)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _onSubmit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('ส่งคำตอบ'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/* ====================== UI widgets ====================== */

// ป้ายหัว (แคปซูลน้ำเงินเข้ม + ขอบดำ + เงา)
class _TitleCapsule extends StatelessWidget {
  final String text;
  const _TitleCapsule({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1433A3), Color(0xFF2D77F6)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.45), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          height: 1.1,
        ),
      ),
    );
  }
}

/// การ์ตูน "ขวา" + กล่องคำพูด "ซ้าย" — ตำแหน่งคงที่ ไม่ไหลตามความยาวข้อความ
class _SpeechBlockRight extends StatelessWidget {
  final String text;
  final String characterAsset;
  final double height;
  final double characterWidth;

  const _SpeechBlockRight({
    required this.text,
    required this.characterAsset,
    this.height = 160,
    this.characterWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // กล่องคำพูด (กินพื้นที่ที่เหลือ)
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 22, 14),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 1.6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ),
                  // หางกล่องคำพูด (ชี้ไปทางตัวละครด้านขวา)
                  Positioned(
                    right: 2,
                    bottom: 8,
                    child: CustomPaint(
                      size: const Size(20, 16),
                      painter: _BubbleTailRightPainter(),
                    ),
                  ),
                ],
              ),
            ),
            // โซนตัวละคร (กว้างคงที่) — จัดชิดขวาล่าง
            SizedBox(
              width: characterWidth,
              child: Align(
                alignment: Alignment.bottomRight,
                child: _CharacterImage(asset: characterAsset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterImage extends StatelessWidget {
  final String asset;
  const _CharacterImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: 132,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox(width: 70, height: 132),
    );
  }
}

class _BubbleTailRightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.5, size.width, 0)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.75, 2, size.height)
      ..close();

    final fill = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ปุ่มตัวเลือก (แคปซูลฟ้า + ไฮไลต์ด้านบน + เงาล่าง) — ไม่เฉลยถูก/ผิดในทันที
class _ChoiceCapsule extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCapsule({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const baseGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFBFE9FF), Color(0xFF7FC7F2)],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: baseGrad,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.4),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              // ไฮไลต์ด้านบนบาง ๆ (gloss)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white.withOpacity(0.44), Colors.white.withOpacity(0.0)],
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F3F59),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
