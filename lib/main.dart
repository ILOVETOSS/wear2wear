import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart'; // 🔥 패키지 임포트
import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/swap_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

int currentTabIndex = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. 🔥 Firestore 무한 로딩 방지 설정 (특히 nam5 리전/웹 환경 필수)
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false, // 웹 브라우저 캐시 비활성화
      sslEnabled: true,          // 보안 연결 강제
    );
    print("🚀 Firestore 웹 최적화 설정 완료 (캐시 꺼짐)");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFE2FF00),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MainNavigationScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static final GlobalKey<_MainNavigationScreenState> navKey = GlobalKey<_MainNavigationScreenState>();

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 탭 변경 함수
  void changeTab(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0: return const HomeScreen();
      case 1: return const MatchScreen();
      case 2: return const SwapScreen();
      case 3: return const UploadScreen();
      case 4: return const ProfileScreen();
      default: return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: MainNavigationScreen.navKey,
      // 🔥 extendBody를 true로 설정해야 네비게이션 바의 잘린 곡선 부분이 배경색과 자연스럽게 연결됩니다.
      extendBody: true,
      body: _getSelectedScreen(currentTabIndex),
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
        color: Colors.white, // 바의 배경색
        buttonBackgroundColor: const Color(0xFFE2FF00), // 🔥 선택된 아이콘이 올라갔을 때의 배경 원 색상 (테마색 적용)
        backgroundColor: Colors.transparent, // 🔥 네비게이션 바 뒤로 보이는 배경을 투명하게 설정
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          changeTab(index);
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}