import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import 'payment_screen.dart';

class OfficeShippingScreen extends StatefulWidget {
  final String swapId;

  const OfficeShippingScreen({super.key, required this.swapId});

  @override
  State<OfficeShippingScreen> createState() => _OfficeShippingScreenState();
}

class _OfficeShippingScreenState extends State<OfficeShippingScreen> {
  bool _agreed = false;
  bool _isLoading = false;

  // 사무실 주소 정보 (상수로 관리하거나 DB에서 받아오는 것이 좋지만 일단 유지)
  final String officeAddress = "서울시 강남구 테헤란로 123, SWAP-FIT 본사";
  final String officePhone = "02-1234-5678";

  // 거래 수수료
  final int tradeFee = 8000;

  // ✅ 배송지 확정 및 DB 업데이트 로직
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

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. DB 업데이트: 배송 정보를 저장하고 상태를 변경
      // ⚠️ 필독: 에러가 발생한다면 Supabase SQL Editor에서 shipping_type, shipping_address 컬럼을 추가했는지 확인하세요.
      await supabase.from('swaps').update({
        'shipping_address': officeAddress,
        'shipping_type': 'office',
        'status': 'payment_pending', // 결제 대기 상태로 변경
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.swapId);

      if (mounted) {
        // 2. 업데이트 성공 시 결제 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              swapId: widget.swapId,
              totalAmount: tradeFee,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ 배송지 등록 실패: $e");
      if (mounted) {
        // 에러 메시지를 더 구체적으로 표시 (PGRST204 에러 대응)
        String errorMsg = e.toString();
        if (errorMsg.contains("PGRST204")) {
          errorMsg = "서버 설정(DB 컬럼)이 완료되지 않았습니다. 관리자에게 문의하세요.";
        } else {
          errorMsg = "오류가 발생했습니다: \n${errorMsg.split('\n').first}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

            Text(
              "상품을 아래 주소로 발송해주세요",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 24.h),

            // 배송지 정보 박스
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

            // 결제 금액 안내 박스
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "안전거래 수수료",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "${_formatPrice(tradeFee)}원",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.payment, color: Colors.blue, size: 32.sp),
                ],
              ),
            ),

            SizedBox(height: 32.h),

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

            // 동의 체크박스 영역 클릭 범위 확대
            InkWell(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
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
            ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmShipping,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  "다음 (결제하기)",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
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