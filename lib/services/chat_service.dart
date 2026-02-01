import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ChatService {
  final _supabase = supabase;

  // ============================================
  // 1. 메시지 조회 - 위치 인자 1개 (기존 코드 호환)
  // ============================================
  // chat_screen.dart 라인 77에서:
  // stream: _chatService.getChatMessages(widget.swapId),

  Stream<List<Map<String, dynamic>>> getChatMessages(String swapId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((messages) {
      final filtered = messages
          .where((msg) => msg['swap_id'] == swapId)
          .toList();

      filtered.sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });

      return filtered;
    });
  }

  // ============================================
  // 2. 메시지 전송 - 위치 인자 2개 (기존 코드 호환)
  // ============================================
  // chat_screen.dart 라인 217에서:
  // _chatService.sendMessage(widget.swapId, _msgController.text.trim());

  Future<void> sendMessage(String swapId, String content) async {
    try {
      final senderId = _supabase.auth.currentUser!.id;
      await _supabase.from('messages').insert({
        'swap_id': swapId,
        'sender_id': senderId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
      print("✅ 메시지 전송 완료");
    } catch (e) {
      print("❌ 메시지 전송 실패: $e");
      rethrow;
    }
  }

  // ============================================
  // 3. 메시지 읽음 처리
  // ============================================
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
      print("✅ 메시지 읽음 처리 완료");
    } catch (e) {
      print("❌ 메시지 읽음 처리 실패: $e");
      rethrow;
    }
  }

  // ============================================
  // 4. 마지막 메시지 조회
  // ============================================
  Future<Map<String, dynamic>?> getLastMessage(String swapId) async {
    try {
      final result = await _supabase
          .from('messages')
          .select()
          .eq('swap_id', swapId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return result;
    } catch (e) {
      print("❌ 마지막 메시지 조회 실패: $e");
      return null;
    }
  }

  // ============================================
  // 5. 읽지 않은 메시지 개수
  // ============================================
  Future<int> getUnreadMessageCount(String swapId, String userId) async {
    try {
      final result = await _supabase
          .from('messages')
          .select()
          .eq('swap_id', swapId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (result as List).length;
    } catch (e) {
      print("❌ 읽지 않은 메시지 개수 조회 실패: $e");
      return 0;
    }
  }
}