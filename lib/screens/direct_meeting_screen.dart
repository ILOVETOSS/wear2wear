import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';

class DirectMeetingScreen extends StatefulWidget {
  final String swapId;

  const DirectMeetingScreen({super.key, required this.swapId});

  @override
  State<DirectMeetingScreen> createState() => _DirectMeetingScreenState();
}

class _DirectMeetingScreenState extends State<DirectMeetingScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _confirmMeeting() async {
    if (_locationController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("모든 정보를 입력해주세요"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await supabase.from('swaps').update({
        'meeting_location': _locationController.text,
        'meeting_date': _dateController.text,
        'meeting_time': _timeController.text,
        'meeting_note': _noteController.text,
        'shipping_type': 'direct',
        'status': 'meeting_scheduled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.swapId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "만남 약속이 등록되었습니다!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ 약속 등록 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "직거래 약속",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.handshake,
                  color: Colors.orange,
                  size: 40.sp,
                ),
              ),
            ),

            SizedBox(height: 32.h),

            Text(
              "만남 약속을 정해주세요",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 24.h),

            // 장소
            _buildTextField(
              controller: _locationController,
              label: "만날 장소",
              hint: "예: 강남역 10번 출구",
              icon: Icons.location_on,
            ),

            SizedBox(height: 20.h),

            // 날짜
            _buildDateField(
              controller: _dateController,
              label: "날짜",
              hint: "날짜 선택",
              icon: Icons.calendar_today,
              onTap: _selectDate,
            ),

            SizedBox(height: 20.h),

            // 시간
            _buildDateField(
              controller: _timeController,
              label: "시간",
              hint: "시간 선택",
              icon: Icons.access_time,
              onTap: _selectTime,
            ),

            SizedBox(height: 20.h),

            // 메모
            _buildTextField(
              controller: _noteController,
              label: "메모 (선택)",
              hint: "예: 카페 앞에서 만나요",
              icon: Icons.note,
              maxLines: 3,
            ),

            SizedBox(height: 32.h),

            // 안전 안내
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                      SizedBox(width: 8.w),
                      Text(
                        "안전 거래 주의사항",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildBulletPoint("안전한 공공장소에서 만나세요"),
                  _buildBulletPoint("밤 시간대는 피해주세요"),
                  _buildBulletPoint("상품 상태를 꼼꼼히 확인하세요"),
                  _buildBulletPoint("개인정보 유출에 주의하세요"),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "약속 확정하기",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: Colors.black, fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.black54),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: TextStyle(color: Colors.black, fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.black54),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 13.sp,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}