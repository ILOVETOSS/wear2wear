import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// 화면 파일들 import
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: supabase.auth.currentSession == null
          ? const LoginScreen()
          : const MainNavigationScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  // ✅ 외부(UploadScreen 등)에서 접근 가능하도록 GlobalKey 설정
  static final GlobalKey<MainNavigationScreenState> navKey = GlobalKey<MainNavigationScreenState>();

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentTabIndex = 0;

  // ✅ 외부에서 탭을 변경할 수 있도록 public 함수로 유지
  void changeTab(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

  // 하단 탭에 연결될 화면들 (총 5개)
  final List<Widget> _screens = [
    const HomeScreen(),      // 0. 홈
    const MatchScreen(),     // 1. 활동 (받은 요청 & 채팅 통합)
    const SwapScreen(),      // 2. 스와이프 매칭
    const UploadScreen(),    // 3. 업로드
    const ProfileScreen(),   // 4. 프로필
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: MainNavigationScreen.navKey,
      extendBody: true,
      body: _screens[currentTabIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.black),
          Icon(Icons.favorite, size: 30, color: Colors.black), // 하트 탭: 요청 & 채팅
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