import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MatchSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> myItem;
  final Map<String, dynamic> targetItem;
  final String swapId;

  const MatchSuccessScreen({
    super.key,
    required this.myItem,
    required this.targetItem,
    required this.swapId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              const Spacer(),

              // ✅ CONGRATS 배지
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 6.w),
                    Text(
                      "CONGRATS!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ✅ MATCH 타이틀
              Text(
                "MATCH",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: 40.h),

              // ✅ 상품 카드들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 내 아이템
                  _buildItemCard(
                    myItem['image_url'],
                    "Your Item",
                    Colors.blue,
                  ),

                  SizedBox(width: 20.w),

                  // 하트 아이콘
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),

                  SizedBox(width: 20.w),

                  // 상대 아이템
                  _buildItemCard(
                    targetItem['image_url'],
                    "Their Item",
                    Colors.orange,
                  ),
                ],
              ),

              SizedBox(height: 40.h),

              // ✅ 상품명 표시
              Column(
                children: [
                  Text(
                    "YOUR",
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    myItem['title'] ?? 'Item',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "FOR",
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    targetItem['title'] ?? 'Item',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              SizedBox(height: 40.h),

              // ✅ 조건 표시
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildInfoRow("Condition", "Excellent"),
                    SizedBox(height: 12.h),
                    _buildInfoRow("Location", "Seoul, KR"),
                    SizedBox(height: 12.h),
                    _buildInfoRow("Shipping", "Free"),
                  ],
                ),
              ),

              const Spacer(),

              // ✅ 버튼들
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // ✅ 수정 포인트: true를 전달하며 pop 합니다.
                        // 이렇게 하면 ActivityScreen에서 이를 감지하여 "진행 현황" 탭으로 즉시 넘겨줍니다.
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Start Trade",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(String? imageUrl, String label, Color borderColor) {
    return Column(
      children: [
        Container(
          width: 120.w,
          height: 150.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: imageUrl != null
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                color: Colors.black12,
              ),
            )
                : const Icon(
              Icons.checkroom,
              color: Colors.black12,
              size: 40,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black45,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}