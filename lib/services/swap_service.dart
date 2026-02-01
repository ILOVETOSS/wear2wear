import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class SwapService {
  final _supabase = supabase;

  // ============================================
  // 1. 내 옷장 조회 (실시간 스트림)
  // ============================================
  Stream<List<Map<String, dynamic>>> getMyCloset() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('clothes')
        .stream(primaryKey: ['id'])
        .map((clothes) =>
        clothes.where((item) => item['user_id'] == userId).toList());
  }

  // ============================================
  // 2. 스왑 요청 - 위치 인자 버전 (기존 코드 호환)
  // ============================================
  // swap_screen.dart 라인 486-488에서:
  // await _swapService.sendSwapRequest(
  //   targetItem['user_id'],           // receiverId (위치 1)
  //   targetItem['id'],                // receiverClothesId (위치 2)
  //   myItem['id'],                    // myClothesId (위치 3)
  // );

  Future<void> sendSwapRequest(
      String receiverId,
      String receiverClothesId,
      String myClothesId,
      ) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase.from('swaps').insert({
        'from_user_id': userId,              // ✅ sender_id → from_user_id
        'to_user_id': receiverId,            // ✅ receiver_id → to_user_id
        'my_item_id': myClothesId,           // ✅ sender_clothes_id → my_item_id
        'target_item_id': receiverClothesId, // ✅ receiver_clothes_id → target_item_id
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ 스왑 요청 전송 완료");
    } catch (e) {
      print("❌ 스왑 요청 전송 실패: $e");
      rethrow;
    }
  }

  // ============================================
  // 3. 스왑 요청 수락
  // ============================================
  Future<void> acceptRequest(String swapId) async {
    try {
      await _supabase
          .from('swaps')
          .update({'status': 'accepted'})
          .eq('id', swapId);

      print("✅ 스왑 수락 완료");
    } catch (e) {
      print("❌ 스왑 수락 실패: $e");
      rethrow;
    }
  }

  // ============================================
  // 4. 스왑 요청 거절
  // ============================================
  Future<void> rejectRequest(String swapId) async {
    try {
      await _supabase
          .from('swaps')
          .update({'status': 'rejected'})
          .eq('id', swapId);

      print("✅ 스왑 거절 완료");
    } catch (e) {
      print("❌ 스왑 거절 실패: $e");
      rethrow;
    }
  }

  // ============================================
  // 5. 내 스왑 목록 조회 (실시간)
  // ============================================
  Stream<List<Map<String, dynamic>>> getMySwaps() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('swaps')
        .stream(primaryKey: ['id'])
        .map((swaps) => swaps
        .where((swap) =>
    swap['sender_id'] == userId || swap['receiver_id'] == userId)
        .toList());
  }

  // ============================================
  // 6. 특정 스왑 정보 조회
  // ============================================
  Future<Map<String, dynamic>?> getSwapDetails(String swapId) async {
    try {
      final result = await _supabase
          .from('swaps')
          .select()
          .eq('id', swapId)
          .maybeSingle();

      return result;
    } catch (e) {
      print("❌ 스왑 정보 조회 실패: $e");
      return null;
    }
  }

  // ============================================
  // 7. 옷 정보 조회
  // ============================================
  Future<Map<String, dynamic>?> getClothItem(String clothId) async {
    try {
      final result = await _supabase
          .from('clothes')
          .select()
          .eq('id', clothId)
          .maybeSingle();

      return result;
    } catch (e) {
      print("❌ 옷 정보 조회 실패: $e");
      return null;
    }
  }

  // ============================================
  // 8. 사용자 프로필 조회
  // ============================================
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final result = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return result;
    } catch (e) {
      print("❌ 사용자 프로필 조회 실패: $e");
      return null;
    }
  }
}