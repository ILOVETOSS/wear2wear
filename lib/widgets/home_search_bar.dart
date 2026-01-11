import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // 어두운 배경색
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "원하는 옷을 검색해보세요",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFE2FF00)), // 형광 포인트 컬러
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }
}