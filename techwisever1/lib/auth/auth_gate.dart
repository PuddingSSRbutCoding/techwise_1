import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techwisever1/main_screen.dart';
import 'package:techwisever1/login/welcome_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user != null) {
          // ล็อกอินแล้ว → ให้ MainScreen เป็นราก
          return const MainScreen(initialIndex: 0);
        }
        // ยังไม่ล็อกอิน
        return const WelcomePage();
      },
    );
  }
}
