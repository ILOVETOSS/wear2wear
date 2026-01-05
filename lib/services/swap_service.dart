import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class SwapService {
  final _supabase = supabase;

  // 1. 내 옷장 데이터 조회
  Stream<List<Map<String, dynamic>>> getMyCloset() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    return _supabase
        .from('clothes')
        .stream(primaryKey: ['id'])
        .eq('user_id', myId)
        .order('created_at');
  }

  // 2. 받은 요청 목록 조회 (수정됨: filter 사용)
  Stream<List<Map<String, dynamic>>> getReceivedRequests(String userId) {
    return _supabase
        .from('swaps')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .map((maps) => maps.where((m) => m['status'] == 'pending').toList());
  }

  // 3. 요청 승인/거절
  Future<void> acceptRequest(String requestId) async {
    await _supabase.from('swaps').update({'status': 'accepted'}).eq('id', requestId);
  }

  Future<void> rejectRequest(String requestId) async {
    await _supabase.from('swaps').update({'status': 'rejected'}).eq('id', requestId);
  }

  // 4. 스왑 요청 보내기 (매개변수 이름 중요!)
  Future<void> sendSwapRequest({
    required String receiverId,
    required String receiverClothesId,
    required String myClothesId,
  }) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    await _supabase.from('swaps').insert({
      'sender_id': myId,
      'receiver_id': receiverId,
      'sender_clothes_id': myClothesId,
      'receiver_clothes_id': receiverClothesId,
      'status': 'pending',
    });
  }
}