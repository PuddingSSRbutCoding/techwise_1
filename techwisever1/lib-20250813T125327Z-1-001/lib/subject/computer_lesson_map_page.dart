import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/subject/lesson_word.dart';
import 'package:techwisever1/question/question_tc1_page.dart';
import 'package:techwisever1/services/local_prefs.dart';
import 'package:techwisever1/services/progress_service.dart';

class ComputerLessonMapPage extends StatefulWidget {
  final int lesson;
  final Set<int> completedStages;

  const ComputerLessonMapPage({
    super.key,
    required this.lesson,
    this.completedStages = const {},
  });

  @override
  State<ComputerLessonMapPage> createState() => _ComputerLessonMapPageState();
}

class _ComputerLessonMapPageState extends State<ComputerLessonMapPage> {
  static const _subject = 'computer';
  static const int kTotalStages = 3;
  static const int kTotalLessons = 3;

  bool _hide = false;
  bool _loading = true;
  Set<int> _completed = {};
  int? _justUnlocked; // สำหรับแอนิเมชัน

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hide = await LocalPrefs.I.getHideLessonContentFor(_subject, widget.lesson);
    Set<int> comp = {...widget.completedStages};

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        comp = await ProgressService.I.loadCompletedStages(
          uid: user.uid, subject: _subject, lesson: widget.lesson,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _hide = hide;
      _completed = comp;
      _loading = false;
    });
  }

  Future<void> _setHide(bool v) async {
    setState(() => _hide = v);
    await LocalPrefs.I.setHideLessonContentFor(_subject, widget.lesson, v);
  }

  Future<void> _openStage(int stage) async {
    final locked = stage != 1 && !_completed.contains(stage - 1);
    if (locked) {
      _showInfo('ด่านนี้ยังไม่ปลดล็อก', 'กรุณาผ่านด่าน ${stage - 1} ก่อน');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _hide
            ? QuestionTC1Page(
                lesson: widget.lesson,
                stage: stage,
                subject: 'computer', // ✅ ชี้วิชา
              )
            : LessonWordPage(
                subject: _subject,
                lesson: widget.lesson,
                stage: stage,
              ),
      ),
    );

    if (result == true) {
      setState(() {
        _completed.add(stage);
        _justUnlocked = stage; // เล่นแอนิเมชัน
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await ProgressService.I.addCompletedStage(
            uid: user.uid, subject: _subject, lesson: widget.lesson, stage: stage,
          );
        } catch (_) {}
      }

      _showPassedSheet(stage);
    }
  }

  void _showInfo(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title), content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง'))],
      ),
    );
  }

  void _showPassedSheet(int stage) {
    final hasNext = stage < kTotalStages;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 42, color: Colors.green),
            const SizedBox(height: 8),
            Text('ผ่านด่าน $stage แล้ว!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('กลับแผนที่'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasNext
                        ? () {
                            Navigator.pop(context);
                            _openStage(stage + 1);
                          }
                        : null,
                    child: Text(hasNext ? 'ทำด่านถัดไป' : 'ครบทุกด่านแล้ว'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson.clamp(1, kTotalLessons);

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/images/backgroundselect.jpg', fit: BoxFit.cover),
          ),

          // แถบบน + toggle
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: Offset(0,2))],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                          (r) => false,
                        );
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: Offset(0,3))],
                          ),
                          child: Text('บทที่ $lesson คอมพิวเตอร์เบื้องต้น',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Row(children: [
                              const Text('ซ่อนเนื้อหา', style: TextStyle(fontSize: 12)),
                              Switch(value: _hide, onChanged: _setHide),
                            ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // เฮกซากอน 3 ด่าน + เส้นเชื่อม
          Positioned.fill(
            top: 110,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(kTotalStages, (i) {
                    final stage = i + 1;
                    final done = _completed.contains(stage);
                    final locked = stage != 1 && !_completed.contains(stage - 1);

                    return Column(
                      children: [
                        Opacity(
                          opacity: locked ? 0.55 : 1,
                          child: _HexStackBadge(
                            number: stage,
                            completed: done,
                            unlocking: _justUnlocked == stage,
                            onTap: () => _openStage(stage),
                          ),
                        ),
                        if (stage != kTotalStages) _ThickConnector(),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───── UI helpers ───── */

class _ThickConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10, height: 40, margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1F1F1F), Color(0xFF2E2E2E), Color(0xFF1F1F1F)],
        ),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))],
      ),
    );
  }
}

class _HexStackBadge extends StatelessWidget {
  final int number;
  final bool completed;
  final bool unlocking;
  final VoidCallback onTap;

  const _HexStackBadge({
    required this.number,
    required this.completed,
    required this.unlocking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainFill = completed ? const Color(0xFF06C167) : const Color(0xFFE0E0E0);
    final Color numberColor = completed ? Colors.white : const Color(0xFF666666);

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: unlocking ? 0.6 : 1.0, end: 1.0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                boxShadow: unlocking
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.55),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                width: 120, height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int depth = 3; depth >= 1; depth--)
                      Transform.translate(
                        offset: Offset(0, (depth - 1) * 6.0),
                        child: _Hexagon(
                          size: 54, fill: Colors.white,
                          borderColor: Colors.black.withOpacity(0.10), borderWidth: 1.2,
                          shadow: BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4)),
                        ),
                      ),
                    _Hexagon(
                      size: 54, fill: mainFill, borderColor: Colors.white, borderWidth: 3,
                      shadow: BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: unlocking ? 14 : 10,
                        offset: const Offset(0, 6),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(color: numberColor, fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Hexagon extends StatelessWidget {
  final double size;
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final BoxShadow? shadow;
  final Widget? child;

  const _Hexagon({
    required this.size, required this.fill, required this.borderColor, required this.borderWidth,
    this.shadow, this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double w = size * 2;
    final double h = size * 2 * 0.8660254;
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(boxShadow: shadow != null ? [shadow!] : null),
      child: ClipPath(
        clipper: _HexClipper(),
        child: Container(
          color: fill,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _HexBorderPainter(color: borderColor, stroke: borderWidth)),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height, a = w / 2, b = h / 2;
    return Path()
      ..moveTo(a, 0)
      ..lineTo(w, b * 0.5)
      ..lineTo(w, b * 1.5)
      ..lineTo(a, h)
      ..lineTo(0, b * 1.5)
      ..lineTo(0, b * 0.5)
      ..close();
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexBorderPainter extends CustomPainter {
  final Color color; final double stroke;
  _HexBorderPainter({required this.color, required this.stroke});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke;
    final w = size.width, h = size.height, a = w / 2, b = h / 2;
    final path = Path()
      ..moveTo(a, 0)
      ..lineTo(w, b * 0.5)..lineTo(w, b * 1.5)..lineTo(a, h)
      ..lineTo(0, b * 1.5)..lineTo(0, b * 0.5)..close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
