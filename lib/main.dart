import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/activity_screen.dart'; // ✅ match_screen → activity_screen
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
    const ActivityScreen(), // ✅ MatchScreen → ActivityScreen
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
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            child: Icon(Icons.add, size: 28.sp),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTabIndex,
          onTap: changeTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 10.sp,
          unselectedFontSize: 10.sp,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home_filled, "HOME"),
            _buildNavItem(Icons.article_outlined, Icons.article, "COMMUNITY"),
            _buildNavItem(Icons.swap_horiz_rounded, Icons.swap_horiz_rounded, "SWAP"),
            _buildNavItem(Icons.notifications_active_outlined, Icons.notifications_active, "ACTIVITY"), // ✅ CHAT → ACTIVITY
            _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, "MY"),
          ],
        ),
      ),
    );
  }

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