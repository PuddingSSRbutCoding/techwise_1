import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/services/progress_service.dart';

class LessonWordPage extends StatefulWidget {
  final String subject;   // 'computer' หรือ 'electronics'
  final int lesson;       // เลขบท
  final int stage;        // เลขด่าน
  final String? fallbackHeroAsset;
  final String? wordDocId; // ถ้าส่งมาก็อ่านตรงจากคอลเล็กชันตาม subject

  const LessonWordPage({
    super.key,
    required this.subject,
    required this.lesson,
    required this.stage,
    this.fallbackHeroAsset,
    this.wordDocId,
  });

  @override
  State<LessonWordPage> createState() => _LessonWordPageState();
}

class _LessonWordPageState extends State<LessonWordPage> {
  final _scrollCtrl = ScrollController();
  double _readProgress = 0.0;
  bool _isStageCompleted = false;
  Map<String, dynamic>? _stageScore;
  bool _loadingScore = true;

  // ✅ แคชสตรีมไว้ครั้งเดียว แก้ปัญหากระพริบ/เลื่อนไม่ได้
  late final Stream<Map<String, dynamic>?> _contentStream;

  @override
  void initState() {
    super.initState();
    _contentStream = _createDocStream().asBroadcastStream();
    _scrollCtrl.addListener(_updateProgress);
    _checkStageStatus();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_updateProgress);
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// ตรวจสอบสถานะของด่าน
  Future<void> _checkStageStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final completed = await ProgressService.I.isStageCompleted(
          uid: user.uid,
          subject: widget.subject,
          lesson: widget.lesson,
          stage: widget.stage,
        );
        
        Map<String, dynamic>? score;
        if (completed) {
          score = await ProgressService.I.getStageScore(
            uid: user.uid,
            subject: widget.subject,
            lesson: widget.lesson,
            stage: widget.stage,
          );
        }
        
