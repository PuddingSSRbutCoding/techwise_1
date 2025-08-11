import 'package:flutter/material.dart';
import 'login/welcome_page.dart';
import 'main_screen.dart'; // ✅ เพิ่ม
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      routes: {
        '/main': (context) => const MainScreen(), // ✅ เพิ่ม route นี้
      },
    );
  }
}
