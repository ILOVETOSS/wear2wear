import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class AccountService {
  final _supabase = supabase;

  // ============================================
  // 1. 로그아웃
  // ============================================
  Future<bool> logout() async {
    try {
      await _supabase.auth.signOut();
      debugPrint("✅ 로그아웃 성공");
      return true;
    } catch (e) {
      debugPrint("❌ 로그아웃 실패: $e");
      return false;
    }
  }

  // ============================================
  // 2. 비밀번호 재설정 (이메일로 링크 전송)
  // ============================================
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.swap-fit://reset-password', // 앱의 deeplink
      );
      debugPrint("✅ 비밀번호 재설정 이메일 전송 성공");
      return true;
    } catch (e) {
      debugPrint("❌ 비밀번호 재설정 이메일 전송 실패: $e");
      return false;
    }
  }

  // ============================================
  // 3. 비밀번호 직접 변경 (로그인 상태에서)
  // ============================================
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint("✅ 비밀번호 변경 성공");
      return true;
    } catch (e) {
      debugPrint("❌ 비밀번호 변경 실패: $e");
      return false;
    }
  }

  // ============================================
  // 4. 계정 삭제 (전체 데이터 삭제)
  // ============================================
  Future<bool> deleteAccount(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final userId = user.id;
      final email = user.email ?? '';

      // Step 1: 비밀번호 확인 (재인증)
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint("❌ 비밀번호 확인 실패: $e");
        return false;
      }

      // Step 2: 사용자 관련 데이터 삭제 (Cascade Delete 이전에)
      await _deleteUserData(userId);

      // Step 3: Supabase Auth 계정 삭제
      await _supabase.auth.admin.deleteUser(userId);

      debugPrint("✅ 계정 삭제 성공");
      return true;
    } catch (e) {
      debugPrint("❌ 계정 삭제 실패: $e");
      return false;
    }
  }

  // ============================================
  // 5. 사용자 관련 데이터 전부 삭제 (Helper)
  // ============================================
  Future<void> _deleteUserData(String userId) async {
    try {
      // 업로드한 이미지들 삭제
      final clothesList = await _supabase
          .from('clothes')
          .select('id, image_urls')
          .eq('user_id', userId);

      for (var clothes in clothesList) {
        if (clothes['image_urls'] != null && clothes['image_urls'] is List) {
          for (var imageUrl in clothes['image_urls']) {
            try {
              final filePath = _extractFilePathFromUrl(imageUrl);
              await _supabase.storage.from('clothing-images').remove([filePath]);
            } catch (e) {
              debugPrint("이미지 삭제 실패 (무시): $e");
            }
          }
        }
      }

      // 프로필 이미지 삭제
      try {
        await _supabase.storage.from('avatars').remove(['$userId.jpg']);
      } catch (e) {
        debugPrint("프로필 이미지 삭제 실패 (무시): $e");
      }

      // 데이터베이스 데이터 삭제
      await _supabase.from('wishlists').delete().eq('user_id', userId);
      await _supabase.from('likes').delete().eq('user_id', userId);
      await _supabase.from('messages').delete().eq('sender_id', userId);
      await _supabase.from('notifications').delete().eq('user_id', userId);
      await _supabase.from('swaps').delete().or('from_user_id.eq.$userId,to_user_id.eq.$userId');
      await _supabase.from('clothes').delete().eq('user_id', userId);
      await _supabase.from('community_posts').delete().eq('publisher_id', userId);
      await _supabase.from('profiles').delete().eq('id', userId);
      await _supabase.from('users').delete().eq('id', userId);

      debugPrint("✅ 사용자 데이터 삭제 완료");
    } catch (e) {
      debugPrint("❌ 사용자 데이터 삭제 중 에러: $e");
      rethrow;
    }
  }

  // ============================================
  // 6. URL에서 파일 경로 추출 (Helper)
  // ============================================
  String _extractFilePathFromUrl(String url) {
    // URL: https://bucket.supabase.co/storage/v1/object/public/clothing-images/clothing%2F123%2F456.jpg
    // 추출: clothing/123/456.jpg
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final index = pathSegments.indexOf('clothing-images');
      if (index != -1 && index + 1 < pathSegments.length) {
        return pathSegments.sublist(index + 1).join('/');
      }
    } catch (e) {
      debugPrint("파일 경로 추출 실패: $e");
    }
    return '';
  }

  // ============================================
  // 7. 이메일로 로그인한 경우 비밀번호 확인
  // ============================================
  Future<bool> verifyPassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) return false;

      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint("❌ 비밀번호 확인 실패: $e");
      return false;
    }
  }
}