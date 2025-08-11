import 'package:flutter/material.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/subject/lesson_word.dart';
import 'package:techwisever1/question/question_page.dart';

class ElectronicsLessonMapPage extends StatefulWidget {
  final int lesson; // 1 / 2 / 3
  const ElectronicsLessonMapPage({super.key, required this.lesson});

  @override
  State<ElectronicsLessonMapPage> createState() => _ElectronicsLessonMapPageState();
}

class _ElectronicsLessonMapPageState extends State<ElectronicsLessonMapPage> {
  static const String _subject = 'electronics';

  // ทุกบท = 5 ด่าน
  int get _totalStages => 5;

  // โครงตาม Firebase ของคุณ: /questions/questionelec{lesson}/questionelec{lesson}-{setNo}/level_*
  String get _questionDocId => 'questionelec${widget.lesson}';

  late List<bool> _done;

  @override
  void initState() {
    super.initState();
    _done = List<bool>.filled(_totalStages, false);
  }

  Future<void> _goToStage(int index) async {
    final stage = index + 1;
    if (index > 0 && !_done[index - 1]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาผ่านด่านก่อนหน้าก่อน')),
      );
      return;
    }

    final proceed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonWordPage(
          subject: _subject,
          lesson: widget.lesson,
          stage: stage,
        ),
      ),
    );

    if (!mounted || proceed != true) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionTC1Page(
          docId: _questionDocId, // <- questionelec1/2/3
          setNo: stage,          // <- คอลเลกชันย่อย questionelec{lesson}-{stage}
          lesson: widget.lesson,
          stage: stage,
        ),
      ),
    );

    if (!mounted) return;
    if (result == true) setState(() => _done[index] = true);
  }

  Icon _badgeIcon(int index) {
    if (_done[index]) return const Icon(Icons.check, color: Colors.white, size: 26);
    if (index > 0 && !_done[index - 1]) return const Icon(Icons.lock, color: Colors.white, size: 26);
    return const Icon(Icons.help_outline, color: Colors.white, size: 26);
  }

  Color _badgeColor(int index) {
    if (_done[index]) return Colors.green[800]!;
    if (index > 0 && !_done[index - 1]) return Colors.grey[600]!;
    return Colors.blue[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox.expand(
          child: Image.asset('assets/images/backgroundbock.jpg', fit: BoxFit.cover),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,2))],
            ),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              Expanded(
                child: Center(
                  child: Text(
                    'แผนที่บทเรียนอิเล็กทรอนิกส์บท ${widget.lesson}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ]),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 86, bottom: 20),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_totalStages, (index) => Column(
                    children: [
                      GestureDetector(
                        onTap: () => _goToStage(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: (index > 0 && !_done[index - 1]) ? 0.6 : 1,
                          child: Container(
                            width: 70, height: 70, margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _badgeColor(index).withOpacity(0.95),
                                  _badgeColor(index).withOpacity(0.75),
                                ],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0,3))],
                            ),
                            child: Stack(alignment: Alignment.center, children: [
                              _badgeIcon(index),
                              Positioned(
                                bottom: 6,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      if (index < _totalStages - 1)
                        Container(width: 6, height: 26, color: Colors.black87),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ),
        Positioned(bottom: 0, left: 10, child: Image.asset('assets/images/TC_student.png', height: 100)),
        Positioned(bottom: 0, right: 10, child: Image.asset('assets/images/TC_student.png', height: 100)),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        onTap: (i) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainScreen(initialIndex: i)),
            (route) => false,
          );
        },
      ),
    );
  }
}
