import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // ✅ MainNavigationScreen을 쓰기 위해 main.dart 임포트
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      final session = Supabase.instance.client.auth.currentSession;

      if (!mounted) return;

      // ✅ 여기서 MainNavigationScreen()으로 보내야 하단바가 생깁니다.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => session == null
              ? const LoginScreen()
              : const MainNavigationScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("SWAP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 40)),
                Text("-FIT", style: TextStyle(
                  color: const Color(0xFFB3EB00),
                  fontWeight: FontWeight.w900,
                  fontSize: 40,
                  shadows: [Shadow(offset: const Offset(1, 1), color: Colors.black.withOpacity(0.1), blurRadius: 2.0)],
                )),
              ],
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Color(0xFFB3EB00)),
          ],
        ),
      ),
    );
  }
}