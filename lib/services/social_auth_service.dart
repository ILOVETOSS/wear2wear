import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class SocialAuthService {
  final _supabase = supabase;

  // ============================================
  // 1. 카카오 로그인
  // ============================================
  // pubspec.yaml에 추가:
  // kakao_flutter_sdk: ^1.9.0
  //
  // Android: google-services.json 추가
  // iOS: Info.plist에 카카오 URL 스킴 추가

  Future<AuthResponse?> signInWithKakao() async {
    try {
      // Step 1: 카카오 SDK로 토큰 얻기
      // (kakao_flutter_sdk 사용)
      // final token = await UserApi.instance.login();

      // Step 2: Supabase에 카카오 토큰 전달 (Supabase 설정 필요)
      // const response = await _supabase.auth.signInWithIdToken(
      //   provider: 'kakao',
      //   idToken: token.accessToken,
      // );

      // 임시: 실제 구현은 백엔드 설정 필요
      debugPrint("⚠️ 카카오 로그인 준비 중...");
      return null;
    } catch (e) {
      debugPrint("❌ 카카오 로그인 실패: $e");
      return null;
    }
  }

  // ============================================
  // 2. 애플 로그인
  // ============================================
  // pubspec.yaml에 추가:
  // sign_in_with_apple: ^5.0.0
  //
  // iOS: Xcode 설정에서 Sign in with Apple capability 활성화
  // Android: 필요 없음 (iOS 전용)

  Future<AuthResponse?> signInWithApple() async {
    try {
      // Step 1: Apple 로그인
      // final credential = await SignInWithApple.getAppleIDCredential(
      //   scopes: [
      //     AppleIDAuthorizationScopes.email,
      //     AppleIDAuthorizationScopes.fullName,
      //   ],
      // );

      // Step 2: Supabase에 Apple 토큰 전달
      // final response = await _supabase.auth.signInWithIdToken(
      //   provider: 'apple',
      //   idToken: credential.identityToken!,
      // );

      // 임시: 실제 구현은 Supabase 설정 필요
      debugPrint("⚠️ 애플 로그인 준비 중...");
      return null;
    } catch (e) {
      debugPrint("❌ 애플 로그인 실패: $e");
      return null;
    }
  }

  // ============================================
  // 3. 구글 로그인 (보너스)
  // ============================================
  // pubspec.yaml에 추가:
  // google_sign_in: ^6.1.0
  //
  // Android: google-services.json 추가
  // iOS: GoogleService-Info.plist 추가

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // 임시: 실제 구현은 google_sign_in 패키지 사용
      debugPrint("⚠️ 구글 로그인 준비 중...");
      return null;
    } catch (e) {
      debugPrint("❌ 구글 로그인 실패: $e");
      return null;
    }
  }

  // ============================================
  // 4. 소셜 로그인 후 프로필 생성/업데이트
  // ============================================
  Future<bool> createOrUpdateSocialProfile(
      String userId,
      String? email,
      String? displayName,
      ) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'nickname': displayName ?? 'User',
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ 소셜 프로필 생성/업데이트 성공");
      return true;
    } catch (e) {
      debugPrint("❌ 소셜 프로필 처리 실패: $e");
      return false;
    }
  }
}