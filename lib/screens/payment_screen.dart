import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';

class PaymentScreen extends StatefulWidget {
  final String swapId;
  final int totalAmount;

  const PaymentScreen({
    super.key,
    required this.swapId,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'card': {
      'icon': Icons.credit_card,
      'title': '신용/체크카드',
      'subtitle': '모든 카드 사용 가능',
    },
    'kakao': {
      'icon': Icons.chat_bubble,
      'title': '카카오페이',
      'subtitle': '간편 결제',
    },
    'naver': {
      'icon': Icons.payment,
      'title': '네이버페이',
      'subtitle': '포인트 사용 가능',
    },
    'toss': {
      'icon': Icons.account_balance_wallet,
      'title': '토스',
      'subtitle': '송금 수수료 무료',
    },
  };

  // ✅ 결제 처리 로직 개선
  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. 실제 결제 API 호출 대신 시뮬레이션 (2초)
      await Future.delayed(const Duration(seconds: 2));

      // 2. DB 업데이트: 'payment_completed' 상태로 변경
      // 중요: SQL에서 컬럼을 미리 추가해야 에러가 나지 않습니다.
      await supabase.from('swaps').update({
        'status': 'payment_completed', // 상태 변경
        'payment_method': _selectedPaymentMethod,
        'payment_amount': widget.totalAmount,
        'payment_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.swapId);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint("❌ 결제 처리 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("결제에 실패했습니다: ${e.toString().split('\n').first}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✅ 성공 다이얼로그 및 이동 로직 수정
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
              SizedBox(height: 24.h),
              Text("결제 완료", style: TextStyle(color: Colors.black, fontSize: 24.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 8.h),
              const Text("거래가 성공적으로 시작되었습니다.\n이제 상품을 발송해주세요!", textAlign: TextAlign.center),
              SizedBox(height: 24.h),
              // 정보 표시 박스
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12.r)),
                child: Column(
                  children: [
                    _buildPriceRow("결제 금액", "${_formatPrice(widget.totalAmount)}원"),
                    SizedBox(height: 8.h),
                    _buildPriceRow("결제 방법", _getPaymentMethodName()),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ 중요: 다이얼로그를 닫고, ActivityScreen(메인)으로 한 번에 돌아감
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text("확인", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 기존 UI 유지 부분 ---
  String _getPaymentMethodName() => _paymentMethods[_selectedPaymentMethod]?['title'] ?? '카드';

  String _formatPrice(int price) => price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.black54, fontSize: 13.sp)),
        Text(value, style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text("결제하기", style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("최종 결제 금액", style: TextStyle(color: Colors.black54, fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  Text("${_formatPrice(widget.totalAmount)}원", style: TextStyle(color: Colors.black, fontSize: 32.sp, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Text("결제 수단", style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 16.h),
            ..._paymentMethods.entries.map((entry) {
              final method = entry.key;
              final info = entry.value;
              final isSelected = _selectedPaymentMethod == method;
              return GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = method),
                child: Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: isSelected ? Colors.black : Colors.black12, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(info['icon'] as IconData, color: isSelected ? Colors.black : Colors.black54),
                      SizedBox(width: 16.w),
                      Expanded(child: Text(info['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.black : Colors.black12),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 32.h),
            // 하단 버튼
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("${_formatPrice(widget.totalAmount)}원 결제하기", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}