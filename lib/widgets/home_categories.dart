import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeCategories extends StatefulWidget {
  const HomeCategories({super.key});

  @override
  State<HomeCategories> createState() => _HomeCategoriesState();
}

class _HomeCategoriesState extends State<HomeCategories> {
  int _selectedIndex = 0;
  final List<String> _categories = ["🎯 추천", "🔥 인기", "🆕 방금 전"];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      // ✅ 전체 배경을 화이트로 유지하기 위해 별도 색상 지정 안 함 (부모가 white)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                // ✅ 선택 시 검정색, 미선택 시 아주 연한 회색
                color: isSelected ? Colors.black : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30.r),
                // ✅ 미선택 시 테두리를 살짝 주어 구분감 생성
                border: isSelected
                    ? null
                    : Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    // ✅ 선택 시 흰색 글자, 미선택 시 검정색 글자
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}