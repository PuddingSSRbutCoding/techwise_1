// lib/question/question_model.dart
class Question {
  final String text;
  final List<String> options;
  final int answerIndex;

  Question({required this.text, required this.options, required this.answerIndex});

  factory Question.fromMap(Map<String, dynamic> m) {
    final rawOptions = (m['option'] ?? m['options'] ?? const <dynamic>[]) as List<dynamic>;
    return Question(
      text: (m['question'] ?? m['text'] ?? '').toString(),
      options: rawOptions.map((e) => e.toString()).toList(),
      answerIndex: (m['answerIndex'] is int)
          ? m['answerIndex'] as int
          : int.tryParse('${m['answerIndex']}') ?? 0,
    );
  }
}
