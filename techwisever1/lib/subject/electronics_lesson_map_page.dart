// lib/subject/electronics_lesson_map_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/subject/lesson_word.dart';
import 'package:techwisever1/question/question_page.dart';
import 'package:techwisever1/services/local_prefs.dart';
import 'package:techwisever1/services/progress_service.dart';

class ElectronicsLessonMapPage extends StatefulWidget {
  final int lesson;
  final Set<int> completedStages;

  const ElectronicsLessonMapPage({
    super.key,
    required this.lesson,
    this.completedStages = const {},
  });

  @override
  State<ElectronicsLessonMapPage> createState() => _ElectronicsLessonMapPageState();
}

class _ElectronicsLessonMapPageState extends State<ElectronicsLessonMapPage> {
  static const _subject = 'electronics';
  static const int kTotalLessons = 3;

  // fallback ถ้าดึงจาก Firestore ไม่ได้
  static const Map<int, int> _fallbackStages = {1: 4, 2: 5, 3: 4};

  bool _hide = false;
  bool _loading = true;
  Set<int> _completed = {};
  int? _justUnlocked;
  int _totalStages = 3;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _clearSnackBars() {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.clearSnackBars();
  }

  void _goBack() {
    _clearSnackBars();
    Navigator.pop(context);
  }

  void _goHome() {
    _clearSnackBars();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
      (r) => false,
    );
  }

  void _goProfile() {
    _clearSnackBars();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
      (r) => false,
    );
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

    final detected = await _detectTotalStages(widget.lesson);
    final total = detected > 0 ? detected : (_fallbackStages[widget.lesson] ?? 3);

    if (!mounted) return;
    setState(() {
      _hide = hide;
      _completed = comp;
      _totalStages = total;
      _loading = false;
    });
  }

  /// ตรวจจำนวนด่านจาก Firestore ตามโครงสร้างของอิเล็กทรอนิกส์:
  ///  - collection: lesson_elec  (ถ้ามี)
  ///  - docId: electronics_<lesson>_<stage>  เช่น electronics_1_4
  ///  - fields: { subject:'electronics', lesson:int, state:int | stage:int }
  Future<int> _detectTotalStages(int lesson) async {
    int maxStage = 0;

    // 1) where ด้วย subject + lesson (ไม่ใส่ stage เพื่อจะได้รวบทุกด่าน) จาก lesson_elec
    try {
      final qs = await FirebaseFirestore.instance
          .collection('lesson_elec')
          .where('subject', isEqualTo: _subject)
          .where('lesson', isEqualTo: lesson)
          .get();

      for (final d in qs.docs) {
        final data = d.data();
        int? s = (data['stage'] as int?) ?? (data['state'] as int?);
        s ??= int.tryParse(RegExp(r'_(\d+)$').firstMatch(d.id)?.group(1) ?? '');
        if (s != null && s > maxStage) maxStage = s;
      }
      if (maxStage > 0) return maxStage;
    } catch (_) {
      // ถ้า index ไม่พอจะไปสแกนทั้งคอลเลกชัน
    }

    // 2) fallback: scan ทั้งคอลเลกชัน lesson_elec แล้วกรองจาก prefix id
    try {
      final all = await FirebaseFirestore.instance.collection('lesson_elec').get();
      final prefix = '$_subject' '_$lesson' '_'; // e.g. electronics_1_
      for (final d in all.docs) {
        if (!d.id.startsWith(prefix)) continue;
        final data = d.data();
        int? s = (data['stage'] as int?) ?? (data['state'] as int?);
        s ??= int.tryParse(RegExp(r'_(\d+)$').firstMatch(d.id)?.group(1) ?? '');
        if (s != null && s > maxStage) maxStage = s;
      }
      if (maxStage > 0) return maxStage;
    } catch (_) {}

    // 3) โครงอื่น ๆ ที่อาจใช้ร่วม: ค้นใน 'questions' / 'subjects/...'
    try {
      final qsA = await FirebaseFirestore.instance
          .collection('questions')
          .where('subject', isEqualTo: _subject)
          .where('lesson', isEqualTo: lesson)
          .get();
      if (qsA.docs.isNotEmpty) {
        final stages = <int>{};
        for (final d in qsA.docs) {
          final s = d.data()['stage'];
          if (s is int && s > 0) stages.add(s);
        }
        if (stages.isNotEmpty) {
          return stages.reduce((a, b) => a > b ? a : b);
        }
      }
    } catch (_) {}

    try {
      final qsB = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subject)
          .collection('lessons')
          .doc('$lesson')
          .collection('questions')
          .get();
      if (qsB.docs.isNotEmpty) {
        final stages = <int>{};
        for (final d in qsB.docs) {
          final s = d.data()['stage'];
          if (s is int && s > 0) stages.add(s);
        }
        if (stages.isNotEmpty) {
          return stages.reduce((a, b) => a > b ? a : b);
        }
      }
    } catch (_) {}

    try {
      final qsC = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(_subject)
          .collection('lessons')
          .doc('$lesson')
          .collection('stages')
          .get();
      if (qsC.docs.isNotEmpty) {
        int max = 0;
        for (final d in qsC.docs) {
          final n = int.tryParse(d.id.replaceAll(RegExp(r'[^0-9]'), ''));
          if (n != null && n > max) max = n;
        }
        if (max > 0) return max;
      }
    } catch (_) {}

    return 0;
  }

  Future<void> _setHide(bool v) async {
    setState(() => _hide = v);
    await LocalPrefs.I.setHideLessonContentFor(_subject, widget.lesson, v);
  }

  Future<void> _openStage(int stage) async {
    // ล็อกด่านถ้ายังไม่ผ่านด่านก่อนหน้า
    final locked = stage != 1 && !_completed.contains(stage - 1);
    if (locked) {
      _showInfo('ด่านนี้ยังไม่ปลดล็อก', 'กรุณาผ่านด่าน ${stage - 1} ก่อน');
      return;
    }

    // ถ้าไม่ซ่อน ให้เข้าหน้าบทเรียนก่อน
    if (!_hide) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonWordPage(
            subject: _subject,
            lesson: widget.lesson,
            stage: stage,
            wordDocId: '${_subject}_${widget.lesson}_$stage',
          ),
        ),
      );
    }

    // แล้วเข้าหน้าคำถาม
    final passed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionTC1Page(
          lesson: widget.lesson,
          stage: stage,
          subject: _subject,
        ),
      ),
    );

    if (passed == true) {
      setState(() {
        _completed.add(stage);
        _justUnlocked = stage;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await ProgressService.I.addCompletedStage(
            uid: user.uid,
            subject: _subject,
            lesson: widget.lesson,
            stage: stage,
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
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showPassedSheet(int stage) {
    final hasNext = stage < _totalStages;
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

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/images/backgroundselect.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _goBack,
                      ),
                      Expanded(
  child: Center(
    child: Text(
      'บท $lesson อิเล็กทรอนิกส์',
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    ),
  ),
),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                children: [
                                  const Text('ซ่อนเนื้อหา', style: TextStyle(fontSize: 12)),
                                  Switch(value: _hide, onChanged: _setHide),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Body: แผนที่ด่าน
            Positioned.fill(
              top: 110,
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                            ),
                            ...List.generate(_totalStages, (i) {
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
                                  if (stage != _totalStages) _ThickConnector(),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),

        // Bottom Nav
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          onTap: (i) => i == 0 ? _goHome() : _goProfile(),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
          ],
        ),
      ),
    );
  }
}

