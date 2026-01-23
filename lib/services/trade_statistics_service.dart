import 'package:flutter/material.dart';
import '../main.dart';

class TradeStatisticsService {
  final _supabase = supabase;

  // 1. 이번 달 거래 현황 조회
  Future<Map<String, int>> getMonthlyTradeStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'instant_buy': 0, 'swap_completed': 0};
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 즉시구매 건수
      final instantBuyData = await _supabase
          .from('swaps')
          .select('id')
          .eq('from_user_id', userId)
          .eq('trade_method', 'instant_buy')
          .eq('status', 'accepted')
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      // 교환완료 건수 (순수교환 + 차액교환 + 플랫폼교환)
      final swapData = await _supabase
          .from('swaps')
          .select('id')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .or('trade_method.eq.pure_swap,trade_method.eq.diff_swap,trade_method.eq.platform_swap')
          .eq('status', 'accepted')
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      debugPrint("✅ 이번 달 거래 현황 조회 성공");
      return {
        'instant_buy': instantBuyData.length,
        'swap_completed': swapData.length,
      };
    } catch (e) {
      debugPrint("❌ 거래 현황 조회 실패: $e");
      return {'instant_buy': 0, 'swap_completed': 0};
    }
  }

  // 2. 특정 월 거래 현황 조회
  Future<Map<String, int>> getTradeStatsByMonth(int year, int month) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'instant_buy': 0, 'swap_completed': 0};
      }

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final instantBuyData = await _supabase
          .from('swaps')
          .select('id')
          .eq('from_user_id', userId)
          .eq('trade_method', 'instant_buy')
          .eq('status', 'accepted')
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      final swapData = await _supabase
          .from('swaps')
          .select('id')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .or('trade_method.eq.pure_swap,trade_method.eq.diff_swap,trade_method.eq.platform_swap')
          .eq('status', 'accepted')
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      return {
        'instant_buy': instantBuyData.length,
        'swap_completed': swapData.length,
      };
    } catch (e) {
      debugPrint("❌ 특정 월 거래 현황 조회 실패: $e");
      return {'instant_buy': 0, 'swap_completed': 0};
    }
  }

  // 3. 전체 거래 통계 (가입 이후 누적)
  Future<Map<String, int>> getTotalTradeStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'instant_buy': 0, 'swap_completed': 0, 'total': 0};
      }

      final instantBuyData = await _supabase
          .from('swaps')
          .select('id')
          .eq('from_user_id', userId)
          .eq('trade_method', 'instant_buy')
          .eq('status', 'accepted');

      final swapData = await _supabase
          .from('swaps')
          .select('id')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .or('trade_method.eq.pure_swap,trade_method.eq.diff_swap,trade_method.eq.platform_swap')
          .eq('status', 'accepted');

      final total = instantBuyData.length + swapData.length;

      return {
        'instant_buy': instantBuyData.length,
        'swap_completed': swapData.length,
        'total': total,
      };
    } catch (e) {
      debugPrint("❌ 전체 거래 통계 조회 실패: $e");
      return {'instant_buy': 0, 'swap_completed': 0, 'total': 0};
    }
  }

  // 4. 월별 거래 금액 통계
  Future<Map<String, int>> getMonthlyTradeAmount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'total_paid': 0, 'total_earned': 0};
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // 내가 지불한 금액 (즉시구매 + 차액 등)
      final paidData = await _supabase
          .from('payments')
          .select('total_amount')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      int totalPaid = 0;
      for (var payment in paidData) {
        totalPaid += (payment['total_amount'] as int?) ?? 0;
      }

      // 내가 받은 금액 (판매 등)
      // TODO: 판매 수익 계산 로직 추가

      return {
        'total_paid': totalPaid,
        'total_earned': 0, // 판매 기능 구현 후 추가
      };
    } catch (e) {
      debugPrint("❌ 월별 거래 금액 조회 실패: $e");
      return {'total_paid': 0, 'total_earned': 0};
    }
  }

  // 5. 거래 타입별 통계
  Future<Map<String, int>> getTradeTypeStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final swaps = await _supabase
          .from('swaps')
          .select('trade_method')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .eq('status', 'accepted');

      Map<String, int> stats = {
        'instant_buy': 0,
        'pure_swap': 0,
        'diff_swap': 0,
        'platform_swap': 0,
      };

      for (var swap in swaps) {
        final method = swap['trade_method'] as String?;
        if (method != null && stats.containsKey(method)) {
          stats[method] = (stats[method] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint("❌ 거래 타입별 통계 조회 실패: $e");
      return {};
    }
  }

  // 6. 최근 N개월 거래 추이
  Future<List<Map<String, dynamic>>> getRecentMonthsStats(int months) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      List<Map<String, dynamic>> result = [];
      final now = DateTime.now();

      for (int i = months - 1; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final stats = await getTradeStatsByMonth(
          targetDate.year,
          targetDate.month,
        );

        result.add({
          'year': targetDate.year,
          'month': targetDate.month,
          'month_label': '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}',
          'instant_buy': stats['instant_buy'],
          'swap_completed': stats['swap_completed'],
          'total': (stats['instant_buy'] ?? 0) + (stats['swap_completed'] ?? 0),
        });
      }

      return result;
    } catch (e) {
      debugPrint("❌ 최근 거래 추이 조회 실패: $e");
      return [];
    }
  }

  // 7. 가장 많이 거래한 브랜드 TOP 5
  Future<List<Map<String, dynamic>>> getTopBrands() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // 내가 구매하거나 교환한 상품들의 브랜드 조회
      final swaps = await _supabase
          .from('swaps')
          .select('target_item_id')
          .eq('from_user_id', userId)
          .eq('status', 'accepted');

      Map<String, int> brandCount = {};

      for (var swap in swaps) {
        final itemId = swap['target_item_id'];
        if (itemId == null) continue;

        final item = await _supabase
            .from('clothes')
            .select('brand')
            .eq('id', itemId)
            .maybeSingle();

        if (item != null) {
          final brand = item['brand'] as String?;
          if (brand != null) {
            brandCount[brand] = (brandCount[brand] ?? 0) + 1;
          }
        }
      }

      // 정렬 및 TOP 5
      final sortedBrands = brandCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedBrands.take(5).map((entry) => {
        'brand': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      debugPrint("❌ TOP 브랜드 조회 실패: $e");
      return [];
    }
  }

  // 8. 거래 성공률
  Future<Map<String, dynamic>> getTradeSuccessRate() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'rate': 0.0, 'total': 0, 'accepted': 0};

      // 내가 보낸 모든 거래 제안
      final allSwaps = await _supabase
          .from('swaps')
          .select('status')
          .eq('from_user_id', userId);

      final total = allSwaps.length;
      if (total == 0) return {'rate': 0.0, 'total': 0, 'accepted': 0};

      final accepted = allSwaps.where((s) => s['status'] == 'accepted').length;
      final rate = (accepted / total * 100).toStringAsFixed(1);

      return {
        'rate': double.parse(rate),
        'total': total,
        'accepted': accepted,
      };
    } catch (e) {
      debugPrint("❌ 거래 성공률 조회 실패: $e");
      return {'rate': 0.0, 'total': 0, 'accepted': 0};
    }
  }

  // 9. 거래 타입 한글 변환
  String getTradeMethodLabel(String method) {
    switch (method) {
      case 'instant_buy':
        return '즉시구매';
      case 'pure_swap':
        return '순수교환';
      case 'diff_swap':
        return '차액교환';
      case 'platform_swap':
        return '플랫폼교환';
      default:
        return method;
    }
  }
}