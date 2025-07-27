import 'package:flutter/material.dart';

class LessonIntroPage extends StatelessWidget {
  const LessonIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔷 พื้นหลัง
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgroundselect.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔷 เนื้อหา
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // 🔷 ภาพตัวละคร
                  Center(
                    child: Image.asset(
                      'assets/images/TC student.png',
                      height: 250,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔷 กล่องข้อความ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'สวัสดีครับ น้องๆทุกคน\nวันนี้พี่จะพามารู้จักกับ\nอุปกรณ์พื้นฐานในวงจรอิเล็กทรอนิกส์เบื้องต้น',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'เมื่ออ่านเนื้อหาเสร็จแล้ว จะมีแบบทดสอบความรู้\nน้องๆสามารถตอบผิดได้ 3 ครั้ง จากทั้งหมด 5 ข้อ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔷 ปุ่มต่อไป
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigator.push(...)
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'ต่อไป',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
