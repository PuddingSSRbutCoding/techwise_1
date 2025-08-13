/// Form validation utilities
class ValidationUtils {
  
  // Email validation regex pattern
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}$'
  );
  
  // Strong password regex pattern
  static final _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$'
  );
  
  // Medium password regex pattern
  static final _mediumPasswordRegex = RegExp(
    r'^(?=.*[a-zA-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$'
  );

  /// ตรวจสอบความถูกต้องของอีเมล
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 5) {
      return 'อีเมลต้องมีอย่างน้อย 5 ตัวอักษร';
    }
    
    if (trimmedValue.length > 254) {
      return 'อีเมลยาวเกินไป (สูงสุด 254 ตัวอักษร)';
    }
    
    if (!_emailRegex.hasMatch(trimmedValue)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง\nตัวอย่าง: example@domain.com';
    }
    
    // ตรวจสอบการใช้ตัวอักษรที่ไม่อนุญาต
    if (trimmedValue.contains('..') || 
        trimmedValue.startsWith('.') || 
        trimmedValue.endsWith('.')) {
      return 'อีเมลมีรูปแบบที่ไม่ถูกต้อง';
    }
    
    return null;
  }

  /// ตรวจสอบความแข็งแกร่งของรหัสผ่าน
  static String? validatePassword(String? value, {bool requireStrong = false}) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    
    if (value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    
    if (value.length > 128) {
      return 'รหัสผ่านยาวเกินไป (สูงสุด 128 ตัวอักษร)';
    }
    
    // ตรวจสอบว่ามีเฉพาะช่องว่าง
    if (value.trim().isEmpty) {
      return 'รหัสผ่านไม่สามารถมีเฉพาะช่องว่างได้';
    }
    
    // ตรวจสอบรหัสผ่านที่ง่ายเกินไป
    final commonPasswords = [
      '123456', 'password', '123456789', '12345678', '12345',
      '1234567', 'qwerty', 'abc123', 'Password', '1234567890'
    ];
    
    if (commonPasswords.contains(value.toLowerCase())) {
      return 'รหัสผ่านนี้ใช้งานทั่วไปเกินไป\nกรุณาเลือกรหัสผ่านที่ปลอดภัยกว่า';
    }
    
    if (requireStrong) {
      if (!_strongPasswordRegex.hasMatch(value)) {
        return 'รหัสผ่านต้องมี:\n• ตัวอักษรพิมพ์เล็ก (a-z)\n• ตัวอักษรพิมพ์ใหญ่ (A-Z)\n• ตัวเลข (0-9)\n• อักขระพิเศษ (@\$!%*?&)\n• อย่างน้อย 8 ตัวอักษร';
      }
    } else {
      if (!_mediumPasswordRegex.hasMatch(value)) {
        return 'รหัสผ่านต้องมีทั้งตัวอักษรและตัวเลข';
      }
    }
    
    return null;
  }

  /// ตรวจสอบการยืนยันรหัสผ่าน
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }
    
    if (value != originalPassword) {
      return 'รหัสผ่านไม่ตรงกัน\nกรุณาตรวจสอบและกรอกใหม่';
    }
    
    return null;
  }

  /// ตรวจสอบชื่อ-นามสกุล
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกชื่อ-นามสกุล';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'ชื่อ-นามสกุลต้องมีอย่างน้อย 2 ตัวอักษร';
    }
    
    if (trimmedValue.length > 100) {
      return 'ชื่อ-นามสกุลยาวเกินไป (สูงสุด 100 ตัวอักษร)';
    }
    
    // ตรวจสอบตัวอักษรที่อนุญาต (ไทย, อังกฤษ, ช่องว่าง, -, .)
    final nameRegex = RegExp(r'^[a-zA-Zก-๙\s\-\.]+$');
    if (!nameRegex.hasMatch(trimmedValue)) {
      return 'ชื่อ-นามสกุลสามารถมีได้เฉพาะตัวอักษร\nภาษาไทย อังกฤษ ช่องว่าง - และ .';
    }
    
    // ตรวจสอบว่าไม่เริ่มต้นหรือลงท้ายด้วยช่องว่าง
    if (value != trimmedValue) {
      return 'ชื่อ-นามสกุลไม่ควรมีช่องว่างต้นหรือท้าย';
    }
    
    return null;
  }

  /// ตรวจสอบสถานศึกษา
  static String? validateInstitution(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกสถานศึกษา';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'ชื่อสถานศึกษาต้องมีอย่างน้อย 2 ตัวอักษร';
    }
    
    if (trimmedValue.length > 200) {
      return 'ชื่อสถานศึกษายาวเกินไป (สูงสุด 200 ตัวอักษร)';
    }
    
    // ตรวจสอบตัวอักษรที่อนุญาต
    final institutionRegex = RegExp(r'^[a-zA-Zก-๙\s\-\.\(\)\d]+$');
    if (!institutionRegex.hasMatch(trimmedValue)) {
      return 'ชื่อสถานศึกษามีรูปแบบไม่ถูกต้อง';
    }
    
    return null;
  }

  /// ประเมินความแข็งแกร่งของรหัสผ่าน
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < 6) return PasswordStrength.weak;
    
    int score = 0;
    
    // ความยาว
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // มีตัวอักษรพิมพ์เล็ก
    if (password.contains(RegExp(r'[a-z]'))) score++;
    
    // มีตัวอักษรพิมพ์ใหญ่
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    
    // มีตัวเลข
    if (password.contains(RegExp(r'[0-9]'))) score++;
    
    // มีอักขระพิเศษ
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score < 2) return PasswordStrength.weak;
    if (score < 4) return PasswordStrength.medium;
    if (score < 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  /// รับข้อความอธิบายความแข็งแกร่งของรหัสผ่าน
  static String getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'รหัสผ่านอ่อน';
      case PasswordStrength.medium:
        return 'รหัสผ่านปานกลาง';
      case PasswordStrength.strong:
        return 'รหัสผ่านแข็งแกร่ง';
      case PasswordStrength.veryStrong:
        return 'รหัสผ่านแข็งแกร่งมาก';
    }
  }
}

/// ระดับความแข็งแกร่งของรหัสผ่าน
enum PasswordStrength {
  empty,
  weak,
  medium,
  strong,
  veryStrong
}
