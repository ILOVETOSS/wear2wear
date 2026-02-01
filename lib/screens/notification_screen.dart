import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),  // ✅ 뒤로가기 버튼 검은색
        title: const Text(
          "NOTIFICATIONS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black12, height: 1.0),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "모든 알림을 읽음 처리했습니다",
                      style: TextStyle(
                        color: Colors.white,  // ✅ 흰색
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: Text(
              "모두 읽음",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60.sp,
                    color: Colors.black12,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "알림이 없습니다",
                    style: TextStyle(
                      color: Colors.black26,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 80,
              color: Color(0xFFEEEEEE),
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context,
      Map<String, dynamic> notification,
      ) {
    final type = notification['type'];
    final title = notification['title'];
    final message = notification['message'];
    final isRead = notification['is_read'] ?? false;
    final createdAt = DateTime.parse(notification['created_at'] as String);
    final notificationId = notification['id'];

    final timeAgo = _getTimeAgo(createdAt);
    final icon = _notificationService.getNotificationIcon(type);
    final iconColor = _notificationService.getNotificationColor(type);

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await _notificationService.markAsRead(notificationId);
        }
        _handleNotificationTap(context, notification);
      },
      child: Container(
        color: isRead ? Colors.white : const Color(0xFFFAFAFA),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘 배경
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24.sp,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // 알림 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // 읽음 상태 및 삭제 버튼
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isRead)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  SizedBox(width: 8.w, height: 8.w),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () async {
                    await _notificationService.deleteNotification(notificationId);
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.black54,  // ✅ 수정: Colors.black26 → Colors.black54
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return "방금";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}분 전";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}시간 전";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}일 전";
    } else {
      return "${dateTime.month}월 ${dateTime.day}일";
    }
  }

  void _handleNotificationTap(
      BuildContext context,
      Map<String, dynamic> notification,
      ) {
    final type = notification['type'];
    final relatedSwapId = notification['related_swap_id'];

    switch (type) {
      case 'swap_request':
      case 'swap_accepted':
      case 'swap_rejected':
      case 'message':
        if (relatedSwapId != null) {
          // 채팅 페이지로 이동
          // Navigator.push(context, MaterialPageRoute(...));
        }
        break;
      default:
        break;
    }
  }
}