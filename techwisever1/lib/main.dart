import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/auth_gate.dart';
import 'main_screen.dart';
import 'login/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(const TechWiseApp());
}

class TechWiseApp extends StatelessWidget {
  const TechWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechWise',
      home: const AuthGate(),        // ✅ ใช้ AuthGate เป็นราก
      routes: {
        '/main': (_) => const MainScreen(),
        '/login': (_) => const WelcomePage(), // กันโค้ดเดิมที่อ้าง '/login'
      },
    );
  }
}
