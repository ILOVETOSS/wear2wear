// 1. 만약 아래 코드에서 'File'을 직접 사용하지 않는다면 이 줄을 지우세요.
// import 'dart:io';

class ClothingItem {
  final String id;
  final String ownerName;
  final String brand;
  final String title;
  final String size;
  final String category;
  final String condition;
  final String description;
  final String imageUrl;
  final bool isLocal;
  final int likes;
  final DateTime createdAt;

  ClothingItem({
    required this.id,
    required this.ownerName,
    required this.brand,
    required this.title,
    required this.size,
    required this.category,
    required this.condition,
    required this.description,
    required this.imageUrl,
    this.isLocal = false,
    this.likes = 0,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // storage_service.dart 에러 해결을 위한 toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerName': ownerName,
      'brand': brand,
      'title': title,
      'size': size,
      'category': category,
      'condition': condition,
      'description': description,
      'imageUrl': imageUrl,
      'isLocal': isLocal,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 데이터 복구를 위한 fromJson
  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      ownerName: json['ownerName'],
      brand: json['brand'],
      title: json['title'],
      size: json['size'],
      category: json['category'],
      condition: json['condition'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      isLocal: json['isLocal'] ?? false,
      likes: json['likes'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}