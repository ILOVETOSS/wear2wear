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
  Stream<List<Map<String, dynamic>>> getReceivedRequests() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    return _supabase
        .from('swaps')
        .stream(primaryKey: ['id'])
        .eq('to_user_id', myId) // 🔥 receiver_id -> to_user_id로 변경
        .map((maps) => maps.where((m) => m['status'] == 'pending').toList());
  }

  // 3. 보낸 요청 목록 조회 (내가 상대방에게 보낸 것)
  Stream<List<Map<String, dynamic>>> getSentRequests() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return Stream.value([]);

    return _supabase
        .from('swaps')
        .stream(primaryKey: ['id'])
        .eq('from_user_id', myId); // 🔥 sender_id -> from_user_id로 변경
  }

  // 4. 요청 승인 (수락)
  Future<void> acceptRequest(String requestId) async {
    await _supabase.from('swaps').update({'status': 'accepted'}).eq('id', requestId);
  }

  // 5. 요청 거절
  Future<void> rejectRequest(String requestId) async {
    await _supabase.from('swaps').update({'status': 'rejected'}).eq('id', requestId);
  }

  // 6. 스왑 요청 보내기 (HomeScreen에서 사용 중인 필드명과 일치시킴)
  Future<void> sendSwapRequest({
    required String receiverId,
    required String receiverClothesId,
    required String myClothesId,
  }) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    await _supabase.from('swaps').insert({
      'from_user_id': myId,          // 🔥 sender_id -> from_user_id
      'to_user_id': receiverId,      // 🔥 receiver_id -> to_user_id
      'my_item_id': myClothesId,     // 🔥 sender_clothes_id -> my_item_id
      'target_item_id': receiverClothesId, // 🔥 receiver_clothes_id -> target_item_id
      'status': 'pending',
    });
  }
}