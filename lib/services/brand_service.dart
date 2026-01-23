import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'package:flutter/material.dart';

class BrandService {
  final _supabase = supabase;

  // 1. 모든 브랜드 조회
  Stream<List<Map<String, dynamic>>> getAllBrands() {
    return _supabase
        .from('brands')
        .stream(primaryKey: ['id'])
        .order('follower_count', ascending: false);
  }

  // 2. 공식 브랜드만 조회
  Stream<List<Map<String, dynamic>>> getOfficialBrands() {
    return _supabase
        .from('brands')
        .stream(primaryKey: ['id'])
        .eq('is_official', true)
        .order('follower_count', ascending: false);
  }

  // 3. 특정 브랜드 상세 정보
  Future<Map<String, dynamic>?> getBrandById(String brandId) async {
    try {
      final data = await _supabase
          .from('brands')
          .select()
          .eq('id', brandId)
          .single();
      return data;
    } catch (e) {
      debugPrint("브랜드 조회 에러: $e");
      return null;
    }
  }

  // 4. 브랜드별 상품 조회
  Stream<List<Map<String, dynamic>>> getBrandProducts(String brandId) {
    return _supabase
        .from('clothes')
        .stream(primaryKey: ['id'])
        .eq('brand_id', brandId)
        .order('created_at', ascending: false);
  }

  // 5. 브랜드 팔로우
  Future<bool> followBrand(String brandId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('brand_follows').insert({
        'user_id': userId,
        'brand_id': brandId,
      });

      debugPrint("✅ 브랜드 팔로우 성공: $brandId");
      return true;
    } catch (e) {
      debugPrint("❌ 브랜드 팔로우 실패: $e");
      return false;
    }
  }

  // 6. 브랜드 언팔로우
  Future<bool> unfollowBrand(String brandId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('brand_follows')
          .delete()
          .eq('user_id', userId)
          .eq('brand_id', brandId);

      debugPrint("✅ 브랜드 언팔로우 성공: $brandId");
      return true;
    } catch (e) {
      debugPrint("❌ 브랜드 언팔로우 실패: $e");
      return false;
    }
  }

  // 7. 팔로우 여부 확인
  Future<bool> isFollowing(String brandId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _supabase
          .from('brand_follows')
          .select()
          .eq('user_id', userId)
          .eq('brand_id', brandId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint("❌ 팔로우 확인 실패: $e");
      return false;
    }
  }

  // 8. 팔로우 토글
  Future<bool> toggleFollow(String brandId) async {
    final isFollowing = await this.isFollowing(brandId);
    if (isFollowing) {
      return await unfollowBrand(brandId);
    } else {
      return await followBrand(brandId);
    }
  }

  // 9. 내가 팔로우한 브랜드 목록
  Stream<List<Map<String, dynamic>>> getMyFollowedBrands() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('brand_follows')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // 10. 팔로우한 브랜드의 상세 정보 가져오기
  Future<List<Map<String, dynamic>>> getMyFollowedBrandsWithDetails() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final follows = await _supabase
          .from('brand_follows')
          .select('brand_id')
          .eq('user_id', userId);

      List<Map<String, dynamic>> result = [];

      for (var follow in follows) {
        final brandData = await _supabase
            .from('brands')
            .select()
            .eq('id', follow['brand_id'])
            .maybeSingle();

        if (brandData != null) {
          result.add(brandData);
        }
      }

      return result;
    } catch (e) {
      debugPrint("❌ 팔로우 브랜드 조회 실패: $e");
      return [];
    }
  }

  // 11. 브랜드명으로 검색
  Future<List<Map<String, dynamic>>> searchBrandsByName(String query) async {
    try {
      final data = await _supabase
          .from('brands')
          .select()
          .ilike('name', '%$query%')
          .order('follower_count', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint("❌ 브랜드 검색 실패: $e");
      return [];
    }
  }
}