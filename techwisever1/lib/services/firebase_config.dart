import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static bool _isInitialized = false;

  /// Initialize Firebase with proper configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure Auth persistence for web
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }

      _isInitialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  /// Get current Firebase App instance
  static FirebaseApp get app {
    if (!_isInitialized) {
      throw Exception('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return Firebase.app();
  }

  /// Check if Firebase is properly initialized
  static bool get isInitialized => _isInitialized;
}

