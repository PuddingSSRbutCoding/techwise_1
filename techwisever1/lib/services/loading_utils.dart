import 'package:flutter/material.dart';

class LoadingUtils {
  static bool _isDialogOpen = false;
  
  /// แสดง loading dialog ที่มีประสิทธิภาพ
  static void showLoadingDialog(BuildContext context) {
    if (_isDialogOpen) return; // ป้องกัน dialog ซ้อน
    
    _isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'กำลังดำเนินการ...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogOpen = false; // รีเซ็ตสถานะเมื่อปิด dialog
    });
  }

  /// ปิด loading dialog อย่างปลอดภัย
  static void hideLoadingDialog(BuildContext context) {
    if (!_isDialogOpen) return; // ถ้าไม่มี dialog เปิดอยู่ก็ไม่ต้องทำอะไร
    
    if (context.mounted && Navigator.canPop(context)) {
      try {
        Navigator.pop(context);
        _isDialogOpen = false;
      } catch (e) {
        debugPrint('Error hiding loading dialog: $e');
        _isDialogOpen = false; // รีเซ็ตสถานะแม้เกิด error
      }
    } else {
      _isDialogOpen = false; // รีเซ็ตสถานะถ้า context ไม่พร้อมใช้
    }
  }

  /// แสดง loading dialog พร้อมข้อความ
  static void showLoadingDialogWithText(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 