class SwapRequest {
  final String? id;
  final String senderId;
  final String receiverId;
  final String senderItemId;
  final String receiverItemId;
  final String status;
  final DateTime timestamp;

  SwapRequest({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderItemId,
    required this.receiverItemId,
    this.status = 'pending',
    required this.timestamp,
  });

  factory SwapRequest.fromJson(Map<String, dynamic> json) {
    return SwapRequest(
      id: json['id'].toString(),
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      senderItemId: json['sender_item_id'],
      receiverItemId: json['receiver_item_id'],
      status: json['status'] ?? 'pending',
      timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'sender_item_id': senderItemId,
      'receiver_item_id': receiverItemId,
      'status': status,
    };
  }
}