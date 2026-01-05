import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 로그인
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return response;
    } catch (e) {
      print("❌ 로그인 에러: $e");
      return null;
    }
  }

  // 회원가입
  Future<String> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    required String name,
    required String gender,
  }) async {
    try {
      // 1. Supabase Auth 계정 생성
      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'nickname': nickname.trim(),
          'name': name.trim(),
          'gender': gender,
        },
      );

      if (res.user != null) {
        // 2. 'users' 테이블에 추가 정보 저장
        await _supabase.from('users').insert({
          'id': res.user!.id,
          'email': email.trim(),
          'nickname': nickname.trim(),
          'name': name.trim(),
          'gender': gender,
        });

        await _supabase.auth.signOut();
        return "success";
      }
      return "error";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "error";
    }
  }
}