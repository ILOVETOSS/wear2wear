import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ClothingItem?> uploadClothingItem({
    required XFile imageFile,
    required String brand,
    required String title,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final String uid = user.id;
      final String fileName = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      // 1. Storage 업로드 (버킷 이름 확인: 'clothing-images')
      await _supabase.storage.from('clothing-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      // 2. 이미지 URL 생성
      final String imageUrl = _supabase.storage.from('clothing-images').getPublicUrl(fileName);

      // 3. DB 저장 (반드시 user_id 필드명 확인)
      final newItem = ClothingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: uid, // 이 값이 내 옷장 필터링의 핵심입니다.
        ownerName: user.email?.split('@')[0] ?? 'User',
        brand: brand,
        title: title,
        imageUrl: imageUrl,
        isLocal: false,
        size: 'M',
        category: '상의',
        condition: 'A',
        description: '',
        likes: 0,
        createdAt: DateTime.now(),
      );

      final response = await _supabase
          .from('clothes')
          .insert(newItem.toJson())
          .select()
          .single();

      return ClothingItem.fromJson(response);
    } catch (e) {
      print("업로드 에러: $e");
      return null;
    }
  }
}