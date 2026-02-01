import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class NotificationService {
  final _supabase = supabase;

  // 1. 알림 생성
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedUserId,
    String? relatedItemId,
    String? relatedSwapId,
    String? imageUrl,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'related_user_id': relatedUserId,
        'related_item_id': relatedItemId,
        'related_swap_id': relatedSwapId,
        'is_read': false,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ 알림 생성 성공: $type");
    } catch (e) {
      debugPrint("❌ 알림 생성 실패: $e");
    }
  }

  // 2. 내 알림 목록 조회 (실시간 스트림)
  Stream<List<Map<String, dynamic>>> getMyNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((notifications) => notifications
        .where((notif) => notif['user_id'] == userId)
        .toList()
      ..sort((a, b) =>
          DateTime.parse(b['created_at'] as String)
              .compareTo(DateTime.parse(a['created_at'] as String))));
  }

  // 3. 읽지 않은 알림 개수
  Stream<int> getUnreadNotificationCount() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((notifications) => notifications
        .where((notif) =>
    notif['user_id'] == userId && notif['is_read'] == false)
        .length);
  }

  // 4. 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      debugPrint("✅ 알림 읽음 처리 완료: $notificationId");
    } catch (e) {
      debugPrint("❌ 알림 읽음 처리 실패: $e");
    }
  }

  // 5. 모든 알림 읽음 처리
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      debugPrint("✅ 모든 알림 읽음 처리 완료");
    } catch (e) {
      debugPrint("❌ 모든 알림 읽음 처리 실패: $e");
    }
  }

  // 6. 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      debugPrint("✅ 알림 삭제 성공: $notificationId");
    } catch (e) {
      debugPrint("❌ 알림 삭제 실패: $e");
    }
  }

  // 7. 알림 타입별 아이콘
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'swap_request':
        return Icons.swap_horiz_rounded;
      case 'swap_accepted':
        return Icons.check_circle_rounded;
      case 'swap_rejected':
        return Icons.cancel_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // 8. 알림 타입별 색상
  Color getNotificationColor(String type) {
    switch (type) {
      case 'swap_request':
        return const Color(0xFFB3EB00);
      case 'swap_accepted':
        return Colors.green;
      case 'swap_rejected':
        return Colors.red;
      case 'message':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // 9. 알림 타입별 한글 텍스트
  String getNotificationTypeLabel(String type) {
    switch (type) {
      case 'swap_request':
        return '교환 요청';
      case 'swap_accepted':
        return '교환 수락';
      case 'swap_rejected':
        return '교환 거절';
      case 'message':
        return '메시지';
      case 'like':
        return '좋아요';
      case 'comment':
        return '댓글';
      default:
        return '알림';
    }
  }

  // 10. 스왑 요청 알림 생성
  Future<void> notifySwapRequest({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String itemTitle,
    required String swapId,
  }) async {
    await createNotification(
      userId: receiverId,
      type: 'swap_request',
      title: '교환 요청 받음',
      message: '$senderName님이 "$itemTitle"에 교환을 요청했습니다.',
      relatedUserId: senderId,
      relatedSwapId: swapId,
    );
  }

  // 11. 스왑 수락 알림 생성
  Future<void> notifySwapAccepted({
    required String senderId,
    required String receiverName,
    required String itemTitle,
    required String swapId,
  }) async {
    await createNotification(
      userId: senderId,
      type: 'swap_accepted',
      title: '교환 수락됨',
      message: '$receiverName님이 교환을 수락했습니다!',
      relatedSwapId: swapId,
    );
  }

  // 12. 스왑 거절 알림 생성
  Future<void> notifySwapRejected({
    required String senderId,
    required String receiverName,
    required String itemTitle,
    required String swapId,
  }) async {
    await createNotification(
      userId: senderId,
      type: 'swap_rejected',
      title: '교환 거절됨',
      message: '$receiverName님이 교환을 거절했습니다.',
      relatedSwapId: swapId,
    );
  }

  // 13. 메시지 알림 생성
  Future<void> notifyNewMessage({
    required String receiverId,
    required String senderName,
    required String message,
    required String swapId,
  }) async {
    await createNotification(
      userId: receiverId,
      type: 'message',
      title: '새로운 메시지',
      message: '$senderName: $message',
      relatedSwapId: swapId,
    );
  }
}