import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ChatService {
  final _supabase = supabase;

  // 메시지 실시간 조회
  Stream<List<Map<String, dynamic>>> getChatMessages(String swapId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((messages) {
      final filtered = messages.where((msg) => msg['swap_id'] == swapId).toList();
      filtered.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
      return filtered;
    });
  }

  // 메시지 전송
  Future<void> sendMessage(String swapId, String content) async {
    try {
      final senderId = _supabase.auth.currentUser!.id;
      await _supabase.from('messages').insert({
        'swap_id': swapId,
        'sender_id': senderId,
        'content': content,
        'is_read': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 채팅방 나가기 (DB 데이터 삭제)
  Future<void> leaveChat(String swapId) async {
    try {
      await _supabase.from('swaps').delete().eq('id', swapId);
    } catch (e) {
      rethrow;
    }
  }
}