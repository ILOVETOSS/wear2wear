import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/swap_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/upload_screen.dart';

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
          theme: AppTheme.blackWhiteTheme,
          title: 'SWAP-FIT',
          home: const SplashScreen(),
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
      backgroundColor: Colors.white,
      body: _screens[currentTabIndex],

      // ✅ FloatingActionButton 위치 및 디자인 수정
      floatingActionButton: currentTabIndex == 2
          ? null
          : Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: SizedBox(
          width: 50.w,
          height: 50.w,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadScreen()),
              );
            },
            backgroundColor: Colors.black, // 버튼은 검은색으로 포인트
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            child: Icon(Icons.add, size: 28.sp),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ✅ 수정된 네비게이션 바 디자인
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.0), // 상단 구분선
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTabIndex,
          onTap: changeTab,
          type: BottomNavigationBarType.fixed, // 아이템 간격 고정
          backgroundColor: Colors.white, // 배경 흰색
          selectedItemColor: Colors.black, // 클릭 시 검은색
          unselectedItemColor: Colors.grey.shade400, // 미클릭 시 회색
          selectedFontSize: 10.sp,
          unselectedFontSize: 10.sp,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0, // Container Border를 사용하므로 기본 그림자 제거
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home_filled, "HOME"),
            _buildNavItem(Icons.article_outlined, Icons.article, "COMMUNITY"),
            _buildNavItem(Icons.swap_horiz_rounded, Icons.swap_horiz_rounded, "SWAP"),
            _buildNavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "CHAT"),
            _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, "MY"),
          ],
        ),
      ),
    );
  }

  // ✅ 네비게이션 아이템 빌더 함수
  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Icon(icon, size: 24.sp),
      ),
      activeIcon: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Icon(activeIcon, size: 24.sp),
      ),
      label: label,
    );
  }
}