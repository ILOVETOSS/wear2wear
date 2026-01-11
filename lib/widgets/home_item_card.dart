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
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: Image.network(item['image_url'], fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['brand'] ?? 'BRAND', style: TextStyle(color: const Color(0xFFE2FF00), fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text(item['title'] ?? '', style: TextStyle(color: Colors.white, fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4.h),
                  Text("${item['size']} · ${item['condition']}", style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}