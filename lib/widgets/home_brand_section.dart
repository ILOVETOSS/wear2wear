import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeBrandSection extends StatelessWidget {
  const HomeBrandSection({Key? key}) : super(key: key);

  // ✅ 임시 데이터 (파일명과 실제 파일이 일치해야 함)
  static const List<Map<String, String>> tempBrands = [
    {"name": "Nike", "image": "assets/images/nike.png"},
    {"name": "Adidas", "image": "assets/images/adidas.png"},
    {"name": "Stussy", "image": "assets/images/stussy.png"},
    {"name": "Zara", "image": "assets/images/zara.png"},
    {"name": "Chanel", "image": "assets/images/chanel.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95.h, // 크기 조정에 따른 높이 최적화
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tempBrands.length,
        itemBuilder: (context, index) {
          final brand = tempBrands[index];
          return Container(
            width: 65.w,
            margin: EdgeInsets.only(right: 12.w),
            child: Column(
              children: [
                Container(
                  width: 52.w, // 로고 크기 축소
                  height: 52.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[100]!, width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      brand['image']!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.style, color: Colors.grey[300], size: 20.sp),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  brand['name']!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}