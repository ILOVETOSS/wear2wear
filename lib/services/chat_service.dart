import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ChatService {
  // 1. 메시지 보내기
  Future<void> sendMessage(String swapId, String content) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    await supabase.from('messages').insert({
      'swap_id': swapId,
      'sender_id': myId,
      'content': content,
    });
  }

  // 2. 메시지 실시간 스트림
  Stream<List<Map<String, dynamic>>> getChatMessages(String swapId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('swap_id', swapId)
        .order('created_at', ascending: true);
  }
}