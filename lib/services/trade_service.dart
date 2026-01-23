import 'package:flutter/material.dart';
import '../main.dart';

class TradeService {
  final _supabase = supabase;

  // 수수료율 상수
  static const double INSTANT_BUY_FEE_RATE = 0.12; // 즉시구매 12%
  static const int PURE_SWAP_FEE = 8000; // 순수교환 8,000원
  static const double DIFF_SWAP_FEE_RATE = 0.15; // 차액교환 15%
  static const double PLATFORM_SWAP_FEE_RATE = 0.15; // 플랫폼 재고 교환 15%

  // 1. 즉시구매 금액 계산
  Map<String, int> calculateInstantBuy(int itemPrice) {
    final fee = (itemPrice * INSTANT_BUY_FEE_RATE).round();
    final totalAmount = itemPrice + fee;

    return {
      'item_price': itemPrice,
      'fee': fee,
      'total_amount': totalAmount,
    };
  }

  // 2. 순수교환 금액 계산
  Map<String, int> calculatePureSwap() {
    return {
      'fee': PURE_SWAP_FEE,
      'total_amount': PURE_SWAP_FEE,
    };
  }

  // 3. 차액교환 금액 계산
  Map<String, dynamic> calculateDiffSwap(int myItemValue, int targetItemValue) {
    final diff = (targetItemValue - myItemValue).abs();
    final fee = (diff * DIFF_SWAP_FEE_RATE).round();
    final totalAmount = diff + fee;

    return {
      'diff_amount': diff,
      'fee': fee,
      'total_amount': totalAmount,
      'is_i_pay': targetItemValue > myItemValue, // 내가 차액을 지불하는지 (bool)
    };
  }

  // 4. 플랫폼 재고 교환 금액 계산
  Map<String, int> calculatePlatformSwap(int myItemValue, int platformItemValue) {
    final diff = platformItemValue - myItemValue;
    final fee = (diff * PLATFORM_SWAP_FEE_RATE).round();
    final totalAmount = diff + fee;

    return {
      'my_item_value': myItemValue,
      'platform_item_value': platformItemValue,
      'diff_amount': diff,
      'fee': fee,
      'total_amount': totalAmount,
    };
  }

  // 5. 즉시구매 거래 생성
  Future<String?> createInstantBuyTrade({
    required String clothesId,
    required int totalAmount,
    required int fee,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // clothes 정보 조회
      final clothesData = await _supabase
          .from('clothes')
          .select()
          .eq('id', clothesId)
          .single();

      // swaps 테이블에 거래 기록
      final swapData = await _supabase.from('swaps').insert({
        'from_user_id': userId,
        'to_user_id': clothesData['user_id'],
        'my_item_id': null, // 즉시구매는 내 아이템 없음
        'target_item_id': clothesId,
        'status': 'pending',
        'trade_method': 'instant_buy',
        'diff_amount': 0,
        'fee': fee,
      }).select().single();

      debugPrint("✅ 즉시구매 거래 생성 성공: ${swapData['id']}");
      return swapData['id'];
    } catch (e) {
      debugPrint("❌ 즉시구매 거래 생성 실패: $e");
      return null;
    }
  }

  // 6. 순수교환 거래 생성
  Future<String?> createPureSwapTrade({
    required String myItemId,
    required String targetItemId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // target item 정보 조회
      final targetItem = await _supabase
          .from('clothes')
          .select()
          .eq('id', targetItemId)
          .single();

      // swaps 테이블에 거래 기록
      final swapData = await _supabase.from('swaps').insert({
        'from_user_id': userId,
        'to_user_id': targetItem['user_id'],
        'my_item_id': myItemId,
        'target_item_id': targetItemId,
        'status': 'pending',
        'trade_method': 'pure_swap',
        'diff_amount': 0,
        'fee': PURE_SWAP_FEE,
      }).select().single();

      debugPrint("✅ 순수교환 거래 생성 성공: ${swapData['id']}");
      return swapData['id'];
    } catch (e) {
      debugPrint("❌ 순수교환 거래 생성 실패: $e");
      return null;
    }
  }

