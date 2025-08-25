import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techwisever1/subject/electronics_page.dart';
import 'package:techwisever1/subject/computertech_page.dart';
import 'package:techwisever1/subject/dynamic_subject_page.dart';
import 'package:techwisever1/services/subject_progress_service.dart';
import 'package:techwisever1/services/ui_constants.dart';

class SelectSubjectPage extends StatefulWidget {
  const SelectSubjectPage({super.key});

  @override
  State<SelectSubjectPage> createState() => _SelectSubjectPageState();
}

class _SelectSubjectPageState extends State<SelectSubjectPage>
    with TickerProviderStateMixin {
  final GlobalKey<_SubjectCardCenteredState> _electronicsCardKey =
      GlobalKey<_SubjectCardCenteredState>();
  final GlobalKey<_SubjectCardCenteredState> _computerCardKey =
      GlobalKey<_SubjectCardCenteredState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // รายการวิชาที่มีอยู่แล้ว
  final Map<String, Map<String, dynamic>> _existingSubjects = {
    'computer': {
      'title': 'คอมพิวเตอร์',
      'image': 'assets/images/TC1.png',
      'color': Colors.blue,
      'page': ComputerTechPage(),
    },
    'electronics': {
      'title': 'อิเล็กทรอนิกส์',
      'image': 'assets/images/TC2.jpg',
      'color': Colors.green,
      'page': ElectronicsPage(),
    },
  };

  // รายการวิชาใหม่จาก Firebase
  List<Map<String, dynamic>> _dynamicSubjects = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
    
    // โหลดวิชาใหม่จาก Firebase
    _loadDynamicSubjects();
  }

  Future<void> _loadDynamicSubjects() async {
    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .get();
      
      final subjects = <Map<String, dynamic>>[];
      for (final doc in subjectsSnapshot.docs) {
        final subjectId = doc.id;
        
        // ข้ามวิชาที่มีอยู่แล้ว
        if (_existingSubjects.containsKey(subjectId)) continue;
        
        final data = doc.data();
        final title = data['title'] ?? _getDefaultSubjectTitle(subjectId);
        final image = data['image'] ?? 'assets/images/TC3.png';
        final color = _getSubjectColor(subjectId);
        
        subjects.add({
          'id': subjectId,
          'title': title,
          'image': image,
          'color': color,
          'data': data,
        });
      }
      
      if (mounted) {
        setState(() {
          _dynamicSubjects = subjects;
        });
      }
    } catch (e) {
      debugPrint('Error loading dynamic subjects: $e');
    }
  }

  String _getDefaultSubjectTitle(String subjectId) {
    switch (subjectId) {
      case 'programming':
        return 'การเขียนโปรแกรม';
      case 'mathematics':
        return 'คณิตศาสตร์';
      case 'science':
        return 'วิทยาศาสตร์';
      case 'language':
        return 'ภาษาไทย';
      default:
        // แปลง subjectId เป็นชื่อภาษาไทย
        return subjectId.split('_').map((word) {
          if (word == 'programming') return 'การเขียนโปรแกรม';
          if (word == 'math') return 'คณิตศาสตร์';
          if (word == 'science') return 'วิทยาศาสตร์';
          if (word == 'thai') return 'ภาษาไทย';
          if (word == 'english') return 'ภาษาอังกฤษ';
          return word;
        }).join(' ');
    }
  }

  Color _getSubjectColor(String subjectId) {
    switch (subjectId) {
      case 'programming':
        return Colors.purple;
      case 'mathematics':
        return Colors.orange;
      case 'science':
        return Colors.teal;
      case 'language':
        return Colors.indigo;
      default:
        // สร้างสีจาก hash ของ subjectId
        final hash = subjectId.hashCode;
        return Color.fromARGB(255, (hash % 200) + 55, ((hash >> 8) % 200) + 55, ((hash >> 16) % 200) + 55);
    }
  }

  void _navigateToSubject(String subjectId, Map<String, dynamic> subjectData) {
    if (_existingSubjects.containsKey(subjectId)) {
      // ใช้หน้าเดิม
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _existingSubjects[subjectId]!['page'] as Widget,
        ),
      );
    } else {
      // ใช้หน้าใหม่แบบไดนามิก
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DynamicSubjectPage(
            subjectId: subjectId,
            subjectData: subjectData,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ ใช้ UIConstants สำหรับ AppBar
      appBar: AppBar(
        elevation: UIConstants.cardElevation,
        backgroundColor: UIConstants.surfaceColor,
        foregroundColor: UIConstants.textPrimaryColor,
        shadowColor: UIConstants.cardShadow.first.color,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: UIConstants.appBarHeight,
        title: Text(
          'TechWise',
          style: TextStyle(
            fontSize: UIConstants.fontSizeXXLarge,
            fontWeight: FontWeight.bold,
            color: UIConstants.primaryColor,
          ),
        ),
        centerTitle: true,
        // เพิ่ม icon หรือปุ่มเพิ่มเติมถ้าต้องการ
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: UIConstants.primaryColor),
            onPressed: () {
              // แสดงข้อมูลเกี่ยวกับแอป
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('TechWise - แอปพลิเคชันการเรียนรู้เทคโนโลยี'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: UIConstants.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const _GradientBackground(),
          const _DecorativeBlobs(),
          // ✅ เพิ่ม SafeArea เพื่อแยกส่วนจาก status bar และ navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  // Header Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const _HeadlinePill(text: 'ฉันอยากจะเรียน'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'เลือกหัวข้อที่คุณสนใจ แล้วเริ่มเรียนได้ทันที',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Subject Cards Section
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cross = c.maxWidth >= 720 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: cross,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          children: [
                            // วิชาคอมพิวเตอร์
                            SubjectCardCentered(
                              key: _computerCardKey,
                              accent: Colors.blue,
                              icon: Icons.computer,
                              title: 'คอมพิวเตอร์',
                              subtitle: 'เข้าใจระบบคอมพิวเตอร์ และเทคโนโลยีสารสนเทศ',
                              subjectKey: 'computer',
                              onTap: () => _navigateToSubject('computer', _existingSubjects['computer']!),
                            ),
                            
                            // วิชาอิเล็กทรอนิกส์
                            SubjectCardCentered(
                              key: _electronicsCardKey,
                              accent: Colors.green,
                              icon: Icons.bolt,
                              title: 'อิเล็กทรอนิกส์',
                              subtitle: 'เรียนรู้พื้นฐานอิเล็กทรอนิกส์ และวงจรไฟฟ้า',
                              subjectKey: 'electronics',
                              onTap: () => _navigateToSubject('electronics', _existingSubjects['electronics']!),
                            ),
                            
                            // วิชาใหม่แบบไดนามิก
                            ..._dynamicSubjects.map((subject) => SubjectCardCentered(
                              accent: subject['color'] ?? Colors.purple,
                              icon: Icons.school,
                              title: subject['title'],
                              subtitle: 'บทเรียน${subject['title']}',
                              onTap: () => _navigateToSubject(subject['id'], subject),
                            )),
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Info Section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'เลือกวิชาที่คุณสนใจเพื่อเริ่มต้นการเรียนรู้',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Corner Decorations
          const Positioned(
            left: -15,
            bottom: -15,
            child: _CornerMascot(icon: Icons.psychology_alt, size: 120),
          ),
          const Positioned(
            right: -15,
            bottom: -15,
            child: _CornerMascot(icon: Icons.smart_toy, size: 120),
          ),
        ],
      ),
    );
  }
}

