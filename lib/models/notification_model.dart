class Notification {
  final String id;
  final String userId;
  final String type; // 'swap_request', 'swap_accepted', 'swap_rejected', 'message', 'like', 'comment'
  final String title;
  final String message;
  final String? relatedUserId;
  final String? relatedItemId;
  final String? relatedSwapId;
  final bool isRead;
  final DateTime createdAt;
  final String? imageUrl;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedUserId,
    this.relatedItemId,
    this.relatedSwapId,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'].toString(),
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      relatedUserId: json['related_user_id'],
      relatedItemId: json['related_item_id'],
      relatedSwapId: json['related_swap_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'related_user_id': relatedUserId,
      'related_item_id': relatedItemId,
      'related_swap_id': relatedSwapId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }
}