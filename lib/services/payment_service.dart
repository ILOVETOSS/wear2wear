import 'package:flutter/material.dart';
import '../main.dart';

class PaymentService {
  final _supabase = supabase;

  // 1. 결제 생성
  Future<String?> createPayment({
    required String paymentType, // 'instant_buy', 'swap_fee', 'swap_diff'
    required int amount,
    required int fee,
    required int totalAmount,
    String? swapId,
    String? clothesId,
    String paymentMethod = 'card',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final paymentData = await _supabase.from('payments').insert({
        'user_id': userId,
        'swap_id': swapId,
        'clothes_id': clothesId,
        'payment_type': paymentType,
        'amount': amount,
        'fee': fee,
        'total_amount': totalAmount,
        'status': 'pending',
        'payment_method': paymentMethod,
      }).select().single();

      debugPrint("✅ 결제 생성 성공: ${paymentData['id']}");
      return paymentData['id'];
    } catch (e) {
      debugPrint("❌ 결제 생성 실패: $e");
      return null;
    }
  }

  // 2. 결제 처리 (실제 결제 API 연동 부분)
  Future<bool> processPayment({
    required String paymentId,
    required String paymentMethod,
  }) async {
    try {
      // TODO: 실제 결제 게이트웨이 API 연동 (포트원, 토스페이먼츠 등)
      // 여기서는 시뮬레이션으로 처리

      await Future.delayed(const Duration(seconds: 2)); // 결제 처리 시뮬레이션

      // 결제 성공 시 상태 업데이트
      await _supabase.from('payments').update({
        'status': 'completed',
        'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      debugPrint("✅ 결제 처리 성공: $paymentId");
      return true;
    } catch (e) {
      debugPrint("❌ 결제 처리 실패: $e");

      // 결제 실패 시 상태 업데이트
      await _supabase.from('payments').update({
        'status': 'failed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      return false;
    }
  }

  // 3. 즉시구매 결제 (통합 프로세스)
  Future<Map<String, dynamic>?> processInstantBuyPayment({
    required String clothesId,
    required int amount,
    required int fee,
    required int totalAmount,
    required String swapId,
  }) async {
    try {
      // 1. 결제 생성
      final paymentId = await createPayment(
        paymentType: 'instant_buy',
        amount: amount,
        fee: fee,
        totalAmount: totalAmount,
        clothesId: clothesId,
        swapId: swapId,
      );

      if (paymentId == null) return null;

      // 2. 결제 처리
      final success = await processPayment(
        paymentId: paymentId,
        paymentMethod: 'card',
      );

      if (!success) return null;

      // 3. swap 상태를 accepted로 변경
      await _supabase.from('swaps').update({
        'status': 'accepted',
        'payment_id': paymentId,
      }).eq('id', swapId);

      return {
        'payment_id': paymentId,
        'swap_id': swapId,
        'success': true,
      };
    } catch (e) {
      debugPrint("❌ 즉시구매 결제 프로세스 실패: $e");
      return null;
    }
  }

  // 4. 교환 수수료 결제 (통합 프로세스)
  Future<Map<String, dynamic>?> processSwapFeePayment({
    required String swapId,
    required int fee,
    required String tradeMethod,
  }) async {
    try {
      // 1. 결제 생성
      final paymentId = await createPayment(
        paymentType: 'swap_fee',
        amount: 0,
        fee: fee,
        totalAmount: fee,
        swapId: swapId,
      );

      if (paymentId == null) return null;

      // 2. 결제 처리
      final success = await processPayment(
        paymentId: paymentId,
        paymentMethod: 'card',
      );

      if (!success) return null;

      // 3. swap 테이블 업데이트
      await _supabase.from('swaps').update({
        'payment_id': paymentId,
      }).eq('id', swapId);

      return {
        'payment_id': paymentId,
        'swap_id': swapId,
        'success': true,
      };
    } catch (e) {
      debugPrint("❌ 교환 수수료 결제 프로세스 실패: $e");
      return null;
    }
  }

  // 5. 차액 결제 (통합 프로세스)
  Future<Map<String, dynamic>?> processSwapDiffPayment({
    required String swapId,
    required int diffAmount,
    required int fee,
  }) async {
    try {
      final totalAmount = diffAmount + fee;

      // 1. 결제 생성
      final paymentId = await createPayment(
        paymentType: 'swap_diff',
        amount: diffAmount,
        fee: fee,
        totalAmount: totalAmount,
        swapId: swapId,
      );

      if (paymentId == null) return null;

      // 2. 결제 처리
      final success = await processPayment(
        paymentId: paymentId,
        paymentMethod: 'card',
      );

      if (!success) return null;

      // 3. swap 테이블 업데이트
      await _supabase.from('swaps').update({
        'payment_id': paymentId,
      }).eq('id', swapId);

      return {
        'payment_id': paymentId,
        'swap_id': swapId,
        'success': true,
      };
    } catch (e) {
      debugPrint("❌ 차액 결제 프로세스 실패: $e");
      return null;
    }
  }

  // 6. 결제 내역 조회
  Future<Map<String, dynamic>?> getPaymentDetail(String paymentId) async {
    try {
      final data = await _supabase
          .from('payments')
          .select()
          .eq('id', paymentId)
          .single();

      return data;
    } catch (e) {
      debugPrint("❌ 결제 내역 조회 실패: $e");
      return null;
    }
  }

  // 7. 내 결제 내역 목록
  Stream<List<Map<String, dynamic>>> getMyPayments() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // 8. 결제 취소/환불
  Future<bool> refundPayment(String paymentId) async {
    try {
      // TODO: 실제 결제 게이트웨이 환불 API 연동

      await _supabase.from('payments').update({
        'status': 'refunded',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      debugPrint("✅ 결제 환불 성공: $paymentId");
      return true;
    } catch (e) {
      debugPrint("❌ 결제 환불 실패: $e");
      return false;
    }
  }

  // 9. 결제 상태별 필터링
  Future<List<Map<String, dynamic>>> getPaymentsByStatus(String status) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _supabase
          .from('payments')
          .select()
          .eq('user_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("❌ 결제 내역 조회 실패: $e");
      return [];
    }
  }

  // 10. 결제 타입별 필터링
  Future<List<Map<String, dynamic>>> getPaymentsByType(String paymentType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final data = await _supabase
          .from('payments')
          .select()
          .eq('user_id', userId)
          .eq('payment_type', paymentType)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("❌ 결제 내역 조회 실패: $e");
      return [];
    }
  }

  // 11. 월별 결제 금액 집계
  Future<int> getMonthlyPaymentTotal(String month) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final data = await _supabase
          .from('payments')
          .select('total_amount')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .gte('created_at', '$month-01')
          .lt('created_at', _getNextMonth(month));

      int total = 0;
      for (var payment in data) {
        total += (payment['total_amount'] as int?) ?? 0;
      }

      return total;
    } catch (e) {
      debugPrint("❌ 월별 결제 금액 집계 실패: $e");
      return 0;
    }
  }

  // 12. 결제 수단별 통계
  Future<Map<String, int>> getPaymentMethodStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final data = await _supabase
          .from('payments')
          .select('payment_method')
          .eq('user_id', userId)
          .eq('status', 'completed');

      Map<String, int> stats = {};
      for (var payment in data) {
        final method = payment['payment_method'] ?? 'unknown';
        stats[method] = (stats[method] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint("❌ 결제 수단 통계 조회 실패: $e");
      return {};
    }
  }

  // 헬퍼: 다음 달 계산
  String _getNextMonth(String month) {
    final parts = month.split('-');
    int year = int.parse(parts[0]);
    int monthNum = int.parse(parts[1]);

    if (monthNum == 12) {
      year++;
      monthNum = 1;
    } else {
      monthNum++;
    }

    return '$year-${monthNum.toString().padLeft(2, '0')}';
  }

  // 13. 결제 타입 한글 변환
  String getPaymentTypeLabel(String paymentType) {
    switch (paymentType) {
      case 'instant_buy':
        return '즉시구매';
      case 'swap_fee':
        return '교환 수수료';
      case 'swap_diff':
        return '차액 결제';
      default:
        return '기타';
    }
  }

  // 14. 결제 상태 한글 변환
  String getPaymentStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'completed':
        return '완료';
      case 'failed':
        return '실패';
      case 'refunded':
        return '환불';
      default:
        return '알 수 없음';
    }
  }
}