/* ======= Background / UI components ======= */

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.8, -1.0),
          end: Alignment(0.8, 1.0),
          colors: [
            Color(0xFF64B5F6), // ฟ้าอ่อน
            Color(0xFF42A5F5), // ฟ้า
            Color(0xFF1976D2), // ฟ้าเข้ม
          ],
          stops: [0.0, 0.5, 1.0],
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
          Positioned(
            top: -80,
            left: -50,
            child: _Blob(size: 200, opacity: 0.12),
          ),
          Positioned(
            top: 50,
            right: -30,
            child: _Blob(size: 150, opacity: 0.10),
          ),
          Positioned(
            top: 180,
            left: -15,
            child: _Blob(size: 130, opacity: 0.08),
          ),
          Positioned(
            bottom: 80,
            right: 40,
            child: _Blob(size: 100, opacity: 0.06),
          ),
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
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeadlinePill extends StatelessWidget {
  final String text;

  const _HeadlinePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Color(0xFF1976D2),
        ),
      ),
    );
  }
}

class SubjectCardCentered extends StatefulWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? subjectKey;

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

class _SubjectCardCenteredState extends State<SubjectCardCentered>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  Map<String, dynamic>? _progressData;
  bool _isLoadingProgress = true;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _loadProgress();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          _scaleController.forward();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          _scaleController.reverse();
        },
        onTapCancel: () {
          setState(() => _pressed = false);
          _scaleController.reverse();
        },
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _GradientBorder(
                radius: 24,
                colors: [
                  widget.accent.withOpacity(0.8),
                  widget.accent.withOpacity(0.4),
                ],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  widget.accent.withOpacity(0.25),
                                  widget.accent.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.accent.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: 36,
                              color: widget.accent,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Title
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: widget.accent.withOpacity(0.9),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.accent.withOpacity(0.7),
                              height: 1.1,
                            ),
                          ),

                          // Progress Section
                          if (widget.subjectKey != null) ...[
                            const SizedBox(height: 8),
                            _buildProgressSection(),
                          ],

                          // Hover Effect
                          if (_hovered) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.accent.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'คลิกเพื่อเริ่มเรียน',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_isLoadingProgress) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: widget.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: SizedBox(
          height: 12,
          width: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
          ),
        ),
      );
    }

    if (_progressData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          'ยังไม่เริ่มเรียน',
          style: TextStyle(
            fontSize: 10,
            color: widget.accent.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final percentage = _progressData!['percentage'] as double;
    final progressColor = percentage > 50
        ? Colors.green
        : percentage > 25
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: widget.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.accent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 12, color: widget.accent),
          const SizedBox(width: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              color: widget.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  final List<Color> colors;

  const _GradientBorder({
    required this.child,
    required this.radius,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(radius - 2),
        ),
        child: child,
      ),
    );
  }
}

class _CornerMascot extends StatelessWidget {
  final IconData icon;
  final double size;

  const _CornerMascot({required this.icon, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.08,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(icon, size: size * 0.5, color: Colors.black87),
      ),
    );
  }
}
