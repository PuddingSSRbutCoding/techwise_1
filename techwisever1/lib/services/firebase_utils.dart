import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class FirebaseUtils {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ดำเนินการ Firebase operation พร้อม timeout และ retry
  static Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 15),
    int maxRetries = 2,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        attempts++;
        
        if (attempts > maxRetries) {
          throw Exception('การดำเนินการล้มเหลวหลังจากลอง $maxRetries ครั้ง: $e');
        }
        
        // รอสักครู่ก่อนลองใหม่
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('การดำเนินการล้มเหลว');
  }

  /// ลบเอกสารหลายชิ้นพร้อม batch operation
  static Future<void> deleteMultipleDocuments({
    required List<DocumentReference> documentRefs,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (documentRefs.isEmpty) return;
    
    // แบ่งเป็น batch ขนาด 500 (Firestore limit)
    const batchSize = 500;
    
    for (int i = 0; i < documentRefs.length; i += batchSize) {
      final end = (i + batchSize < documentRefs.length) ? i + batchSize : documentRefs.length;
      final batch = _db.batch();
      
      for (int j = i; j < end; j++) {
        batch.delete(documentRefs[j]);
      }
      
      await executeWithTimeout(
        operation: () => batch.commit(),
        timeout: timeout,
      );
    }
  }

  /// คิวรีเอกสารพร้อม timeout
  static Future<QuerySnapshot> queryWithTimeout({
    required Query query,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return await executeWithTimeout(
      operation: () => query.get(),
      timeout: timeout,
    );
  }

  /// อ่านเอกสารเดียวพร้อม timeout
  static Future<DocumentSnapshot> getDocumentWithTimeout({
    required DocumentReference documentRef,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return await executeWithTimeout(
      operation: () => documentRef.get(),
      timeout: timeout,
    );
  }

  /// บันทึกข้อมูลพร้อม timeout
  static Future<void> setDocumentWithTimeout({
    required DocumentReference documentRef,
    required Map<String, dynamic> data,
    SetOptions? options,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await executeWithTimeout(
      operation: () => documentRef.set(data, options),
      timeout: timeout,
    );
  }

  /// อัปเดตข้อมูลพร้อม timeout
  static Future<void> updateDocumentWithTimeout({
    required DocumentReference documentRef,
    required Map<String, dynamic> data,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await executeWithTimeout(
      operation: () => documentRef.update(data),
      timeout: timeout,
    );
  }

  /// ลบเอกสารพร้อม timeout
  static Future<void> deleteDocumentWithTimeout({
    required DocumentReference documentRef,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await executeWithTimeout(
      operation: () => documentRef.delete(),
      timeout: timeout,
    );
  }
}
