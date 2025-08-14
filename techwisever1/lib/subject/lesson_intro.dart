import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'computer_lesson_map_page.dart';
import 'electronics_lesson_map_page.dart';

class LessonIntroPage extends StatefulWidget {
  final String subject; // 'computer' | 'electronics'
  final int lesson;     // 1..n
  final String title;
  final String intro;
  final String? heroAsset;     // รองรับทั้ง asset path และ URL
  final VoidCallback? onStart;

  const LessonIntroPage({
    super.key,
    required this.subject,
    required this.lesson,
    required this.title,
    required this.intro,
    this.heroAsset,
    this.onStart,
  });

  @override
  State<LessonIntroPage> createState() => _LessonIntroPageState();
}

class _LessonIntroPageState extends State<LessonIntroPage> {
  // เก็บสถานะ skip ปัจจุบัน (โหลดจาก local/cloud)
  bool _skip = false;

  // คีย์ใน local ที่ผูกกับผู้ใช้ (uid ถ้ามี)
  Future<String> _localKey() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return 'skip_intro_${uid}_${widget.subject}_${widget.lesson}';
  }

  @override
  void initState() {
    super.initState();
    // หลังเฟรมแรก ค่อยเช็คและ auto-skip ถ้าจำเป็น
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSkip());
  }

  Future<void> _maybeAutoSkip() async {
    final skip = await _loadSkipFlag();
    if (!mounted) return;
    setState(() => _skip = skip);

    if (skip) {
      // ถ้าต้องข้าม ให้แทนหน้านี้ทันที → ย้อนหลังจะไม่เห็น Intro
      _goToMap(context, replace: true);
    }
  }

  /// โหลดค่าสถานะ skip แบบ "ต่อผู้ใช้"
  /// ลำดับความสำคัญ: Local (เร็ว/ออฟไลน์) -> Cloud Firestore (หากมี uid)
  Future<bool> _loadSkipFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _localKey();
    bool skip = prefs.getBool(key) ?? false;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !skip) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('prefs')
            .doc('intro_skips')
            .get();

        if (doc.exists) {
          final data = (doc.data() ?? <String, dynamic>{});
          final cloudKey = '${widget.subject}_${widget.lesson}';
          // รองรับสองรูปแบบ: ฟิลด์ boolean รายบท หรือ array ต่อวิชา
          skip = (data[cloudKey] == true) ||
                 (data[widget.subject] is List && (data[widget.subject] as List).contains(widget.lesson));
          if (skip) {
            await prefs.setBool(key, true); // แคชไว้ให้เร็ว/ออฟไลน์
          }
        }
      } catch (_) {
        // เงียบไว้ถ้าออฟไลน์หรืออ่าน cloud ไม่ได้
      }
    }
    return skip;
  }

  /// ตั้งค่าว่า "อย่าแสดงอีก" ทั้งใน Local และ (ถ้ามี uid) ใน Cloud
  Future<void> _setSkipTrue() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _localKey();
    await prefs.setBool(key, true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('prefs')
            .doc('intro_skips')
            .set(
              {'${widget.subject}_${widget.lesson}': true},
              SetOptions(merge: true),
            );
      } catch (_) {
        // เงียบไว้ถ้าออฟไลน์—อย่างน้อย local ก็ทำงาน
      }
    }
    if (mounted) setState(() => _skip = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const _GradientBackground(),
          const _RingsDecor(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Pill(text: widget.subject.toUpperCase()),
                      const SizedBox(width: 8),
                      _Pill(text: 'บท ${widget.lesson}'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  GradientText(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF7FF), Colors.white],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (widget.heroAsset != null && widget.heroAsset!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    width: double.infinity,
                                    height: 140,
                                    child: _buildHeroImage(widget.heroAsset!),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.intro,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ปุ่มหลัก: เข้าเรียน (ถ้า _skip = true จะ replace, ไม่งั้น push)
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onStart != null) {
                            widget.onStart!();
                          }
                          _goToMap(context, replace: _skip);
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 8,
                          backgroundColor: const Color(0xFF7E57C2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text(
                          'ไปยังหน้าถัดไป',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ปุ่มรอง: ไม่แสดงหน้านี้อีก (บันทึก per-account แล้ว replace)
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _setSkipTrue();
                          _goToMap(context, replace: true);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(width: 1.2, color: Colors.white),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.hide_source),
                        label: const Text(
                          'ไม่แสดงหน้านี้อีก',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // รองรับทั้ง asset และ network image
  Widget _buildHeroImage(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
        loadingBuilder: (c, w, progress) =>
            progress == null ? w : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
      );
    }
  }

  // ถ้า replace=true จะไม่เหลือ Intro ในสแตก → กดย้อนจาก Map จะไม่กลับมา Intro
  void _goToMap(BuildContext context, {bool replace = false}) {
    final lower = widget.subject.toLowerCase();
    final Widget dest = lower.startsWith('comp')
        ? ComputerLessonMapPage(lesson: widget.lesson)
        : lower.startsWith('elec')
            ? ElectronicsLessonMapPage(lesson: widget.lesson)
            : const _FallbackPop();

    if (replace) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
    }
  }
}

// ใช้กรณี subject ไม่ตรง → แค่ pop กลับ
class _FallbackPop extends StatelessWidget {
  const _FallbackPop({super.key});
  @override
  Widget build(BuildContext context) {
    Future.microtask(() => Navigator.pop(context));
    return const SizedBox.shrink();
  }
}

/* --------------------------- Decorations --------------------------- */

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.9, -1.0),
          end: Alignment(0.9, 1.0),
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
        ),
      ),
    );
  }
}

class _RingsDecor extends StatelessWidget {
  const _RingsDecor();

  @override
  Widget build(BuildContext context) {
    final ring = (double size, Offset pos, double opacity) => Positioned(
          left: pos.dx,
          top: pos.dy,
          child: _Ring(size: size, opacity: opacity),
        );
    return IgnorePointer(
      child: Stack(
        children: [
          ring(120, const Offset(-20, 60), .20),
          ring(74, const Offset(36, 180), .14),
          ring(92, const Offset(210, 120), .12),
          ring(140, const Offset(80, 320), .10),
          ring(180, const Offset(-30, 460), .08),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final double opacity;
  const _Ring({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 10),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(.25),
              blurRadius: 20,
              spreadRadius: -6,
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Widgets ------------------------------ */

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.90),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.14),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  const GradientText(this.text, {super.key, required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
