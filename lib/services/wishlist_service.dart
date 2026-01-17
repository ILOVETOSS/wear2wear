import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'package:flutter/material.dart';

class WishlistService {
  final _supabase = supabase;

  // ==================== 위시리스트 ====================

  /// 위시리스트에 추가
  Future<bool> addToWishlist(String clothesId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('wishlists').insert({
        'user_id': userId,
        'clothes_id': clothesId,
      });

      debugPrint("✅ 위시리스트 추가 성공: $clothesId");
      return true;
    } catch (e) {
      debugPrint("❌ 위시리스트 추가 실패: $e");
      return false;
    }
  }

  /// 위시리스트에서 제거
  Future<bool> removeFromWishlist(String clothesId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('wishlists')
          .delete()
          .eq('user_id', userId)
          .eq('clothes_id', clothesId);

      debugPrint("✅ 위시리스트 제거 성공: $clothesId");
      return true;
    } catch (e) {
      debugPrint("❌ 위시리스트 제거 실패: $e");
      return false;
    }
  }

  /// 위시리스트 토글 (추가/제거)
  Future<bool> toggleWishlist(String clothesId) async {
    final isInWishlist = await checkWishlist(clothesId);
    if (isInWishlist) {
      return await removeFromWishlist(clothesId);
    } else {
      return await addToWishlist(clothesId);
    }
  }

  /// 위시리스트에 있는지 확인
  Future<bool> checkWishlist(String clothesId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _supabase
          .from('wishlists')
          .select('id')
          .eq('user_id', userId)
          .eq('clothes_id', clothesId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint("❌ 위시리스트 확인 실패: $e");
      return false;
    }
  }

  /// 내 위시리스트 목록 스트림
  Stream<List<Map<String, dynamic>>> getMyWishlist() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('wishlists')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// 위시리스트 아이템 상세 정보 가져오기
  Future<List<Map<String, dynamic>>> getWishlistWithDetails() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final wishlists = await _supabase
          .from('wishlists')
          .select('clothes_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> result = [];

      for (var wishlist in wishlists) {
        final clothesData = await _supabase
            .from('clothes')
            .select()
            .eq('id', wishlist['clothes_id'])
            .maybeSingle();

        if (clothesData != null) {
          result.add({
            ...clothesData,
            'added_at': wishlist['created_at'],
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint("❌ 위시리스트 상세 조회 실패: $e");
      return [];
    }
  }

  // ==================== 좋아요 (하트) ====================

  /// 좋아요 추가
  Future<bool> addLike(String clothesId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('likes').insert({
        'user_id': userId,
        'clothes_id': clothesId,
      });

      debugPrint("✅ 좋아요 추가 성공: $clothesId");
      return true;
    } catch (e) {
      debugPrint("❌ 좋아요 추가 실패: $e");
      return false;
    }
  }

  /// 좋아요 제거
  Future<bool> removeLike(String clothesId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('clothes_id', clothesId);

      debugPrint("✅ 좋아요 제거 성공: $clothesId");
      return true;
    } catch (e) {
      debugPrint("❌ 좋아요 제거 실패: $e");
      return false;
    }
  }

  /// 좋아요 토글
  Future<bool> toggleLike(String clothesId) async {
    final isLiked = await checkLike(clothesId);
    if (isLiked) {
      return await removeLike(clothesId);
    } else {
      return await addLike(clothesId);
    }
  }

  /// 좋아요 했는지 확인
  Future<bool> checkLike(String clothesId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _supabase
          .from('likes')
          .select('id')
          .eq('user_id', userId)
          .eq('clothes_id', clothesId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint("❌ 좋아요 확인 실패: $e");
      return false;
    }
  }

  /// 내 좋아요 목록 스트림
  Stream<List<Map<String, dynamic>>> getMyLikes() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('likes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// 좋아요한 아이템 상세 정보 가져오기
  Future<List<Map<String, dynamic>>> getLikedItemsWithDetails() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final likes = await _supabase
          .from('likes')
          .select('clothes_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> result = [];

      for (var like in likes) {
        final clothesData = await _supabase
            .from('clothes')
            .select()
            .eq('id', like['clothes_id'])
            .maybeSingle();

        if (clothesData != null) {
          result.add({
            ...clothesData,
            'liked_at': like['created_at'],
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint("❌ 좋아요 목록 조회 실패: $e");
      return [];
    }
  }

  /// 특정 옷의 좋아요 수 가져오기
  Future<int> getLikesCount(String clothesId) async {
    try {
      final data = await _supabase
          .from('clothes')
          .select('likes_count')
          .eq('id', clothesId)
          .single();

      return data['likes_count'] ?? 0;
    } catch (e) {
      debugPrint("❌ 좋아요 수 조회 실패: $e");
      return 0;
    }
  }
}