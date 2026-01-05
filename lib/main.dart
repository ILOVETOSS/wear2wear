import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// 화면 파일들 import (경로가 다르면 수정하세요)
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/swap_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Supabase 설정
  await Supabase.initialize(
    url: 'https://lfwotjcrjqoexkhuuspl.supabase.co',
    anonKey: 'sb_publishable_UYYDiJTfiHCBvBAzkgnnig_gq2y7lU0',
  );

  runApp(const MyApp());
}

// 전역 supabase 클라이언트
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clothes Swap',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFE2FF00),
      ),
      // 현재 세션 여부에 따라 첫 화면 결정
      home: supabase.auth.currentSession == null
          ? const LoginScreen()
          : const MainNavigationScreen(),

      // ✅ 로그인 화면에서 Navigator.pushReplacementNamed(context, '/home')를 쓸 수 있게 경로 등록
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  // ✅ UploadScreen 등에서 탭을 이동시킬 때 사용할 키
  static final GlobalKey<MainNavigationScreenState> navKey = GlobalKey<MainNavigationScreenState>();

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentTabIndex = 0;

  // 탭 변경 함수
  void changeTab(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

  // 하단 탭에 연결될 화면들
  final List<Widget> _screens = [
    const HomeScreen(),
    const MatchScreen(),
    const SwapScreen(),
    const UploadScreen(),
    const ProfileScreen(), // 여기에 내 옷 목록이 뜨도록 설계됨
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: MainNavigationScreen.navKey,
      extendBody: true, // 내비게이션 바 뒤로 배경이 보이게 함
      body: _screens[currentTabIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.black),
          Icon(Icons.favorite, size: 30, color: Colors.black),
          Icon(Icons.swap_horiz, size: 30, color: Colors.black),
          Icon(Icons.add_box, size: 30, color: Colors.black),
          Icon(Icons.person, size: 30, color: Colors.black),
        ],
        color: Colors.white,
        buttonBackgroundColor: const Color(0xFFE2FF00),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          changeTab(index);
        },
      ),
    );
  }
}