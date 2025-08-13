import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs._();
  static final LocalPrefs I = LocalPrefs._();

  SharedPreferences? _sp;
  Future<void> _ensure() async => _sp ??= await SharedPreferences.getInstance();

  // 🔹 คีย์แบบรายวิชา/บท
  String _hideKey(String subject, int lesson) => 'hideLessonContent:$subject:$lesson';

  Future<bool> getHideLessonContentFor(String subject, int lesson) async {
    await _ensure();
    return _sp!.getBool(_hideKey(subject, lesson)) ?? false;
  }

  Future<void> setHideLessonContentFor(String subject, int lesson, bool value) async {
    await _ensure();
    await _sp!.setBool(_hideKey(subject, lesson), value);
  }

  // (คงเมธอดเดิมไว้ถ้ามีโค้ดที่เรียกใช้)
  Future<bool> getHideLessonContent() async => getHideLessonContentFor('global', 0);
  Future<void> setHideLessonContent(bool value) =>
      setHideLessonContentFor('global', 0, value);
}
