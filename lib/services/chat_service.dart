import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ChatService {
  final _supabase = supabase;

  // 메시지 조회 (오래된 메시지가 위로 가게 정렬)
  Stream<List<Map<String, dynamic>>> getChatMessages(String swapId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((messages) {
      final filtered = messages
          .where((msg) => msg['swap_id'] == swapId)
          .toList();

      // 시간순 정렬 (과거 -> 현재)
      filtered.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateA.compareTo(dateB);
      });

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
      print("✅ 메시지 전송 완료");
    } catch (e) {
      print("❌ 메시지 전송 실패: $e");
      rethrow;
    }
  }

  // 메시지 읽음 처리 (상대방 메시지만)
  Future<void> markAsRead(String swapId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;
    await _supabase
        .from('messages')
        .update({'is_read': true})
        .eq('swap_id', swapId)
        .neq('sender_id', myId)
        .eq('is_read', false);
  }
}