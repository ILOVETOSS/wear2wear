import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeBrandSection extends StatelessWidget {
  const HomeBrandSection({super.key});

  // 확장자 .png 반영
  final List<Map<String, String>> brands = const [
    {'name': 'Nike', 'image': 'assets/images/nike.png'},
    {'name': 'Adidas', 'image': 'assets/images/adidas.png'},
    {'name': 'Gucci', 'image': 'assets/images/gucci.png'},
    {'name': 'Fila', 'image': 'assets/images/fila.png'},
    {'name': 'Puma', 'image': 'assets/images/puma.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
          child: Text(
            "인기 브랜드 스왑",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 105.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 20.w),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 18.w),
                child: Column(
                  children: [
                    Container(
                      width: 68.w,
                      height: 68.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(
                          color: const Color(0xFFE2FF00).withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(14.w),
                        child: Image.asset(
                          brands[index]['image']!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error_outline, color: Colors.white24),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      brands[index]['name']!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}