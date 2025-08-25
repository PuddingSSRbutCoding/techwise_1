import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../question/question_model.dart';
import 'package:flutter/material.dart'; // Added for Color

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

  /// สร้างวิชาใหม่
  static Future<void> createSubject({
    required String subjectId,
    required String title,
    String? description,
    String? image,
    Color? color,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final subjectRef = _db.collection('subjects').doc(subjectId);
      
      final subjectData = {
        'title': title,
        'description': description ?? 'บทเรียน$title',
        'image': image ?? 'assets/images/TC1.png',
        'color': color?.value ?? 0xFF2196F3, // สีฟ้าเริ่มต้น
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'lessonCount': 0,
        'questionCount': 0,
      };

      await setDocumentWithTimeout(
        documentRef: subjectRef,
        data: subjectData,
        timeout: timeout,
      );

      // สร้างบทเรียนเริ่มต้น
      await _createDefaultLessons(subjectId, timeout);
      
    } catch (e) {
      throw Exception('ไม่สามารถสร้างวิชาได้: $e');
    }
  }

  /// สร้างบทเรียนเริ่มต้นสำหรับวิชาใหม่
  static Future<void> _createDefaultLessons(String subjectId, Duration timeout) async {
    try {
      final lessonsRef = _db.collection('subjects/$subjectId/lessons');
      
      final defaultLessons = [
        {
          'id': 'L1',
          'title': 'บทที่ 1',
          'intro': 'เริ่มต้นเรียนรู้พื้นฐาน',
          'image': 'assets/images/TC1.png',
          'order': 1,
          'requiredStages': 4,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
        {
          'id': 'L2',
          'title': 'บทที่ 2',
          'intro': 'เรียนรู้เพิ่มเติม',
          'image': 'assets/images/TC2.jpg',
          'order': 2,
          'requiredStages': 5,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
        {
          'id': 'L3',
          'title': 'บทที่ 3',
          'intro': 'สรุปและประยุกต์',
          'image': 'assets/images/TC3.png',
          'order': 3,
          'requiredStages': 4,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        },
      ];

      final batch = _db.batch();
      for (final lesson in defaultLessons) {
        final lessonRef = lessonsRef.doc(lesson['id'] as String);
        batch.set(lessonRef, lesson);
      }
      
      await executeWithTimeout(
        operation: () => batch.commit(),
        timeout: timeout,
      );

      // อัปเดตจำนวนบทเรียนในวิชา
      await _updateLessonCount(subjectId, timeout);
      
    } catch (e) {
      debugPrint('⚠️ ไม่สามารถสร้างบทเรียนเริ่มต้นได้: $e');
      // ไม่ throw error เพื่อไม่ให้กระทบการสร้างวิชาหลัก
    }
  }

  /// อัปเดตจำนวนบทเรียนในวิชา
  static Future<void> _updateLessonCount(String subjectId, Duration timeout) async {
    try {
      final subjectRef = _db.collection('subjects').doc(subjectId);
      
      final lessonsSnapshot = await queryWithTimeout(
        query: _db.collection('subjects/$subjectId/lessons').where('isActive', isEqualTo: true),
        timeout: timeout,
      );

      final lessonCount = lessonsSnapshot.docs.length;

      await updateDocumentWithTimeout(
        documentRef: subjectRef,
        data: {
          'lessonCount': lessonCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        timeout: timeout,
      );
    } catch (e) {
      debugPrint('⚠️ ไม่สามารถอัปเดตจำนวนบทเรียนได้: $e');
    }
  }

  /// บันทึกคำถามใหม่ลงใน Firestore
  static Future<void> saveQuestion({
    required String subject,
    required String lesson,
    required Question question,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // ตรวจสอบว่าวิชามีอยู่หรือไม่ ถ้าไม่มีให้สร้างใหม่
      final subjectRef = _db.collection('subjects').doc(subject);
      final subjectDoc = await getDocumentWithTimeout(
        documentRef: subjectRef,
        timeout: timeout,
      );

      if (!subjectDoc.exists) {
        // สร้างวิชาใหม่
        await createSubject(
          subjectId: subject,
          title: _getDefaultSubjectTitle(subject),
          timeout: timeout,
        );
      }

      // ตรวจสอบว่าบทเรียนมีอยู่หรือไม่ ถ้าไม่มีให้สร้างใหม่
      final lessonRef = _db.collection('subjects/$subject/lessons').doc(lesson);
      final lessonDoc = await getDocumentWithTimeout(
        documentRef: lessonRef,
        timeout: timeout,
      );

      if (!lessonDoc.exists) {
        // สร้างบทเรียนใหม่
        final lessonNumber = int.tryParse(lesson.substring(1)) ?? 1;
        await setDocumentWithTimeout(
          documentRef: lessonRef,
          data: {
            'id': lesson,
            'title': 'บทที่ $lessonNumber',
            'intro': 'เนื้อหาบทเรียนที่ $lessonNumber',
            'image': 'assets/images/TC$lessonNumber.png',
            'order': lessonNumber,
            'requiredStages': _getRequiredStages(lessonNumber),
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          },
          timeout: timeout,
        );
      }

      // สร้าง collection path สำหรับคำถาม
      final collectionPath = 'subjects/$subject/lessons/$lesson/questions';
      
      // แปลง Question object เป็น Map
      final questionData = {
        'id': question.id,
        'text': question.text,
        'options': question.options,
        'answerIndex': question.answerIndex,
        'imageUrl': question.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin', // หรือใช้ UID ของแอดมิน
        'isActive': true,
      };

      // บันทึกลง Firestore
      final docRef = _db.collection(collectionPath).doc(question.id);
      await setDocumentWithTimeout(
        documentRef: docRef,
        data: questionData,
        timeout: timeout,
      );

      // อัปเดตจำนวนคำถามในบทเรียน
      await _updateQuestionCount(subject, lesson, timeout);
      
    } catch (e) {
      throw Exception('ไม่สามารถบันทึกคำถามได้: $e');
    }
  }

  /// อัปเดตจำนวนคำถามในบทเรียน
  static Future<void> _updateQuestionCount(String subject, String lesson, Duration timeout) async {
    try {
      final lessonRef = _db.collection('subjects/$subject/lessons').doc(lesson);
      
      // นับจำนวนคำถามในบทเรียน
      final questionsSnapshot = await queryWithTimeout(
        query: _db.collection('subjects/$subject/lessons/$lesson/questions')
            .where('isActive', isEqualTo: true),
        timeout: timeout,
      );

      final questionCount = questionsSnapshot.docs.length;

      // อัปเดตจำนวนคำถามในบทเรียน
      await updateDocumentWithTimeout(
        documentRef: lessonRef,
        data: {
          'questionCount': questionCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        timeout: timeout,
      );

      // อัปเดตจำนวนคำถามรวมในวิชา
      await _updateSubjectQuestionCount(subject, timeout);
      
    } catch (e) {
      // ไม่ throw error เพื่อไม่ให้กระทบการบันทึกคำถามหลัก
      debugPrint('⚠️ ไม่สามารถอัปเดตจำนวนคำถามได้: $e');
    }
  }

  /// อัปเดตจำนวนคำถามรวมในวิชา
  static Future<void> _updateSubjectQuestionCount(String subject, Duration timeout) async {
    try {
      final subjectRef = _db.collection('subjects').doc(subject);
      
      final lessonsSnapshot = await queryWithTimeout(
        query: _db.collection('subjects/$subject/lessons').where('isActive', isEqualTo: true),
        timeout: timeout,
      );

      int totalQuestions = 0;
      for (final lessonDoc in lessonsSnapshot.docs) {
        final lessonData = lessonDoc.data() as Map<String, dynamic>;
        totalQuestions += lessonData['questionCount'] as int? ?? 0;
      }

      await updateDocumentWithTimeout(
        documentRef: subjectRef,
        data: {
          'questionCount': totalQuestions,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        timeout: timeout,
      );
    } catch (e) {
      debugPrint('⚠️ ไม่สามารถอัปเดตจำนวนคำถามรวมได้: $e');
    }
  }

  /// ดึงชื่อวิชาเริ่มต้น
  static String _getDefaultSubjectTitle(String subjectId) {
    switch (subjectId) {
      case 'programming':
        return 'การเขียนโปรแกรม';
      case 'mathematics':
        return 'คณิตศาสตร์';
      case 'science':
        return 'วิทยาศาสตร์';
      case 'language':
        return 'ภาษาไทย';
      default:
        return subjectId.split('_').map((word) {
          if (word == 'programming') return 'การเขียนโปรแกรม';
          if (word == 'math') return 'คณิตศาสตร์';
          if (word == 'science') return 'วิทยาศาสตร์';
          if (word == 'thai') return 'ภาษาไทย';
          if (word == 'english') return 'ภาษาอังกฤษ';
          return word;
        }).join(' ');
    }
  }

  /// ดึงจำนวนด่านที่ต้องผ่านสำหรับบทเรียน
  static int _getRequiredStages(int lesson) {
    const Map<int, int> requiredStages = {1: 4, 2: 5, 3: 4};
    return requiredStages[lesson] ?? 4;
  }
}

