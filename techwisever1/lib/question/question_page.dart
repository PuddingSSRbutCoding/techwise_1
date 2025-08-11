// lib/question/question_tc1_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_service.dart';
import 'question_model.dart';

class QuestionTC1Page extends StatefulWidget {
  final String docId;     // เช่น 'questioncomputer1'
  final int? setNo;       // ถ้าไม่ส่ง จะใช้ stage แทน
  final int lesson;       // 1
  final int stage;        // 1..5

  const QuestionTC1Page({
    super.key,
    this.docId = 'questioncomputer1',
    this.setNo,
    required this.lesson,
    required this.stage,
  });

  @override
  State<QuestionTC1Page> createState() => _QuestionTC1PageState();
}

class _QuestionTC1PageState extends State<QuestionTC1Page> {
  late final QuestionService _service;
  late Future<List<Question>> _future;

  late final int _effectiveSetNo; // setNo ที่ใช้จริง (= setNo ?? stage)

  int _current = 0;
  int _score = 0;
  int? _picked;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _service = QuestionService(db: FirebaseFirestore.instance);

    // 👉 ถ้าไม่ได้ส่ง setNo มา ให้ใช้ stage เป็นชื่อชุด
    _effectiveSetNo = widget.setNo ?? widget.stage;

    _future = _service.fetchByLessonStage(
      docId: widget.docId,
      setNo: _effectiveSetNo,
      lesson: widget.lesson,
      stage: widget.stage,
    );
  }

  void _onPick(Question q, int index) {
    if (_locked) return;
    setState(() {
      _picked = index;
      _locked = true;
      if (q.answerIndex == index) _score++;
    });

    Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      setState(() {
        _current++;
        _picked = null;
        _locked = false;
      });
    });
  }

  void _finish() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('จบแบบทดสอบ'),
        content: Text('คะแนนของคุณ: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // ส่ง true กลับไปแผนที่ให้ติ๊กผ่านด่าน
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = 'บทที่ ${widget.lesson} ด่าน ${widget.stage}';

    return Scaffold(
      // ❌ เอา AppBar (ปุ่มย้อนกลับ) ออก
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('เกิดข้อผิดพลาด: ${snap.error}'),
            );
          }

          final list = snap.data ?? const <Question>[];
          if (list.isEmpty) {
            return const Center(child: Text('ยังไม่มีคำถามสำหรับชุดนี้'));
          }
          if (_current >= list.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
          }

          // ป้องกัน out of range
          final q = list[_current.clamp(0, list.length - 1)];
          final marks = const ['A', 'B', 'C', 'D', 'E', 'F'];

          // ✅ ทำให้ตัวนับไม่เกินจำนวนข้อจริง (เช่น 1/4 หรือ 4/4 ไม่เกิน 4)
          final total = list.length;
          final displayIndex = (_current + 1 <= total) ? _current + 1 : total;

          return Stack(
            children: [
              // BG
              SizedBox.expand(
                child: Image.asset('assets/images/backgroundbock.jpg', fit: BoxFit.cover),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _HeaderCapsule(text: header),
                    const SizedBox(height: 12),

                    // คำถาม + การ์ตูน
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _SpeechBubbleCartoon(
                                text: q.text.isEmpty ? '— ไม่มีข้อความคำถาม —' : q.text,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Image.asset('assets/images/TC_student.png', height: 164),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ตัวเลือก
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        itemCount: q.options.length,
                        itemBuilder: (context, i) {
                          final selected = _picked == i;
                          final correct = q.answerIndex == i;

                          Color base = const Color(0xFFBFEAFC);
                          if (_picked != null) {
                            if (selected && correct) base = Colors.green.shade400;
                            if (selected && !correct) base = Colors.red.shade400;
                          }

                          final mark = (i < marks.length) ? marks[i] : '${i + 1}';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _ChoicePill(
                              text: '$mark )  ${q.options[i]}',
                              baseColor: base,
                              onTap: () => _onPick(q, i),
                              enabled: !_locked && _picked == null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ข้อ $displayIndex / $total', // ✅ แสดงผลแบบไม่เกินจำนวนข้อจริง
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'คะแนนปัจจุบัน: $_score',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

/// ——— UI helpers (เดิม) ———
class _HeaderCapsule extends StatelessWidget {
  final String text;
  const _HeaderCapsule({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E63FF), Color(0xFF2EA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _SpeechBubbleCartoon extends StatelessWidget {
  final String text;
  const _SpeechBubbleCartoon({required this.text});
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 160;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth, minHeight: 96),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black26, width: 1.2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w600)),
        ),
        Positioned(
          left: 20,
          bottom: -8,
          child: Transform.rotate(
            angle: 0.78,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26, width: 1.2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String text;
  final Color baseColor;
  final VoidCallback onTap;
  final bool enabled;
  const _ChoicePill({
    required this.text,
    required this.baseColor,
    required this.onTap,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [baseColor.withOpacity(.95), const Color(0xFF8ED3F6).withOpacity(.9)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    return Opacity(
      opacity: enabled ? 1 : .9,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.95), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(0, -1)),
            ],
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF123B55), fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
