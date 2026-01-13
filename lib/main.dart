import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'theme/app_theme.dart'; // 테마 임포트 추가
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/swap_screen.dart';
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
          theme: AppTheme.blackWhiteTheme, // ✅ 단일화된 블랙&화이트 테마 적용
          title: 'SWAP-FIT',
          home: supabase.auth.currentSession == null
              ? const LoginScreen()
              : const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  static final GlobalKey<MainNavigationScreenState> navKey = GlobalKey<MainNavigationScreenState>();
  const MainNavigationScreen({super.key});

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentTabIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CommunityScreen(),
    const SwapScreen(),
    const MatchScreen(),
    const ProfileScreen(),
  ];

  void changeTab(int index) {
    setState(() {
      currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: MainNavigationScreen.navKey,
      extendBody: true,
      body: _screens[currentTabIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 60.0,
        items: [
          _buildNavItem(Icons.home_filled, "HOME", 0),
          _buildNavItem(Icons.dynamic_feed_rounded, "COMMUNITY", 1),
          _buildNavItem(Icons.swap_horiz_rounded, "SWAP", 2),
          _buildNavItem(Icons.chat_bubble_rounded, "CHAT", 3),
          _buildNavItem(Icons.person_rounded, "MY", 4),
        ],
        color: Colors.black,
        buttonBackgroundColor: Colors.black,
        backgroundColor: Colors.transparent,
        onTap: (index) => changeTab(index),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = currentTabIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: isSelected ? Colors.white : Colors.grey),
        if (!isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
