import '../main.dart';

class ClothingItem {
  final String id;
  final String userId;
  final String ownerName;
  final String brand;
  final String title;
  final String imageUrl;
  final bool isLocal;
  final String size;
  final String category;
  final String condition;
  final String description;
  final int likes;
  final DateTime createdAt;
  final int? price; // 🔥 가격 필드 추가
  final String tradeType; // 🔥 거래 방식
  final bool isPartnerBrand; // 🔥 파트너 브랜드 여부
  final String authStatus; // 🔥 정품 인증 상태

  ClothingItem({
    required this.id,
    required this.userId,
    required this.ownerName,
    required this.brand,
    required this.title,
    required this.imageUrl,
    this.isLocal = false,
    required this.size,
    required this.category,
    required this.condition,
    required this.description,
    required this.likes,
    required this.createdAt,
    this.price,
    this.tradeType = '둘다 가능',
    this.isPartnerBrand = false,
    this.authStatus = '모름',
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'].toString(),
      userId: json['user_id'],
      ownerName: json['owner_name'] ?? '',
      brand: json['brand'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      size: json['size'] ?? 'M',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      likes: json['likes'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      price: json['price'],
      tradeType: json['trade_type'] ?? '둘다 가능',
      isPartnerBrand: json['is_partner_brand'] ?? false,
      authStatus: json['auth_status'] ?? '모름',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'owner_name': ownerName,
      'brand': brand,
      'title': title,
      'image_url': imageUrl,
      'size': size,
      'category': category,
      'condition': condition,
      'description': description,
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
      'price': price,
      'trade_type': tradeType,
      'is_partner_brand': isPartnerBrand,
      'auth_status': authStatus,
    };
  }
}