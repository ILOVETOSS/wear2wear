import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'signup_screen.dart'; // 💡 이미 가지고 계신 SignupScreen 파일을 임포트하세요.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 로그인 핸들러
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        // ✅ 로그인 성공 시 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 중 에러가 발생했습니다.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "CLO-SWAP",
              style: TextStyle(
                color: Color(0xFFE2FF00),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFFE2FF00))
            else ...[
              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2FF00),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("로그인", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ 회원가입 화면으로 이동하는 버튼 (수정됨)
              TextButton(
                onPressed: () {
                  // 💡 누르면 작성하신 SignupScreen으로 이동합니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "계정이 없으신가요? 회원가입",
                  style: TextStyle(color: Color(0xFFE2FF00)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}