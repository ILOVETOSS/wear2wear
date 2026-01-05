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

  // 2. 받은 요청 목록 조회 (상대방이 나에게 보낸 것)
  Stream<List<Map<String, dynamic>>> getReceivedRequests(String userId) {
    return _supabase
        .from('swaps')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .map((maps) => maps.where((m) => m['status'] == 'pending').toList());
  }

  // 3. [추가] 보낸 요청 목록 조회 (내가 상대방에게 보낸 것)
  Stream<List<Map<String, dynamic>>> getSentRequests() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    return _supabase
        .from('swaps')
        .stream(primaryKey: ['id'])
        .eq('sender_id', myId);
  }

  // 4. 요청 승인 (수락)
  Future<void> acceptRequest(String requestId) async {
    await _supabase.from('swaps').update({'status': 'accepted'}).eq('id', requestId);
  }

  // 5. 요청 거절
  Future<void> rejectRequest(String requestId) async {
    await _supabase.from('swaps').update({'status': 'rejected'}).eq('id', requestId);
  }

  // 6. 스왑 요청 보내기
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