import 'package:flutter/material.dart';
import 'package:techwisever1/subject/select_subject_page.dart';
import 'package:techwisever1/profile/profile_page.dart';
import 'package:techwisever1/services/app_nav.dart';
import 'package:techwisever1/services/auth_state_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late final VoidCallback _navListener;

  final List<Widget> _screens = const [
    SelectSubjectPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);
    _navListener = () {
      if (!mounted) return;
      final v = AppNav.bottomIndex.value.clamp(0, _screens.length - 1);
      if (_selectedIndex != v) setState(() => _selectedIndex = v);
    };
    AppNav.bottomIndex.addListener(_navListener);
    
    // เริ่มโหลดข้อมูลผู้ใช้ในพื้นหลังหากยังไม่ได้โหลด
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthStateService.instance.userData.value == null && 
          !AuthStateService.instance.isLoadingUser.value) {
        AuthStateService.instance.refreshUserData();
      }
    });
  }

  @override
  void dispose() {
    AppNav.bottomIndex.removeListener(_navListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
