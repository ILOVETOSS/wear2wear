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
        // 디자인 소스 특유의 어두운 카드 배경과 둥근 모서리
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16.r)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상품 이미지 (Supabase URL 연결)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: Image.network(
                  item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // 이미지 로딩 실패 시 처리
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              ),
            ),
            // 2. 상품 정보 텍스트 영역
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 브랜드명 (형광 노랑 포인트 컬러 적용)
                  Text(
                    item['brand'] ?? 'BRAND',
                    style: TextStyle(
                        color: const Color(0xFFE2FF00),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // 상품 제목
                  Text(
                      item['title'] ?? 'ITEM',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  SizedBox(height: 4.h),
                  // 사이즈 및 상태 정보
                  Text(
                      "${item['size'] ?? 'Free'} · ${item['condition'] ?? '중고'}",
                      style: TextStyle(
                          color: Colors.white38,
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