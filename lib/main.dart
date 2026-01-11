import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/search_screen.dart';
// 화면 파일들 import
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';   // 기존 하트/매치 기능을 채팅 탭에서 사용
import 'screens/swap_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lfwotjcrjqoexkhuuspl.supabase.co',
    anonKey: 'sb_publishable_UYYDiJTfiHCBvBAzkgnnig_gq2y7lU0',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            primaryColor: const Color(0xFFE2FF00),
          ),
          home: child,
        );
      },
      child: supabase.auth.currentSession == null
          ? const LoginScreen()
          : const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static final GlobalKey<MainNavigationScreenState> navKey = GlobalKey<MainNavigationScreenState>();

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentTabIndex = 0;

  // 🔥 요청하신 구성: [홈, 검색, 스왑, 채팅(하트기능), 마이]
  final List<Widget> _screens = [
    const HomeScreen(),    // 0: 홈
    const SearchScreen(),  // 🔥 1: 탐색(검색) 자리에 방금 만든 SearchScreen 연결
    const SwapScreen(),    // 2: 스왑
    const MatchScreen(),   // 3: 채팅 (하트/매치 기능)
    const ProfileScreen(), // 4: 마이
  ];

  void changeTab(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

  void _openUploadPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const UploadScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 스왑 화면(index 2)일 때는 업로드 버튼 숨김
    bool showUploadButton = currentTabIndex != 2;

    return Scaffold(
      key: MainNavigationScreen.navKey,
      extendBody: true,
      body: _screens[currentTabIndex],

      // 🔥 '+ 업로드' 버튼 (위치 하향 조정)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: showUploadButton
          ? Padding(
        padding: EdgeInsets.only(bottom: 60.h), // 바텀바에 더 가깝게 내림
        child: FloatingActionButton.extended(
          onPressed: _openUploadPage,
          backgroundColor: Colors.black,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
          label: Text("업로드", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          icon: Icon(Icons.add, color: Colors.white, size: 20.sp),
        ),
      )
          : null,

      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 65.0,
        items: const <Widget>[
          Icon(Icons.home_filled, size: 28, color: Colors.black),          // 0: 홈
          Icon(Icons.search, size: 28, color: Colors.black),               // 1: 검색
          Icon(Icons.swap_horiz_rounded, size: 32, color: Colors.black),    // 2: 스왑
          Icon(Icons.chat_bubble_outline, size: 26, color: Colors.black),    // 3: 채팅 (기존 하트 자리)
          Icon(Icons.person_outline, size: 28, color: Colors.black),       // 4: 마이
        ],
        color: Colors.white,
        buttonBackgroundColor: const Color(0xFFE2FF00),
        backgroundColor: Colors.transparent,
        onTap: (index) => changeTab(index),
      ),
    );
  }
}