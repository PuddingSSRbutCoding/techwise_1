import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase
import 'login/welcome_page.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ สำคัญมากสำหรับ plugin
  await Firebase.initializeApp();            // ✅ สำคัญมากสำหรับทุก auth
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomePage(),

      // ✅ Route สำหรับ MainScreen
      routes: {
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
