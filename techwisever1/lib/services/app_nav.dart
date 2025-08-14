import 'package:flutter/foundation.dart';

/// ใช้สั่งสลับแท็บของ MainScreen จากหน้าลึก ๆ
/// ตัวอย่าง: AppNav.bottomIndex.value = 0; // ไปแท็บหน้าหลัก
class AppNav {
  static final ValueNotifier<int> bottomIndex = ValueNotifier<int>(0);
}
