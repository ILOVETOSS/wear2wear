import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';

class StorageService {
  static const String _key = 'my_clothing_items';

  // 리스트 저장
  static Future<void> saveItems(List<ClothingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_key, encodedData);
  }

  // 리스트 불러오기
  static Future<List<ClothingItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_key);
    if (encodedData == null) return [];

    final List<dynamic> decodedData = jsonDecode(encodedData);
    // 타입을 ClothingItem으로 명확하게 변환
    return decodedData
        .map((item) => ClothingItem.fromJson(item))
        .toList()
        .cast<ClothingItem>();
  }
}