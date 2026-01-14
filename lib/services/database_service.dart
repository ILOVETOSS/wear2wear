import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. 내 옷 등록 (다중 이미지 지원)
  Future<bool> uploadClothingItem({
    required List<XFile> imageFiles, // ✅ 단일 파일에서 리스트로 변경
    required String brand,
    required String title,
    required Map<String, dynamic> extraData,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      List<String> uploadedUrls = [];

      // 1-1. 여러 장의 이미지를 순차적으로 Storage에 업로드
      for (int i = 0; i < imageFiles.length; i++) {
        final String fileName = 'clothing/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Uint8List bytes = await imageFiles[i].readAsBytes();

        await _supabase.storage.from('clothing-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

        final String url = _supabase.storage.from('clothing-images').getPublicUrl(fileName);
        uploadedUrls.add(url);
      }

      print("✅ 모든 이미지 업로드 완료: ${uploadedUrls.length}장");

      // 1-2. Database Insert
      await _supabase.from('clothes').insert({
        'user_id': user.id,
        'brand': brand,
        'title': title,
        // ✅ 첫 번째 이미지는 대표 이미지로, 전체 리스트는 따로 저장
        'image_url': uploadedUrls.isNotEmpty ? uploadedUrls[0] : null,
        'image_urls': uploadedUrls, // 🔥 DB에 image_urls 컬럼(jsonb 등)이 있어야 합니다.
        'owner_name': user.userMetadata?['full_name'] ?? 'User',
        'trade_type': extraData['trade_type'],
        'auth_status': extraData['auth_status'],
        'disclaimer_agreed': extraData['disclaimer_agreed'],
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print("❌ 업로드 에러: $e");
      return false;
    }
  }

  // 2. 커뮤니티 OOTD 등록 (다중 이미지 지원)
  Future<bool> uploadCommunityPost({
    required List<XFile> imageFiles, // ✅ 리스트로 변경
    required String category,
    required String content,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      List<String> uploadedUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final String fileName = 'community/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final bytes = await imageFiles[i].readAsBytes();

        await _supabase.storage.from('clothing-images').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        uploadedUrls.add(_supabase.storage.from('clothing-images').getPublicUrl(fileName));
      }

      await _supabase.from('community_posts').insert({
        'publisher_id': user.id,
        'publisher_name': user.userMetadata?['full_name'] ?? '사용자',
        'category': category,
        'content': content,
        'image_url': uploadedUrls[0],
        'image_urls': uploadedUrls, // 🔥 DB 컬럼 확인 필요
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print("❌ 커뮤니티 등록 에러: $e");
      return false;
    }
  }
}