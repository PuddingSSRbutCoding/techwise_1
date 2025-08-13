import 'dart:ui';
import 'package:flutter/material.dart';
import 'computer_lesson_map_page.dart';
import 'electronics_lesson_map_page.dart';

class LessonIntroPage extends StatelessWidget {
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
                      _Pill(text: subject.toUpperCase()),
                      const SizedBox(width: 8),
                      _Pill(text: 'บท $lesson'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  GradientText(
                    title,
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
                            if (heroAsset != null && heroAsset!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.black, width: 3), // ✅ กรอบสีดำ
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    width: double.infinity,
                                    height: 140, // ปรับขนาดตามต้องการ
                                    child: _buildHeroImage(heroAsset!),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  intro,
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

                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (onStart != null) {
                            onStart!();
                          } else {
                            _goToMap(context);
                          }
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
                          'ไปแบบทบทวนเรียน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
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
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
        loadingBuilder: (c, w, progress) =>
            progress == null
                ? w
                : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.image_not_supported)),
      );
    }
  }

  void _goToMap(BuildContext context) {
    final lower = subject.toLowerCase();
    if (lower.startsWith('comp')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ComputerLessonMapPage(lesson: lesson)),
      );
    } else if (lower.startsWith('elec')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ElectronicsLessonMapPage(lesson: lesson)),
      );
    } else {
      Navigator.pop(context);
    }
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
  const GradientText(this.text,
      {super.key, required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
