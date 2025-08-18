# ระบบการ Refresh คะแนนอัตโนมัติ

## ภาพรวม

ระบบนี้ถูกออกแบบมาเพื่อให้หน้าต่างๆ ในแอปสามารถแสดงคะแนนที่อัปเดตแล้วแบบ real-time โดยไม่ต้องรีเฟรชหน้าด้วยตนเอง

## องค์ประกอบหลัก

### 1. ScoreStreamService (`lib/services/score_stream_service.dart`)

บริการหลักที่จัดการ stream คะแนนแบบ real-time:

- **`getLessonScoreStream()`** - Stream คะแนนของบทเรียนที่ระบุ
- **`getAllLessonScoresStream()`** - Stream คะแนนของทุกบทเรียนในวิชา
- **`getStageProgressStream()`** - Stream ความคืบหน้าของด่านที่ระบุ
- **`getSubjectCompletionStream()`** - Stream สถานะการเสร็จสมบูรณ์ของวิชา
- **`forceRefresh()`** - Force refresh ข้อมูลคะแนน

### 2. การใช้งานในหน้าต่างๆ

#### หน้าเลือกวิชา (SelectSubjectPage)
- ใช้ StreamBuilder แทน FutureBuilder
- รีเฟรชคะแนนอัตโนมัติเมื่อมีการเปลี่ยนแปลง

#### หน้าวิชาคอมพิวเตอร์ (ComputerTechPage)
- เพิ่มปุ่ม "รีเฟรชคะแนน" ใน AppBar
- ใช้ StreamBuilder สำหรับคะแนนบทเรียน
- รีเฟรชอัตโนมัติเมื่อมีการอัปเดตคะแนน

#### หน้าวิชาอิเล็กทรอนิกส์ (ElectronicsPage)
- เพิ่มปุ่ม "รีเฟรชคะแนน" ใน AppBar
- ใช้ StreamBuilder สำหรับคะแนนบทเรียน
- รีเฟรชอัตโนมัติเมื่อมีการอัปเดตคะแนน

#### หน้าบทเรียน (LessonWordPage)
- เพิ่ม StreamBuilder เพื่อติดตามความคืบหน้าของด่าน
- อัปเดตสถานะอัตโนมัติเมื่อมีการเปลี่ยนแปลง

#### หน้าแบบทดสอบ (QuestionPage)
- รีเฟรชคะแนนอัตโนมัติหลังจากบันทึกคะแนน
- ใช้ `_refreshScoresAfterSave()` เพื่อ force refresh

## วิธีการทำงาน

### 1. Real-time Updates
- ใช้ Firebase Firestore `snapshots()` เพื่อติดตามการเปลี่ยนแปลง
- ข้อมูลจะอัปเดตอัตโนมัติเมื่อมีการเปลี่ยนแปลงใน Firebase

### 2. Force Refresh
- เมื่อต้องการรีเฟรชทันที สามารถใช้ปุ่ม "รีเฟรชคะแนน"
- ระบบจะอ่านข้อมูลใหม่จาก Firebase และ trigger stream

### 3. Automatic Refresh
- หลังจากทำแบบทดสอบเสร็จ ระบบจะรีเฟรชคะแนนอัตโนมัติ
- หน้าต่างๆ จะแสดงคะแนนใหม่ทันที

## การใช้งาน

### สำหรับผู้ใช้ทั่วไป
1. **ปุ่มรีเฟรชคะแนน** - แตะเพื่อรีเฟรชคะแนนทันที
2. **การอัปเดตอัตโนมัติ** - คะแนนจะอัปเดตเองเมื่อมีการเปลี่ยนแปลง

### สำหรับนักพัฒนา
1. **เพิ่ม StreamBuilder** - แทนที่ FutureBuilder ด้วย StreamBuilder
2. **ใช้ ScoreStreamService** - เรียกใช้ service ที่เหมาะสม
3. **จัดการ State** - อัปเดต state เมื่อข้อมูลเปลี่ยน

## ตัวอย่างการใช้งาน

```dart
// ใช้ StreamBuilder แทน FutureBuilder
StreamBuilder<Map<int, Map<String, dynamic>>>(
  stream: ScoreStreamService.instance.getAllLessonScoresStream(
    uid: uid, 
    subject: 'computer'
  ),
  builder: (context, snapshot) {
    // UI จะอัปเดตอัตโนมัติเมื่อข้อมูลเปลี่ยน
    final lessonScores = snapshot.data ?? {};
    return _buildLessonCards(lessonScores);
  },
)

// Force refresh เมื่อต้องการ
await ScoreStreamService.instance.forceRefresh(
  uid: uid,
  subject: 'computer',
  lesson: 1,
);
```

## ประโยชน์

1. **Real-time Updates** - คะแนนอัปเดตทันทีเมื่อมีการเปลี่ยนแปลง
2. **User Experience** - ผู้ใช้ไม่ต้องรีเฟรชหน้าด้วยตนเอง
3. **Performance** - ใช้ stream แทนการโหลดข้อมูลซ้ำๆ
4. **Consistency** - ข้อมูลในทุกหน้าจะตรงกันเสมอ

## การแก้ไขปัญหา

### ปัญหาที่พบบ่อย
1. **Stream ไม่ทำงาน** - ตรวจสอบการเชื่อมต่อ Firebase
2. **ข้อมูลไม่อัปเดต** - ใช้ `forceRefresh()` เพื่อรีเฟรชทันที
3. **Performance** - ใช้ `StreamGroup.merge()` สำหรับหลาย streams

### การ Debug
- ตรวจสอบ console logs สำหรับ error messages
- ใช้ `kDebugMode` เพื่อแสดงข้อมูล debug
- ตรวจสอบ Firebase rules และการเชื่อมต่อ

## การพัฒนาต่อ

1. **เพิ่ม Caching** - เก็บข้อมูลใน local storage
2. **Optimization** - ลดการเรียก Firebase ที่ไม่จำเป็น
3. **Error Handling** - จัดการ error cases เพิ่มเติม
4. **Testing** - เพิ่ม unit tests และ integration tests
