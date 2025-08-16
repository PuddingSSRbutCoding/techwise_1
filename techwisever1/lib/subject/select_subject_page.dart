import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/subject/electronics_page.dart';
import 'package:techwisever1/subject/computertech_page.dart';
import 'package:techwisever1/services/subject_progress_service.dart';

class SelectSubjectPage extends StatefulWidget {
  const SelectSubjectPage({super.key});

  @override
  State<SelectSubjectPage> createState() => _SelectSubjectPageState();
}

class _SelectSubjectPageState extends State<SelectSubjectPage> {
  final GlobalKey<_SubjectCardCenteredState> _electronicsCardKey = GlobalKey<_SubjectCardCenteredState>();
  final GlobalKey<_SubjectCardCenteredState> _computerCardKey = GlobalKey<_SubjectCardCenteredState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          const _GradientBackground(),
          const _DecorativeBlobs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  const _HeadlinePill(text: 'ฉันอยากจะเรียน'),
                  const SizedBox(height: 12),
                  Text(
                    'เลือกหัวข้อที่คุณสนใจ แล้วเริ่มเรียนได้ทันที',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.92),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cross = c.maxWidth >= 720 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: cross,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          padding: const EdgeInsets.only(bottom: 12),
                          children: [
                            SubjectCardCentered(
                              key: _electronicsCardKey,
                              accent: const Color(0xFF00B894),
                              icon: Icons.bolt,
                              title: 'อิเล็กทรอนิกส์',
                              subtitle: 'พื้นฐาน · วงจร · เครื่องมือ',
                              subjectKey: 'electronics', // เพิ่ม subject key
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ElectronicsPage()),
                                );
                                // รีเฟรชข้อมูลเมื่อกลับมา
                                _electronicsCardKey.currentState?._loadProgress();
                              },
                            ),
                            SubjectCardCentered(
                              key: _computerCardKey,
                              accent: const Color(0xFF2962FF),
                              icon: Icons.computer,
                              title: 'เทคนิคคอมพิวเตอร์',
                              subtitle: 'ฮาร์ดแวร์ · ซอฟต์แวร์ · เครือข่าย',
                              subjectKey: 'computer', // เพิ่ม subject key
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ComputerTechPage()),
                                );
                                // รีเฟรชข้อมูลเมื่อกลับมา
                                _computerCardKey.currentState?._loadProgress();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(left: -10, bottom: -10, child: _CornerMascot(icon: Icons.psychology_alt)),
          const Positioned(right: -10, bottom: -10, child: _CornerMascot(icon: Icons.smart_toy)),
        ],
      ),
    );
  }
}

/* ======= Background / UI components (คงของเดิม) ======= */

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -1.0),
          end: Alignment(0.9, 1.0),
          colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
        ),
      ),
    );
  }
}

class _DecorativeBlobs extends StatelessWidget {
  const _DecorativeBlobs();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(top: -120, left: -80, child: _Blob(size: 260, opacity: .14)),
          Positioned(top: 40, right: -60, child: _Blob(size: 200, opacity: .12)),
          Positioned(top: 220, left: -40, child: _Blob(size: 180, opacity: .10)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(width: size, height: size, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
    );
  }
}

class _HeadlinePill extends StatelessWidget {
  final String text;
  const _HeadlinePill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: .3)),
    );
  }
}

class SubjectCardCentered extends StatefulWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? subjectKey; // เพิ่มสำหรับดึงข้อมูลความคืบหน้า
  const SubjectCardCentered({
    super.key, 
    required this.accent, 
    required this.icon, 
    required this.title, 
    required this.subtitle, 
    required this.onTap,
    this.subjectKey,
  });
  @override
  State<SubjectCardCentered> createState() => _SubjectCardCenteredState();
}

class _SubjectCardCenteredState extends State<SubjectCardCentered> {
  bool _pressed = false;
  Map<String, dynamic>? _progressData;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (widget.subjectKey == null) {
      setState(() => _isLoadingProgress = false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingProgress = false);
      return;
    }

    try {
      final progress = await SubjectProgressService.instance.getSubjectProgress(
        uid: uid,
        subject: widget.subjectKey!,
      );
      if (mounted) {
        setState(() {
          _progressData = progress;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed ? .98 : 1.0,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: _GradientBorder(
          radius: 22, colors: [widget.accent.withOpacity(.55), Colors.white.withOpacity(.65)],
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.90),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 10))],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [widget.accent.withOpacity(.18), widget.accent.withOpacity(.08)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(widget.icon, size: 38, color: widget.accent),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.2)),
                    
                    // แสดงความคืบหน้า
                    if (widget.subjectKey != null) ...[
                      const SizedBox(height: 6),
                      _buildProgressSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_isLoadingProgress) {
      return const SizedBox(
        height: 12,
        width: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    }

    if (_progressData == null) {
      return const SizedBox.shrink();
    }

    final percentage = _progressData!['percentage'] as double;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: widget.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.accent.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 10,
          color: widget.accent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GradientBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  final List<Color> colors;
  const _GradientBorder({required this.child, required this.radius, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(radius)),
      child: Container(
        margin: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.02), borderRadius: BorderRadius.circular(radius - 2)),
        child: child,
      ),
    );
  }
}

class _CornerMascot extends StatelessWidget {
  final IconData icon;
  const _CornerMascot({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .10,
      child: Container(width: 120, height: 120, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Icon(icon, size: 60, color: Colors.black87)),
    );
  }
}
