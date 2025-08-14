// lib/question/question_model.dart
// คงเดิม: รองรับทั้ง 'options' และ 'option' + มี alias q.option
import 'package:flutter/foundation.dart';

class Question {
  final String id;
  final String text;
  final List<String> options; // normalized to exactly 4
  final int answerIndex;      // 0..3
  final String? imageUrl;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
    this.imageUrl,
  });

  List<String> get option => options;

  bool get isValid {
    final nonEmpty = options.where((e) => e.trim().isNotEmpty).length;
    return text.trim().isNotEmpty &&
        nonEmpty >= 2 &&
        answerIndex >= 0 &&
        answerIndex < options.length;
  }

  static int _letterToIndex(String s) {
    switch (s.trim().toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return int.tryParse(s) ?? 0;
    }
  }

  factory Question.fromMap(Map<String, dynamic> m, {String id = ''}) {
    String pickText() => (m['text'] ?? m['question'] ?? '').toString().trim();

    List<String> pickOptions() {
      final rawOptions = m['options'];
      if (rawOptions is List) {
        return rawOptions.map((e) => (e ?? '').toString()).toList();
      }
      final rawOption = m['option'];
      if (rawOption is List) {
        return rawOption.map((e) => (e ?? '').toString()).toList();
      }
      if (rawOption is Map) {
        final map = Map<String, dynamic>.from(rawOption);
        final keys = map.keys.toList()
          ..sort((a, b) {
            int toNum(String x) => int.tryParse(x) ?? 0;
            return toNum(a.toString()).compareTo(toNum(b.toString()));
          });
        return keys.map((k) => (map[k] ?? '').toString()).toList();
      }
      const abcd = ['A', 'B', 'C', 'D'];
      if (abcd.any((k) => m[k] != null)) {
        return abcd.map((k) => (m[k] ?? '').toString()).toList();
      }
      const opt = ['option1', 'option2', 'option3', 'option4'];
      if (opt.any((k) => m[k] != null)) {
        return opt.map((k) => (m[k] ?? '').toString()).toList();
      }
      final answers = m['answers'];
      if (answers is List) {
        return answers.map((e) => (e ?? '').toString()).toList();
      }
      final choices = m['choices'];
      if (choices is List) {
        return choices.map((e) => (e ?? '').toString()).toList();
      }
      return const <String>[];
    }

    int pickAnswerIndex(List<String> opts) {
      int clampIdx(int i) => i.clamp(0, opts.isNotEmpty ? opts.length - 1 : 0);
      final ai = m['answerIndex'];
      if (ai is int) return clampIdx(ai);
      if (ai is String) {
        final parsed = int.tryParse(ai);
        if (parsed != null) return clampIdx(parsed);
        return clampIdx(_letterToIndex(ai));
      }
      final alt = (m['answer'] ?? m['answerLetter'] ?? m['correct']);
      if (alt is int) return clampIdx(alt);
      if (alt is String) {
        final parsed = int.tryParse(alt);
        if (parsed != null) return clampIdx(parsed);
        return clampIdx(_letterToIndex(alt));
      }
      return 0;
    }

    String? pickImage() {
      final v = (m['imageUrl'] ?? m['image'] ?? m['img']);
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    final text = pickText();
    var opts = pickOptions().map((e) => e.trim()).toList();
    if (opts.length > 4) {
      opts = opts.take(4).toList();
    } else if (opts.length < 4) {
      opts = [...opts, ...List.filled(4 - opts.length, '')];
    }

    final idx = pickAnswerIndex(opts);
    final img = pickImage();

    final q = Question(
      id: id,
      text: text,
      options: opts,
      answerIndex: idx,
      imageUrl: img,
    );

    if (kDebugMode && !q.isValid) {
      debugPrint('[Question.fromMap] Invalid question data id=$id map=$m');
    }
    return q;
  }
}