        if (mounted) {
          setState(() {
            _isStageCompleted = completed;
            _stageScore = score;
            _loadingScore = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingScore = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loadingScore = false;
        });
      }
    }
  }

  // throttle: เปลี่ยนเกิน 1% ค่อย setState
  void _updateProgress() {
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    final offset = _scrollCtrl.offset.clamp(0.0, max);
    final p = max == 0 ? 0.0 : (offset / max);
    if ((p - _readProgress).abs() > 0.01) {
      setState(() => _readProgress = p);
    }
  }

  /// สร้างปุ่มสำหรับด่านที่ทำสำเร็จแล้ว
  Widget _buildCompletedStageButton() {
    if (_loadingScore) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Row(
      children: [
        // ปุ่มกลับไปหน้าก่อน
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text(
              'กลับ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // แสดงคะแนน
        Expanded(
          flex: 2,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ด่านนี้ทำสำเร็จแล้ว!',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (_stageScore != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'คะแนน: ${_stageScore!['score'] ?? 0}/${_stageScore!['total'] ?? 0}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// สร้างปุ่มทำแบบทดสอบ
  Widget _buildQuizButton() {
    return Row(
      children: [
        // ปุ่มกลับไปหน้าก่อน
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text(
              'กลับ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ปุ่มไปหน้าคำถาม
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            onPressed: () {
              // ปุ่มไปหน้าคำถาม → ส่ง true ให้หน้าก่อนหน้าใช้ตัดสินใจ
              Navigator.pop(context, true);
            },
            child: const Text(
              'ไปหน้าคำถาม!!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  /* ============= Data layer ============= */

  // ค่ามาตรฐานของ subject เพื่อใช้ทำ alias/query
  String _subjectCanonical(String s) {
    final ss = s.toLowerCase().trim();
    if (ss.startsWith('comp')) return 'computer';
    if (ss.startsWith('elec')) return 'electronics';
    return ss;
  }

  // alias ของ subject (รองรับสะกดหลากหลาย)
  List<String> _subjectAliases(String canonical) {
    if (canonical == 'electronics') {
      return const ['electronics', 'electronic', 'elec'];
    }
    if (canonical == 'computer') {
      return const ['computer', 'computers', 'comp', 'com'];
    }
    return [canonical];
  }

  // map subject -> คอลเล็กชันเนื้อหา
  String _collectionForSubject(String s) {
    final c = _subjectCanonical(s);
    if (c == 'computer') return 'lesson_com';      // คอมพิวเตอร์
    if (c == 'electronics') return 'lesson_words'; // อิเล็กฯ
    return 'lesson_words';
  }

  // ลองเปิดเอกสารตามแพทเทิร์นชื่อ docId (เช่น electronic_1_2)
  Future<Map<String, dynamic>?> _tryGetByDocIdCandidates(String colName) async {
    final l = widget.lesson;
    final st = widget.stage;
    final canon = _subjectCanonical(widget.subject);

    final candidates = <String>[
      if (canon == 'electronics') ...[
        'electronic_${l}_${st}',
        'electronics_${l}_${st}',
        'elec_${l}_${st}',
      ] else if (canon == 'computer') ...[
        'computer_${l}_${st}',
        'computers_${l}_${st}',
        'comp_${l}_${st}',
        'com_${l}_${st}',
      ] else
        '${canon}_${l}_${st}',
    ];

    for (final id in candidates) {
      final doc = await FirebaseFirestore.instance.collection(colName).doc(id).get();
      if (doc.exists) return doc.data();
    }
    return null;
  }

  // คิวรีด้วย subject aliases และรองรับ stage/state
  Future<Map<String, dynamic>?> _queryByAliases(String colName) async {
    final aliases = _subjectAliases(_subjectCanonical(widget.subject));

    // ลองด้วย stage ก่อน
    var qs = await FirebaseFirestore.instance
        .collection(colName)
        .where('subject', whereIn: aliases)
        .where('lesson', isEqualTo: widget.lesson)
        .where('stage', isEqualTo: widget.stage)
        .limit(1)
        .get();
    if (qs.docs.isNotEmpty) return qs.docs.first.data();

    // ถ้าไม่เจอ ลอง state แทน
    qs = await FirebaseFirestore.instance
        .collection(colName)
        .where('subject', whereIn: aliases)
        .where('lesson', isEqualTo: widget.lesson)
        .where('state', isEqualTo: widget.stage)
        .limit(1)
        .get();
    if (qs.docs.isNotEmpty) return qs.docs.first.data();

    // กันเคสไม่มี subject ในเอกสาร (คิวรีเฉพาะบท/ด่าน)
    qs = await FirebaseFirestore.instance
        .collection(colName)
        .where('lesson', isEqualTo: widget.lesson)
        .where('stage', isEqualTo: widget.stage)
        .limit(1)
        .get();
    if (qs.docs.isNotEmpty) return qs.docs.first.data();

    qs = await FirebaseFirestore.instance
        .collection(colName)
        .where('lesson', isEqualTo: widget.lesson)
        .where('state', isEqualTo: widget.stage)
        .limit(1)
        .get();
    if (qs.docs.isNotEmpty) return qs.docs.first.data();

    return null;
  }

  // fallback รวม: คิวรีด้วย aliases -> ลอง docId แพทเทิร์น
  Future<Map<String, dynamic>?> _fallbackLookupContent() async {
    final colName = _collectionForSubject(widget.subject);
    final byAliases = await _queryByAliases(colName);
    if (byAliases != null) return byAliases;
    return await _tryGetByDocIdCandidates(colName);
  }

  // stream เอกสารเนื้อหา: resolve จาก subjects/... แล้วตาม wordDocId หรือ query
  Stream<Map<String, dynamic>?> _createDocStream() async* {
    // 0) ถ้ามี wordDocId → เปิด doc ตรงตามคอลเล็กชัน subject
    if (widget.wordDocId != null && widget.wordDocId!.isNotEmpty) {
      final col = FirebaseFirestore.instance.collection(_collectionForSubject(widget.subject));
      yield* col.doc(widget.wordDocId!).snapshots().map((d) => d.data());
      return;
    }

    // 1) ตรวจ meta ในเส้นทาง subject/lesson/stage (ใช้ widget.subject ตามเดิม)
    final subjDocRef = FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subject)
        .collection('lessons')
        .doc(widget.lesson.toString())
        .collection('stages')
        .doc(widget.stage.toString());

    await for (final metaSnap in subjDocRef.snapshots()) {
      final meta = metaSnap.data();

      // 1.1) ไม่มี meta → fallback (คิวรีด้วย aliases และลอง docId หลายรูปแบบ)
      if (meta == null) {
        yield await _fallbackLookupContent();
        continue;
      }

      // 1.2) meta มีเนื้อหาโดยตรง
      if (meta.containsKey('title') || meta.containsKey('content') || meta.containsKey('image')) {
        yield meta;
        continue;
      }

      // 1.3) meta เป็นตัวชี้ → ใช้ sourceCollection/docId หรือ query
      final colName =
          (meta['sourceCollection'] ?? meta['collection'] ?? meta['col']) as String? ??
              _collectionForSubject(widget.subject);
      final docId = (meta['wordDocId'] ?? meta['docId']) as String?;

      if (docId != null && docId.isNotEmpty) {
        final stream = FirebaseFirestore.instance
            .collection(colName)
            .doc(docId)
            .snapshots()
            .map((d) => d.data());
        await for (final d in stream) {
          yield d;
          break;
        }
      } else {
        // ไม่มี docId ให้คิวรีด้วย aliases ก่อน แล้วค่อยลอง docId แพทเทิร์น
        final data = await _queryByAliases(colName) ?? await _tryGetByDocIdCandidates(colName);
        yield data;
      }
    }
  }

  /* ============= UI ============= */

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ ให้กลับไปหน้าก่อนหน้าปกติ (แผนที่ด่าน) โดยไม่ไปทำแบบทดสอบ
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // กลับหน้าก่อนหน้าปกติ
          return false;                 // เราจัดการ pop เองแล้ว
        }
        return true; // ไม่มีหน้าก่อนหน้า ปล่อยระบบจัดการ
      },
      child: Scaffold(
        body: Stack(
          children: [
            // พื้นหลัง
            SizedBox.expand(
              child: Image.asset('assets/images/backgroundselect.jpg', fit: BoxFit.cover),
            ),

            SafeArea(
              child: Column(
                children: [
                  // แถบบน (ไม่มีปุ่มย้อนกลับอีกต่อไป)
                  _TopBar(
                    titleStream: _contentStream.map((d) => (d?['title'] as String?) ?? 'บทเรียน'),
                  ),

                  // แถบ progress อ่าน
                  SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: _readProgress,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      color: Colors.indigo,
                      minHeight: 4,
                    ),
                  ),

                  // เนื้อหา
                  Expanded(
                    child: StreamBuilder<Map<String, dynamic>?>(
                      stream: _contentStream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const _LoadingSkeleton();
                        }
                        final data = snap.data;
                        if (data == null) {
                          return const _EmptyState(
                            message: 'ไม่พบข้อมูลบทเรียนใน Firebase (ตรวจสอบ subjects/* หรือ collection ปลายทาง)',
                          );
                        }

                        final title = (data['title'] as String?) ?? 'บทเรียน';
                        final content = (data['content'] as String?) ?? '';
                        final imageUrl = data['image'] as String?;

                        return SingleChildScrollView(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                _HeroImage(url: imageUrl)
                              else if (widget.fallbackHeroAsset != null)
                                _HeroAsset(path: widget.fallbackHeroAsset!),

                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'บทเรียน',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 12),
                                    MarkdownBody(
                                      data: '# $title\n\n$content',
                                      selectable: false,
                                      styleSheet: _markdownStyle(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // CTA ลอยด้านล่าง
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 54,
                    child: _isStageCompleted
                        ? _buildCompletedStageButton()
                        : _buildQuizButton(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final base = Theme.of(context).textTheme;
    return MarkdownStyleSheet(
      p: base.bodyMedium!.copyWith(fontSize: 16, height: 1.6),
      h1: base.headlineSmall!.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
      h2: base.titleLarge!.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
      h3: base.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      strong: const TextStyle(fontWeight: FontWeight.w800),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet: base.bodyMedium!.copyWith(fontSize: 16),
      blockquote: base.bodyMedium!.copyWith(fontSize: 16, height: 1.6),
      blockquoteDecoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.06),
        border: const Border(left: BorderSide(color: Colors.indigoAccent, width: 4)),
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: Colors.grey.shade100,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 2, color: Colors.grey.shade300)),
      ),
    );
  }
}

/* ---------- Widgets ย่อย (เวอร์ชันไม่มีปุ่มย้อนกลับ) ---------- */

class _TopBar extends StatelessWidget {
  final Stream<String> titleStream;

  const _TopBar({
    required this.titleStream,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // ปุ่มกลับไปหน้าก่อน
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'กลับไปหน้าก่อน',
          ),
          Expanded(
            child: StreamBuilder<String>(
              stream: titleStream,
              builder: (context, s) {
                final title = (s.data ?? 'บทเรียน').trim();
                return Text(
                  title.isEmpty ? 'บทเรียน' : title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String url;
  const _HeroImage({required this.url});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(url, fit: BoxFit.cover)),
    );
  }
}

class _HeroAsset extends StatelessWidget {
  final String path;
  const _HeroAsset({required this.path});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(aspectRatio: 16 / 9, child: Image.asset(path, fit: BoxFit.cover)),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _skel(height: 180, radius: 16),
        const SizedBox(height: 16),
        _skel(height: 22, width: 220),
        const SizedBox(height: 12),
        _skel(height: 16),
        const SizedBox(height: 8),
        _skel(height: 16, width: 280),
        const SizedBox(height: 8),
        _skel(height: 16, width: 240),
      ],
    );
  }

  Widget _skel({double height = 14, double? width, double radius = 12}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius),
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
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }
}
