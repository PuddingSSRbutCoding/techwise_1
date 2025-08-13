// lib/subject/lesson_word.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  // ✅ แคชสตรีมไว้ครั้งเดียว แก้ปัญหากระพริบ/เลื่อนไม่ได้
  late final Stream<Map<String, dynamic>?> _contentStream;

  @override
  void initState() {
    super.initState();
    _contentStream = _createDocStream().asBroadcastStream();
    _scrollCtrl.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_updateProgress);
    _scrollCtrl.dispose();
    super.dispose();
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

  /* ============= Data layer ============= */

  String _collectionForSubject(String s) {
    final ss = s.toLowerCase().trim();
    if (ss.startsWith('comp')) return 'lesson_com';      // คอมพิวเตอร์
    if (ss.startsWith('elec')) return 'lesson_words';    // อิเล็กฯ
    return 'lesson_words';
  }

  // stream เอกสารเนื้อหา: resolve จาก subjects/... แล้วตาม wordDocId หรือ query
  Stream<Map<String, dynamic>?> _createDocStream() async* {
    // ถ้าได้ wordDocId มา → อ่านตรงจากคอลเล็กชันตาม subject
    if (widget.wordDocId != null && widget.wordDocId!.isNotEmpty) {
      final col = FirebaseFirestore.instance.collection(_collectionForSubject(widget.subject));
      yield* col.doc(widget.wordDocId!).snapshots().map((d) => d.data());
      return;
    }

    final subjDocRef = FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subject)
        .collection('lessons')
        .doc(widget.lesson.toString())
        .collection('stages')
        .doc(widget.stage.toString());

    await for (final metaSnap in subjDocRef.snapshots()) {
      final meta = metaSnap.data();

      // (1) ไม่มี meta → fallback คิวรีด้วย subject/lesson/stage
      if (meta == null) {
        final colName = _collectionForSubject(widget.subject);
        final qs = await FirebaseFirestore.instance
            .collection(colName)
            .where('subject', isEqualTo: widget.subject)
            .where('lesson',  isEqualTo: widget.lesson)
            .where('stage',   isEqualTo: widget.stage)
            .limit(1)
            .get();
        yield qs.docs.isNotEmpty ? qs.docs.first.data() : null;
        continue;
      }

      // (2) meta มีเนื้อหาโดยตรง
      if (meta.containsKey('title') || meta.containsKey('content') || meta.containsKey('image')) {
        yield meta;
        continue;
      }

      // (3) meta เป็นตัวชี้ → ใช้ sourceCollection/docId หรือ query
      final colName = (meta['sourceCollection'] ?? meta['collection'] ?? meta['col'])
              as String? ?? _collectionForSubject(widget.subject);
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
        final qs = await FirebaseFirestore.instance
            .collection(colName)
            .where('subject', isEqualTo: widget.subject)
            .where('lesson',  isEqualTo: widget.lesson)
            .where('stage',   isEqualTo: widget.stage)
            .limit(1)
            .get();
        yield qs.docs.isNotEmpty ? qs.docs.first.data() : null;
      }
    }
  }

  /* ============= UI ============= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
          SizedBox.expand(
            child: Image.asset('assets/images/backgroundselect.jpg', fit: BoxFit.cover),
          ),

          SafeArea(
            child: Column(
              children: [
                // แถบบน
                _TopBar(
                  titleStream: _contentStream.map((d) => (d?['title'] as String?) ?? 'บทเรียน'),
                  onBack: () => Navigator.pop(context, false),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'ฉันเรียนจบ/ผ่านบทนี้แล้ว',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
        border: Border(left: BorderSide(color: Colors.indigoAccent, width: 4)),
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

/* ---------- Widgets ย่อย ---------- */

class _TopBar extends StatelessWidget {
  final Stream<String> titleStream;
  final VoidCallback onBack;

  const _TopBar({
    required this.titleStream,
    required this.onBack,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 4),
          Expanded(
            child: StreamBuilder<String>(
              stream: titleStream,
              builder: (context, s) {
                final title = (s.data ?? 'บทเรียน').trim();
                return Text(
                  title.isEmpty ? 'บทเรียน' : title,
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
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ),
    );
  }
}
