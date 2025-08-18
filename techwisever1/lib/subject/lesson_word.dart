import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/services/progress_service.dart';
import 'package:techwisever1/services/score_stream_service.dart';

class LessonWordPage extends StatefulWidget {
  final String subject; // 'computer' หรือ 'electronics'
  final int lesson; // เลขบท
  final int stage; // เลขด่าน
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

  /// สร้าง StreamBuilder สำหรับความคืบหน้าของด่าน
  Widget _buildStageProgressStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: ScoreStreamService.instance.getStageProgressStream(
        uid: user.uid,
        subject: widget.subject,
        lesson: widget.lesson,
        stage: widget.stage,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final stageData = snapshot.data;
        if (stageData == null) {
          return const SizedBox.shrink();
        }

        final isCompleted = stageData['isCompleted'] as bool? ?? false;
        final lastUpdated = stageData['lastUpdated'] as String? ?? 'unknown';

        // อัปเดต state เมื่อข้อมูลเปลี่ยน
        if (mounted && (_isStageCompleted != isCompleted || _stageScore != stageData)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isStageCompleted = isCompleted;
              _stageScore = stageData;
              _loadingScore = false;
            });
          });
        }

        return const SizedBox.shrink(); // ไม่แสดง UI แต่ใช้เพื่ออัปเดต state
      },
    );
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
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Colors.indigo.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 18),
                SizedBox(width: 4),
                Text(
                  'กลับ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
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
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: Colors.indigo.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 18),
                SizedBox(width: 4),
                Text(
                  'กลับ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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

  // map subject -> คอลเล็กชันเนื้อหา
  String _collectionForSubject(String s) {
    final ss = s.toLowerCase().trim();
    if (ss.startsWith('comp')) return 'lesson_com'; // คอมพิวเตอร์
    if (ss.startsWith('elec')) return 'lesson_words'; // อิเล็กฯ
    return 'lesson_words';
  }

  /* ============= Data helpers ============= */

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getIfExists(
    String col,
    String id,
  ) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(col)
          .doc(id)
          .get();
      return snap.exists ? snap : null;
    } catch (e) {
      print('Error getting document $col/$id: $e');
      return null;
    }
  }

  /// 1) พยายามเปิด docId ตามแพทเทิร์น electronic_{lesson}_{stage} ก่อนเสมอ
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findByDocIdStrict(
    String col,
  ) async {
    final id = 'electronic_${widget.lesson}_${widget.stage}';
    print('Trying strict docId: $id in collection: $col');
    return _getIfExists(col, id);
  }

  /// 2) คิวรีแบบยืดหยุ่น: ให้ความสำคัญ state ก่อน stage และรองรับ subject หลายแบบ
  Future<DocumentSnapshot<Map<String, dynamic>>?> _queryFlexible(
    String col,
  ) async {
    try {
      print(
        'Searching flexibly in $col for lesson: ${widget.lesson}, stage: ${widget.stage}',
      );

      // ลองหาโดยไม่มี subject ก่อน - เพราะ Firebase อาจไม่มี subject field
      var qs = await FirebaseFirestore.instance
          .collection(col)
          .where('lesson', isEqualTo: widget.lesson)
          .where('state', isEqualTo: widget.stage)
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        print('Found by lesson+state (no subject): ${qs.docs.first.id}');
        return qs.docs.first;
      }

      // ลอง stage แทน state
      qs = await FirebaseFirestore.instance
          .collection(col)
          .where('lesson', isEqualTo: widget.lesson)
          .where('stage', isEqualTo: widget.stage)
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        print('Found by lesson+stage (no subject): ${qs.docs.first.id}');
        return qs.docs.first;
      }

      // ตอนนี้ลอง subject combinations
      final subjects = [
        'electronic',
        'electronics',
        'elec',
        'computer',
        'comp',
      ];

      for (final sub in subjects) {
        print('Trying subject: $sub');

        // state ก่อน
        qs = await FirebaseFirestore.instance
            .collection(col)
            .where('subject', isEqualTo: sub)
            .where('lesson', isEqualTo: widget.lesson)
            .where('state', isEqualTo: widget.stage)
            .limit(1)
            .get();

        if (qs.docs.isNotEmpty) {
          print('Found by subject+lesson+state: ${qs.docs.first.id}');
          return qs.docs.first;
        }

        // stage ถัดมา
        qs = await FirebaseFirestore.instance
            .collection(col)
            .where('subject', isEqualTo: sub)
            .where('lesson', isEqualTo: widget.lesson)
            .where('stage', isEqualTo: widget.stage)
            .limit(1)
            .get();

        if (qs.docs.isNotEmpty) {
          print('Found by subject+lesson+stage: ${qs.docs.first.id}');
          return qs.docs.first;
        }
      }

      // ลองดูทุก document ใน collection (debug mode)
      print('Trying to list all documents in $col for debugging...');
      qs = await FirebaseFirestore.instance.collection(col).limit(10).get();

      for (var doc in qs.docs) {
        final data = doc.data();
        print(
          'Found doc ${doc.id}: lesson=${data['lesson']}, state=${data['state']}, stage=${data['stage']}, subject=${data['subject']}',
        );

        // Manual check
        if (data['lesson'] == widget.lesson &&
            (data['state'] == widget.stage || data['stage'] == widget.stage)) {
          print('Manual match found: ${doc.id}');
          return doc;
        }
      }
    } catch (e) {
      print('Error in flexible query: $e');
    }

    return null;
  }

  /// 3) meta pointer / inline (subjects/{subject}/lessons/{L}/stages/{S})
  Stream<Map<String, dynamic>?> _streamFromMetaIfAny() async* {
    try {
      final subjDocRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subject)
          .collection('lessons')
          .doc(widget.lesson.toString())
          .collection('stages')
          .doc(widget.stage.toString());

      await for (final metaSnap in subjDocRef.snapshots()) {
        final meta = metaSnap.data();
        print('Meta data: $meta');

        if (meta == null) {
          yield null;
          continue;
        }

        // inline content
        if (meta.containsKey('title') ||
            meta.containsKey('content') ||
            meta.containsKey('image')) {
          print('Using inline meta content');
          yield meta;
          continue;
        }

        // pointer -> sourceCollection/docId
        final colName =
            (meta['sourceCollection'] ?? meta['collection'] ?? meta['col'])
                as String? ??
            _collectionForSubject(widget.subject);
        final docId = (meta['wordDocId'] ?? meta['docId']) as String?;

        if (docId != null && docId.isNotEmpty) {
          print('Using meta pointer to $colName/$docId');
          yield* FirebaseFirestore.instance
              .collection(colName)
              .doc(docId)
              .snapshots()
              .map((d) => d.data());
          return;
        } else {
          // fallback เก่า: subject ตรงตัว + state/stage
          print('Meta fallback search in $colName');

          var qs = await FirebaseFirestore.instance
              .collection(colName)
              .where('subject', isEqualTo: widget.subject)
              .where('lesson', isEqualTo: widget.lesson)
              .where('state', isEqualTo: widget.stage)
              .limit(1)
              .get();

          if (qs.docs.isEmpty) {
            qs = await FirebaseFirestore.instance
                .collection(colName)
                .where('subject', isEqualTo: widget.subject)
                .where('lesson', isEqualTo: widget.lesson)
                .where('stage', isEqualTo: widget.stage)
                .limit(1)
                .get();
          }

          yield qs.docs.isNotEmpty ? qs.docs.first.data() : null;
        }
      }
    } catch (e) {
      print('Error in meta stream: $e');
      yield null;
    }
  }

  // stream เอกสารเนื้อหา: resolve จาก subjects/... แล้วตาม wordDocId หรือ query
  Stream<Map<String, dynamic>?> _createDocStream() async* {
    final colName = _collectionForSubject(widget.subject);
    print(
      'Creating doc stream for subject: ${widget.subject}, lesson: ${widget.lesson}, stage: ${widget.stage}',
    );
    print('Using collection: $colName');

    // 0) ถ้ามี wordDocId มากับพารามิเตอร์ → ตรวจสอบก่อนว่ามีจริงไหม
    if ((widget.wordDocId ?? '').isNotEmpty) {
      print('Checking provided wordDocId: ${widget.wordDocId}');
      final docExists = await _getIfExists(colName, widget.wordDocId!);
      if (docExists != null) {
        print('WordDocId exists, using: ${widget.wordDocId}');
        yield* docExists.reference.snapshots().map((d) {
          print('WordDocId data: ${d.data()}');
          return d.data();
        });
        return;
      } else {
        print('WordDocId ${widget.wordDocId} not found, trying other methods');
      }
    }

    // 1) docId strict: electronic_{lesson}_{stage}
    final strict = await _findByDocIdStrict(colName);
    if (strict != null) {
      print('Using strict docId match: ${strict.id}');
      yield* strict.reference.snapshots().map((d) {
        print('Strict match data: ${d.data()}');
        return d.data();
      });
      return;
    }

    // 2) flexible query: ไม่ล็อก subject + รองรับ state/stage
    final flex = await _queryFlexible(colName);
    if (flex != null) {
      print('Using flexible query match: ${flex.id}');
      yield* flex.reference.snapshots().map((d) {
        print('Flexible match data: ${d.data()}');
        return d.data();
      });
      return;
    }

    // 3) meta path (inline/pointer)
    print('Trying meta path');
    yield* _streamFromMetaIfAny();
  }

  /* ============= UI ============= */

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✅ ให้กลับไปหน้าก่อนหน้าปกติ (แผนที่ด่าน) โดยไม่ไปทำแบบทดสอบ
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // กลับหน้าก่อนหน้าปกติ
          return false; // เราจัดการ pop เองแล้ว
        }
        return true; // ไม่มีหน้าก่อนหน้า ปล่อยระบบจัดการ
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ✅ พื้นหลังแบบเดิม - ใช้รูปภาพ
            SizedBox.expand(
              child: Image.asset(
                'assets/images/backgroundselect.jpg',
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ✅ แถบบนแบบใหม่ - ไม่มีปุ่มย้อนกลับ
                  _TopBar(
                    titleStream: _contentStream.map(
                      (d) => (d?['title'] as String?) ?? 'บทเรียน',
                    ),
                  ),

                  // ✅ แถบ progress อ่านแบบเดิม - ใช้สีฟ้า
                  SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: _readProgress,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
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
                            message:
                                'ไม่พบข้อมูลบทเรียนใน Firebase (ตรวจสอบ subjects/* หรือ collection ปลายทาง)',
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
                              // ✅ Hero Image แบบใหม่
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                _HeroImage(url: imageUrl)
                              else if (widget.fallbackHeroAsset != null)
                                _HeroAsset(path: widget.fallbackHeroAsset!),

                              // ✅ Lesson Card แบบใหม่
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ✅ Header แบบเดิม - ใช้สีฟ้า
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.school,
                                            color: Colors.indigo,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'บทเรียน',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // ✅ Title แบบใหม่
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // ✅ Content แบบใหม่
                                    MarkdownBody(
                                      data: content,
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

            // ✅ CTA ลอยด้านล่างแบบใหม่
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 60, // ✅ เพิ่มความสูง
                    child: _isStageCompleted
                        ? _buildCompletedStageButton()
                        : _buildQuizButton(),
                  ),
                ),
              ),
            ),

            // เพิ่ม StreamBuilder เพื่อ refresh อัตโนมัติ
            Positioned(
              top: 0,
              left: 0,
              child: _buildStageProgressStream(),
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
      h1: base.headlineSmall!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
      ),
      h2: base.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
      ),
      h3: base.titleMedium!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet: base.bodyMedium!.copyWith(fontSize: 16),
      blockquote: base.bodyMedium!.copyWith(fontSize: 16, height: 1.6),
      blockquoteDecoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.06), // ✅ เปลี่ยนกลับเป็นสีฟ้า
        border: const Border(
          left: BorderSide(
            color: Colors.indigo,
            width: 4,
          ), // ✅ เปลี่ยนกลับเป็นสีฟ้า
        ),
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: Colors.indigo.withOpacity(
          0.1,
        ), // ✅ เปลี่ยนกลับเป็นสีฟ้า
        color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 2,
            color: Colors.indigo.shade300,
          ), // ✅ เปลี่ยนกลับเป็นสีฟ้า
        ),
      ),
    );
  }
}

/* ---------- Widgets ย่อย (เวอร์ชันไม่มีปุ่มย้อนกลับ) ---------- */

class _TopBar extends StatelessWidget {
  final Stream<String> titleStream;

  const _TopBar({required this.titleStream});

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
            color: Colors.indigo.withOpacity(0.2), // ✅ เปลี่ยนกลับเป็นสีฟ้า
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ✅ ไม่มีปุ่มย้อนกลับแล้ว
          Expanded(
            child: StreamBuilder<String>(
              stream: titleStream,
              builder: (context, s) {
                final title = (s.data ?? 'บทเรียน').trim();
                return Text(
                  title.isEmpty ? 'บทเรียน' : title,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center, // ✅ จัดให้อยู่กลาง
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.indigo, // ✅ เปลี่ยนกลับเป็นสีฟ้า
                  ),
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
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(url, fit: BoxFit.cover),
      ),
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
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(path, fit: BoxFit.cover),
      ),
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
