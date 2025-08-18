import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _selectedIndex;
  late final VoidCallback _navListener;

  final List<Widget> _screens = const [SelectSubjectPage(), ProfilePage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);
    _navListener = () {
      if (!mounted) return;
      final v = AppNav.bottomIndex.value.clamp(0, _screens.length - 1);
      if (_selectedIndex != v) setState(() => _selectedIndex = v);
    };
    AppNav.bottomIndex.addListener(_navListener);

    // หยุด loading state ทันทีหลังจากเข้าหน้า main สำเร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // หยุด loading state ทันที
      AuthStateService.instance.stopLoadingAndClearData();
      
      // โหลดข้อมูลผู้ใช้ในพื้นหลังแบบไม่บล็อก UI (ถ้าจำเป็น)
      _loadUserDataInBackground();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppNav.bottomIndex.removeListener(_navListener);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // แอปกลับมาทำงาน - refresh ข้อมูล
        _refreshCurrentPage();
        break;
      case AppLifecycleState.paused:
        // แอปถูก pause - หยุดการ refresh
        break;
      case AppLifecycleState.inactive:
        // แอปไม่ active - หยุดการ refresh
        break;
      case AppLifecycleState.detached:
        // แอปถูกปิด - หยุดการ refresh
        break;
      default:
        break;
    }
  }
  
  /// Refresh หน้าปัจจุบัน
  void _refreshCurrentPage() {
    if (mounted) {
      setState(() {
        // Trigger rebuild เพื่อ refresh ข้อมูล
      });
    }
  }

  /// โหลดข้อมูลผู้ใช้ในพื้นหลังแบบไม่บล็อก UI
  void _loadUserDataInBackground() {
    // ตรวจสอบว่าผู้ใช้ยังคงล็อกอินอยู่หรือไม่
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // โหลดข้อมูลในพื้นหลังแบบไม่บล็อก UI
      Future.microtask(() async {
        try {
          // ใช้ timeout สั้นมากเพื่อไม่ให้บล็อก UI
          await AuthStateService.instance.refreshUserData().timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              debugPrint('⚠️ Background user data loading timeout - continuing anyway');
              return;
            },
          );
        } catch (e) {
          debugPrint('⚠️ Background user data loading failed: $e');
          // ไม่ throw error เพื่อไม่ให้บล็อก UI
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          AppNav.bottomIndex.value = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'บทเรียน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
