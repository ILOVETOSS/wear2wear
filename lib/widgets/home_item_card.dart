import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const HomeItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ✅ 배경을 화이트로 변경하고, 아주 연한 테두리(border)를 추가해서 깔끔하게 만듦
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1), // 살짝 구분감 주기
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: Image.network(
                  item['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // 이미지 로딩 중일 때 표시할 배경
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 브랜드명: 형광 라임 -> 블랙
                  Text(
                      item['brand'] ?? 'BRAND',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900, // 더 굵게 강조
                          letterSpacing: 0.5
                      )
                  ),
                  SizedBox(height: 4.h),
                  // ✅ 상품명: 화이트 -> 블랙
                  Text(
                      item['title'] ?? '',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  SizedBox(height: 4.h),
                  // ✅ 사이즈/상태: 연한 화이트 -> 연한 블랙(회색)
                  Text(
                      "${item['size']} · ${item['condition']}",
                      style: TextStyle(
                          color: Colors.black38,
                          fontSize: 11.sp
                      )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}