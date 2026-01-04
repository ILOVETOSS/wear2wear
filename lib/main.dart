import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 추가됨
import 'package:flutter/foundation.dart'; // 🔥 kIsWeb 사용을 위해 추가됨
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

  // GlobalKey를 통해 다른 화면(UploadScreen 등)에서 이 상태에 접근할 수 있게 합니다.
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
      key: MainNavigationScreen.navKey, // 🔥 navKey 연결
      body: _getSelectedScreen(currentTabIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF4D4D),
        unselectedItemColor: Colors.white54,
        currentIndex: currentTabIndex,
        onTap: changeTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '매치'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: '스왑'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: '업로드'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}