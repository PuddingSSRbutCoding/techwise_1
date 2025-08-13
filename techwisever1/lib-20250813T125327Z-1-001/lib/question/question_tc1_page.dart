// lib/question/question_tc1_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Question page that supports multiple subjects.
/// - subject: 'computer' | 'electronics' (or anything you map below)
/// - lesson / stage : used to query the quiz doc if docId not provided
/// - docId (optional) : read that exact document
class QuestionTC1Page extends StatefulWidget {
  final int lesson;
  final int stage;
  final String subject;   // e.g. 'computer' or 'electronics'
  final String? docId;    // optional, to fetch exact doc

  const QuestionTC1Page({
    super.key,
    required this.lesson,
    required this.stage,
    this.subject = 'computer',
    this.docId,
  });

  @override
  State<QuestionTC1Page> createState() => _QuestionTC1PageState();
}

/* -------------------- data models -------------------- */
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

  _QuizData({required this.title, required this.items});
}

/* -------------------- page state -------------------- */
class _QuestionTC1PageState extends State<QuestionTC1Page> {
  late final CollectionReference<Map<String, dynamic>> _qcol;

  // quiz state
  _QuizData? _quiz;
  int _index = 0;
  int _score = 0;
  int _selected = -1;
  bool _locked = false; // after submit an answer

  // tweak: change pass rate if you like
  static const double _passRate = 0.6;

  @override
  void initState() {
    super.initState();
    _qcol = FirebaseFirestore.instance.collection(_questionCollection(widget.subject));
    _load();
  }

  String _questionCollection(String s) {
    final ss = s.toLowerCase();
    // 👇 ใส่ชื่อคอลเล็กชันให้ตรงกับโปรเจกต์ของคุณ
    if (ss.startsWith('elec')) return 'question_electronics';
    return 'question_computer';
  }

  Future<void> _load() async {
    try {
      Map<String, dynamic>? data;
      if (widget.docId != null && widget.docId!.isNotEmpty) {
        final d = await _qcol.doc(widget.docId!).get();
        data = d.data();
      } else {
        final qs = await _qcol
            .where('lesson', isEqualTo: widget.lesson)
            .where('stage', isEqualTo: widget.stage)
            .limit(1)
            .get();
        data = qs.docs.isNotEmpty ? qs.docs.first.data() : null;
      }

      if (data == null) {
        setState(() => _quiz = _QuizData(title: 'ไม่พบข้อสอบ', items: []));
        return;
      }

      final title = (data['title'] as String?) ?? 'แบบฝึกหัด';
      final rawList = (data['questions'] ??
              data['items'] ??
              data['qs'] ??
              []) as List<dynamic>;

      final items = <_QuizItem>[];
      for (final it in rawList) {
        if (it is! Map) continue;
        final m = Map<String, dynamic>.from(it as Map);
        final text = (m['question'] ?? m['q'] ?? '').toString();
        final rawChoices = (m['choices'] ?? m['options'] ?? []) as List<dynamic>;
        final choices = rawChoices.map((e) => e.toString()).toList();

        int correct = 0;
        final ans = m['answerIndex'] ?? m['answer'] ?? m['ans'];
        if (ans is int && ans >= 0 && ans < choices.length) {
          correct = ans;
        } else if (ans is String) {
          final idx = choices.indexOf(ans);
          correct = idx >= 0 ? idx : 0;
        }

        items.add(_QuizItem(
          text: text,
          choices: choices,
          correctIndex: correct,
          imageUrl: (m['image'] as String?),
        ));
      }

      setState(() => _quiz = _QuizData(title: title, items: items));
    } catch (e) {
      setState(() => _quiz = _QuizData(title: 'เกิดข้อผิดพลาด', items: []));
    }
  }

  void _submitAnswer() {
    if (_quiz == null) return;
    if (_selected < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เลือกคำตอบก่อนนะ')),
      );
      return;
    }
    final item = _quiz!.items[_index];
    if (!_locked) {
      // first submit on this question
      if (_selected == item.correctIndex) _score++;
      setState(() => _locked = true);
      return;
    }

