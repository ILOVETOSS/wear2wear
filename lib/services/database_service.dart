import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. 내 옷 등록 (스왑용)
  Future<bool> uploadClothingItem({
    required XFile imageFile,
    required String brand,
    required String title,
    required Map<String, dynamic> extraData,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final String fileName = 'clothing/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      await _supabase.storage.from('clothing-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final String imageUrl = _supabase.storage.from('clothing-images').getPublicUrl(fileName);

      await _supabase.from('clothes').insert({
        'user_id': user.id,
        'brand': brand,
        'title': title,
        'image_url': imageUrl,
        'owner_name': user.userMetadata?['full_name'] ?? 'User',
        ...extraData,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 2. 커뮤니티 OOTD 등록
  Future<bool> uploadCommunityPost({
    required XFile imageFile,
    required String category,
    required String content,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final String fileName = 'community/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      await _supabase.storage.from('clothing-images').uploadBinary(
        fileName, bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final String imageUrl = _supabase.storage.from('clothing-images').getPublicUrl(fileName);

      await _supabase.from('community_posts').insert({
        'publisher_id': user.id,
        'publisher_name': user.userMetadata?['full_name'] ?? '사용자',
        'category': category,
        'content': content,
        'image_url': imageUrl,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}