import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // 3초 후 로그인 화면으로 이동
    Timer(const Duration(seconds: 3), () {
      if (mounted) { // mounted 체크 추가 (메모리 누수 방지)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고
            const Icon(Icons.swap_horiz, size: 100, color: Color(0xFFFF4D4D)),
            const SizedBox(height: 20),
            const Text(
              "CLOSWAP",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900, // 🔥 FontWeight.black 대신 w900 사용
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "가치 있는 옷의 새로운 순환",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4D4D)),
            ),
          ],
        ),
      ),
    );
  }
}