/* ───── UI helpers ───── */

class _ThickConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F1F1F), Color(0xFF2E2E2E), Color(0xFF1F1F1F)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))
        ],
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
    final Color mainFill =
        completed ? const Color(0xFF06C167) : const Color(0xFFE0E0E0);
    final Color numberColor =
        completed ? Colors.white : const Color(0xFF666666);

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
                        )
                      ]
                    : null,
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int depth = 3; depth >= 1; depth--)
                      Transform.translate(
                        offset: Offset(0, (depth - 1) * 6.0),
                        child: _Hexagon(
                          size: 54,
                          fill: Colors.white,
                          borderColor: Colors.black.withOpacity(0.10),
                          borderWidth: 1.2,
                          shadow: BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ),
                      ),
                    _Hexagon(
                      size: 54,
                      fill: mainFill,
                      borderColor: Colors.white,
                      borderWidth: 3,
                      shadow: BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: unlocking ? 14 : 10,
                        offset: const Offset(0, 6),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            color: numberColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
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
    required this.size,
    required this.fill,
    required this.borderColor,
    required this.borderWidth,
    this.shadow,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double w = size * 2;
    final double h = size * 2 * 0.8660254;
    return Container(
      width: w,
      height: h,
      decoration:
          BoxDecoration(boxShadow: shadow != null ? [shadow!] : null),
      child: ClipPath(
        clipper: _HexClipper(),
        child: Container(
          color: fill,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _HexBorderPainter(
                  color: borderColor,
                  stroke: borderWidth,
                ),
              ),
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
  final Color color;
  final double stroke;

  _HexBorderPainter({required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final w = size.width, h = size.height, a = w / 2, b = h / 2;
    final path = Path()
      ..moveTo(a, 0)
      ..lineTo(w, b * 0.5)
      ..lineTo(w, b * 1.5)
      ..lineTo(a, h)
      ..lineTo(0, b * 1.5)
      ..lineTo(0, b * 0.5)
      ..close();

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
