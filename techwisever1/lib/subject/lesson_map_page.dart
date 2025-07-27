import 'package:flutter/material.dart';

class LessonProgressPage extends StatelessWidget {
  const LessonProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลัง
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background_lesson.png', // เปลี่ยนตามชื่อไฟล์จริงของคุณ
              fit: BoxFit.cover,
            ),
          ),

          // หัวข้อบทเรียน
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'บทที่ 1 อิเล็กทรอนิกส์เบื้องต้น',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // ด่าน
          Positioned.fill(
            top: 120,
            bottom: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStageButton(context, 1, isUnlocked: true),
                  _buildConnector(),
                  _buildStageButton(context, 2, isUnlocked: false),
                  _buildConnector(),
                  _buildStageButton(context, 3, isUnlocked: false),
                  _buildConnector(),
                  _buildStageButton(context, 4, isUnlocked: false),
                  _buildConnector(),
                  _buildStageButton(context, 5, isUnlocked: false),
                ],
              ),
            ),
          ),

          // ตัวละครล่างซ้าย-ขวา
          Positioned(
            bottom: 0,
            left: 10,
            child: Image.asset(
              'assets/images/char_left.png',
              height: 120,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 10,
            child: Image.asset(
              'assets/images/char_right.png',
              height: 120,
            ),
          ),
        ],
      ),

      // BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
        onTap: (index) {
          // TODO: เพิ่มการนำทางตาม index
        },
      ),
    );
  }

  Widget _buildStageButton(BuildContext context, int stage,
      {required bool isUnlocked}) {
    final imagePath = isUnlocked
        ? 'assets/images/stage_$stage.png'
        : 'assets/images/stage_${stage}_gray.png';
    return GestureDetector(
      onTap: isUnlocked
          ? () {
              // TODO: นำทางไปยังหน้าด่านที่เลือก
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Image.asset(
          imagePath,
          height: 60,
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 4,
      height: 20,
      color: Colors.black,
    );
  }
}
