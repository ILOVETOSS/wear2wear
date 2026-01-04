import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart'; // 🔥 추가 예정인 회원가입 화면

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("SWAP", style: TextStyle(color: Color(0xFFE2FF00), fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Email", hintStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pwController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Password", hintStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await _auth.signInWithEmail(_emailController.text, _pwController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2FF00), minimumSize: const Size(double.infinity, 50)),
              child: const Text("로그인", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            // 🔥 회원가입 화면으로 이동하는 버튼 추가
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text("계정이 없으신가요? 회원가입", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}