    // already locked -> go next or finish
    if (_index < _quiz!.items.length - 1) {
      setState(() {
        _index++;
        _selected = -1;
        _locked = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final total = _quiz!.items.length == 0 ? 1 : _quiz!.items.length;
    final passed = _score / total >= _passRate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'ผ่านแบบฝึกหัด 🎉' : 'ยังไม่ผ่าน'),
        content: Text('คะแนนของคุณ: $_score / $total'),
        actions: [
          TextButton(
            onPressed: () {
              // review (restart)
              Navigator.pop(context);
              setState(() {
                _index = 0;
                _score = 0;
                _selected = -1;
                _locked = false;
              });
            },
            child: const Text('ทบทวน'),
          ),
          TextButton(
            onPressed: () {
              // แจ้งแผนที่ว่าผ่านแล้ว
              Navigator.pop(context);       // close dialog
              Navigator.pop(context, true); // return to map with success
            },
            child: const Text('กลับแผนที่'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    final bg = Image.asset('assets/images/backgroundselect.jpg', fit: BoxFit.cover);

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: bg),

          SafeArea(
            child: Column(
              children: [
                _AppBar(title: _appTitle()),
                Expanded(
                  child: quiz == null
                      ? const Center(child: CircularProgressIndicator())
                      : quiz.items.isEmpty
                          ? const _EmptyState(message: 'ไม่พบข้อสอบสำหรับบท/ด่านนี้')
                          : _QuestionView(
                              item: quiz.items[_index],
                              index: _index,
                              total: quiz.items.length,
                              selected: _selected,
                              locked: _locked,
                              onSelect: (i) => setState(() => _selected = i),
                            ),
                ),
                if (quiz != null && quiz.items.isNotEmpty)
                  _BottomBar(
                    locked: _locked,
                    isLast: _index == _quiz!.items.length - 1,
                    onPressed: _submitAnswer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _appTitle() {
    final subjectName = widget.subject.toLowerCase().startsWith('elec')
        ? 'Electronics'
        : 'Computer';
    final head = _quiz?.title ?? 'แบบฝึกหัด';
    return '$subjectName • บท ${widget.lesson} • ด่าน ${widget.stage} — $head';
  }
}

/* -------------------- widgets -------------------- */

class _AppBar extends StatelessWidget {
  final String title;
  const _AppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final _QuizItem item;
  final int index;
  final int total;
  final int selected;
  final bool locked;
  final ValueChanged<int> onSelect;

  const _QuestionView({
    required this.item,
    required this.index,
    required this.total,
    required this.selected,
    required this.locked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // index card
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('ข้อ ${index + 1} / $total',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),

          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(item.imageUrl!, fit: BoxFit.cover),
              ),
            ),

          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Text(
              item.text,
              style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),

          // choices
          ...List.generate(item.choices.length, (i) {
            final isCorrect = i == item.correctIndex;
            final isSelected = i == selected;

            Color? tileColor;
            if (locked && isCorrect) tileColor = Colors.green.withOpacity(0.15);
            if (locked && isSelected && !isCorrect) tileColor = Colors.red.withOpacity(0.12);

            return Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (locked
                          ? (isCorrect ? Colors.green : Colors.red)
                          : Colors.indigo)
                      : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: RadioListTile<int>(
                value: i,
                groupValue: selected,
                onChanged: locked ? null : (v) => onSelect(v!),
                title: Text(item.choices[i]),
                activeColor: locked
                    ? (isCorrect ? Colors.green : Colors.red)
                    : Colors.indigo,
              ),
            );
          }),
          const SizedBox(height: 90), // space for bottom button
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool locked;
  final bool isLast;
  final VoidCallback onPressed;

  const _BottomBar({
    required this.locked,
    required this.isLast,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = !locked
        ? 'ยืนยันคำตอบ'
        : (isLast ? 'ส่งคะแนน' : 'ข้อต่อไป');

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
