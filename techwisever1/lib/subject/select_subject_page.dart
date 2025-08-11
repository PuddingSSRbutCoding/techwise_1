import 'package:flutter/material.dart';
import 'subject_card.dart';
import 'electronics_page.dart';
import 'computertech_page.dart';

class SelectSubjectPage extends StatefulWidget {
  const SelectSubjectPage({super.key});

  @override
  State<SelectSubjectPage> createState() => _SelectSubjectPageState();
}

class _SelectSubjectPageState extends State<SelectSubjectPage> {
  Widget? _currentSubPage;

  @override
  void didChangeDependencies() {
    Future.microtask(() {
      if (_currentSubPage != null) {
        setState(() {
          _currentSubPage = null;
        });
      }
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _currentSubPage ?? _buildSubjectMenu();
  }

  Widget _buildSubjectMenu() {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/backgroundselect.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(153),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ฉันอยากจะเรียน',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SubjectCard(
                        title: 'อิเล็กทรอนิกส์',
                        imagePath: 'assets/images/energy.png',
                        onTap: () {
                          setState(() {
                            _currentSubPage = ElectronicsPage(
                              onBack: () => setState(() => _currentSubPage = null),
                            );
                          });
                        },
                      ),
                      SubjectCard(
                        title: 'เทคนิคคอมพิวเตอร์',
                        imagePath: 'assets/images/hacker.png',
                        onTap: () {
                          setState(() {
                            _currentSubPage = ComputerTechPage(
                              onBack: () => setState(() => _currentSubPage = null),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