  // 7. 차액교환 거래 생성
  Future<String?> createDiffSwapTrade({
    required String myItemId,
    required String targetItemId,
    required int diffAmount,
    required int fee,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // target item 정보 조회
      final targetItem = await _supabase
          .from('clothes')
          .select()
          .eq('id', targetItemId)
          .single();

      // swaps 테이블에 거래 기록
      final swapData = await _supabase.from('swaps').insert({
        'from_user_id': userId,
        'to_user_id': targetItem['user_id'],
        'my_item_id': myItemId,
        'target_item_id': targetItemId,
        'status': 'pending',
        'trade_method': 'diff_swap',
        'diff_amount': diffAmount,
        'fee': fee,
      }).select().single();

      debugPrint("✅ 차액교환 거래 생성 성공: ${swapData['id']}");
      return swapData['id'];
    } catch (e) {
      debugPrint("❌ 차액교환 거래 생성 실패: $e");
      return null;
    }
  }

  // 8. 플랫폼 재고 교환 거래 생성
  Future<String?> createPlatformSwapTrade({
    required String myItemId,
    required String platformItemId,
    required int diffAmount,
    required int fee,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 플랫폼 재고는 to_user_id를 null로 (시스템 소유)
      final swapData = await _supabase.from('swaps').insert({
        'from_user_id': userId,
        'to_user_id': null, // 플랫폼 재고는 상대방 없음
        'my_item_id': myItemId,
        'target_item_id': platformItemId,
        'status': 'pending',
        'trade_method': 'platform_swap',
        'diff_amount': diffAmount,
        'fee': fee,
      }).select().single();

      debugPrint("✅ 플랫폼 재고 교환 거래 생성 성공: ${swapData['id']}");
      return swapData['id'];
    } catch (e) {
      debugPrint("❌ 플랫폼 재고 교환 거래 생성 실패: $e");
      return null;
    }
  }

  // 9. 거래 상세 정보 조회
  Future<Map<String, dynamic>?> getTradeDetail(String swapId) async {
    try {
      final data = await _supabase
          .from('swaps')
          .select()
          .eq('id', swapId)
          .single();

      return data;
    } catch (e) {
      debugPrint("❌ 거래 정보 조회 실패: $e");
      return null;
    }
  }

  // 10. 내 아이템 가치 평가 (임시 - 실제로는 더 복잡한 로직 필요)
  Future<int> estimateItemValue(String itemId) async {
    try {
      final item = await _supabase
          .from('clothes')
          .select()
          .eq('id', itemId)
          .single();

      // 임시 가치 평가 로직 (실제로는 브랜드, 상태, 시세 등 고려)
      // 여기서는 단순히 고정값 반환
      return 300000; // 30만원으로 가정
    } catch (e) {
      debugPrint("❌ 아이템 가치 평가 실패: $e");
      return 0;
    }
  }

  // 11. 거래 방식 검증
  bool validateTradeMethod(String tradeType, String requestedMethod) {
    if (tradeType == '둘다 가능') return true;

    if (tradeType == '판매만') {
      return requestedMethod == 'instant_buy';
    }

    if (tradeType == '스왑만') {
      return requestedMethod == 'pure_swap' ||
          requestedMethod == 'diff_swap' ||
          requestedMethod == 'platform_swap';
    }

    return false;
  }

  // 12. 수수료 정보 텍스트 반환
  String getFeeDescription(String tradeMethod) {
    switch (tradeMethod) {
      case 'instant_buy':
        return '플랫폼 수수료 ${(INSTANT_BUY_FEE_RATE * 100).toInt()}%';
      case 'pure_swap':
        return '교환 수수료 ${PURE_SWAP_FEE.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
      case 'diff_swap':
        return '차액 교환 수수료 ${(DIFF_SWAP_FEE_RATE * 100).toInt()}%';
      case 'platform_swap':
        return '플랫폼 교환 수수료 ${(PLATFORM_SWAP_FEE_RATE * 100).toInt()}%';
      default:
        return '';
    }
  }
}