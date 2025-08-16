import 'package:flutter/material.dart';
import 'dart:async';

class LoadingUtils {
  /// แสดง loading dialog พร้อม timeout และการจัดการ error
  static Future<T?> showLoadingWithTimeout<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    String loadingMessage = 'กำลังดำเนินการ...',
    String timeoutMessage = 'การดำเนินการใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง',
    String errorMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
  }) async {
    // แสดง loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(loadingMessage)),
          ],
        ),
      ),
    );

    try {
      // ทำการดำเนินการพร้อม timeout
      final result = await operation().timeout(timeout);
      
      // ปิด loading dialog อัตโนมัติ
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      return result;
      
    } on TimeoutException {
      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // แสดงข้อความ timeout
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(timeoutMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
      
    } catch (e) {
      // ปิด loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // แสดงข้อความ error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }

  /// แสดง loading indicator แบบง่าย
  static void showSimpleLoading(BuildContext context, {String message = 'กำลังโหลด...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// ปิด loading dialog
  static void hideLoading(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// แสดงข้อความสำเร็จ
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// แสดงข้อความผิดพลาด
  static void showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
} 