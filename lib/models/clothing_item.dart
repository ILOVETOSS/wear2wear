import '../main.dart'; // supabase 사용을 위해 추가

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
  });

  // 🔥 Supabase(Map)에서 데이터를 가져오는 팩토리 생성자
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
    };
  }
}