import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';

class OfficeShippingScreen extends StatefulWidget {
  final String swapId;

  const OfficeShippingScreen({super.key, required this.swapId});

  @override
  State<OfficeShippingScreen> createState() => _OfficeShippingScreenState();
}

class _OfficeShippingScreenState extends State<OfficeShippingScreen> {
  bool _agreed = false;

  // 사무실 주소
  final String officeAddress = "서울시 강남구 테헤란로 123, SWAP-FIT 본사";
  final String officePhone = "02-1234-5678";

  Future<void> _confirmShipping() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("안내사항에 동의해주세요"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // DB 업데이트: 배송지를 사무실로 설정
      await supabase.from('swaps').update({
        'shipping_address': officeAddress,
        'shipping_type': 'office',
        'status': 'shipping',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.swapId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "배송 정보가 등록되었습니다. 상품을 발송해주세요!",
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
      debugPrint("❌ 배송지 등록 실패: $e");
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
          "안전거래 배송 안내",
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
            // 안내 아이콘
            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.green,
                  size: 40.sp,
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // 제목
            Text(
              "상품을 아래 주소로 발송해주세요",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 24.h),

            // 배송지 정보
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: Colors.black, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "SWAP-FIT 안전거래 센터",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoRow(Icons.location_on, officeAddress),
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.phone, officePhone),
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.person, "수령인: SWAP-FIT 검수팀"),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 안내사항
            Text(
              "안내사항",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 16.h),

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
                  _buildBulletPoint("상품을 위 주소로 택배 발송해주세요"),
                  _buildBulletPoint("도착 후 전문가 검수가 진행됩니다 (1-2일)"),
                  _buildBulletPoint("검수 완료 후 교환 상품이 배송됩니다"),
                  _buildBulletPoint("배송비는 선불로 발송해주세요"),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 동의 체크박스
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreed,
                    activeColor: Colors.black,
                    onChanged: (val) {
                      setState(() => _agreed = val!);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "위 안내사항을 확인했으며 동의합니다",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmShipping,
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
                  "발송 준비 완료",
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 18.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}