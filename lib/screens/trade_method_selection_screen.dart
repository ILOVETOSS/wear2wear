import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart'; // ✅ supabase 객체 접근을 위해 필수

class TradeMethodSelectionScreen extends StatelessWidget {
  final String swapId;
  final Map<String, dynamic> myItem;
  final Map<String, dynamic> targetItem;

  const TradeMethodSelectionScreen({
    super.key,
    required this.swapId,
    required this.myItem,
    required this.targetItem,
  });

  // ✅ DB 업데이트 함수: 거래 방식 저장 및 상태 변경
  Future<void> _updateSwapTradeMethod(String swapId, String method) async {
    try {
      await supabase
          .from('swaps')
          .update({
        'trade_method': method,
        'status': 'trade_selected', // ✅ 상태를 변경해야 ActivityScreen에서 배송지 입력 버튼이 노출됨
      })
          .eq('id', swapId);
    } catch (e) {
      debugPrint("❌ 거래 방식 업데이트 에러: $e");
      rethrow;
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
          "거래 방식 선택",
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
            Text(
              "안전하고 편리한 거래 방식을\n선택해주세요",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            SizedBox(height: 32.h),

            // 1. 안전거래
            _buildTradeMethodCard(
              context: context,
              icon: Icons.lock,
              iconColor: Colors.green,
              title: "안전거래",
              badge: "추천",
              badgeColor: Colors.green,
              description: "플랫폼이 상품을 보관하고\n검수 후 교환합니다",
              fee: "8,000원",
              duration: "3-5일",
              benefits: ["✓ 플랫폼 검수 포함", "✓ 상품 보호 보험", "✓ 분쟁 해결 지원"],
              onTap: () => _handleTradeMethodSelection(context, 'safe_trade', 8000),
            ),

            SizedBox(height: 16.h),

            // 2. 고가상품 거래
            _buildTradeMethodCard(
              context: context,
              icon: Icons.diamond,
              iconColor: Colors.purple,
              title: "고가상품 거래",
              badge: "20만원 이상 권장",
              badgeColor: Colors.purple,
              description: "정품 인증 + 안전거래\n전문가 검수 포함",
              fee: "15,000원",
              duration: "5-7일",
              benefits: ["✓ 정품 인증서 발급", "✓ 전문가 검수", "✓ 프리미엄 보험"],
              onTap: () => _handleTradeMethodSelection(context, 'premium_trade', 15000),
            ),

            SizedBox(height: 16.h),

            // 3. 일반 거래 (직거래)
            _buildTradeMethodCard(
              context: context,
              icon: Icons.bolt,
              iconColor: Colors.orange,
              title: "일반 거래",
              badge: "수수료 무료",
              badgeColor: Colors.orange,
              description: "직접 만나서 교환\n빠르고 간편합니다",
              fee: "무료",
              duration: "당일 가능",
              benefits: ["✓ 수수료 없음", "✓ 즉시 거래 가능", "✓ 직접 확인 가능"],
              onTap: () => _handleTradeMethodSelection(context, 'direct_trade', 0),
            ),

            SizedBox(height: 32.h),

            // 주의사항 배너
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "일반 거래는 플랫폼 보호를 받지 못합니다.\n직거래 시 안전한 장소에서 만나세요.",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 거래 방식 카드 위젯
  Widget _buildTradeMethodCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required String fee,
    required String duration,
    required List<String> benefits,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.black12, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 16.sp),
              ],
            ),
            SizedBox(height: 16.h),
            Text(description, style: TextStyle(color: Colors.black54, fontSize: 13.sp, height: 1.4)),
            SizedBox(height: 16.h),
            Row(
              children: [
                _buildInfoChip("수수료: $fee"),
                SizedBox(width: 8.w),
                _buildInfoChip("기간: $duration"),
              ],
            ),
            SizedBox(height: 16.h),
            ...benefits.map((benefit) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(benefit, style: TextStyle(color: Colors.black87, fontSize: 12.sp)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ✅ 방식 선택 시 팝업 및 DB 처리 로직
  void _handleTradeMethodSelection(BuildContext context, String method, int fee) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          _getMethodTitle(method),
          style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("이 방식으로 거래를 진행하시겠습니까?", style: TextStyle(color: Colors.black87, fontSize: 14.sp)),
            if (fee > 0) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("거래 수수료", style: TextStyle(color: Colors.black54, fontSize: 13.sp)),
                    Text("${_formatPrice(fee)}원",
                        style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("취소", style: TextStyle(color: Colors.black38, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // ✅ 1. DB 업데이트 (trade_method 저장 및 status 변경)
                await _updateSwapTradeMethod(swapId, method);

                if (context.mounted) {
                  Navigator.pop(dialogContext); // 다이얼로그 닫기
                  Navigator.pop(context); // 현재 화면(거래 선택창) 닫기 -> ActivityScreen으로 돌아감

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("거래 방식이 선택되었습니다."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("업데이트 실패. 다시 시도해주세요."), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("선택", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getMethodTitle(String method) {
    switch (method) {
      case 'safe_trade': return '안전거래';
      case 'premium_trade': return '고가상품 거래';
      case 'direct_trade': return '일반 거래';
      default: return '';
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}