import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'search_screen.dart';
import '../widgets/home_slider.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_brand_section.dart';
import '../widgets/select_clothes_feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
                "SWAP",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 22.sp,
                    letterSpacing: -0.5
                )
            ),
            // ✅ FIT 부분 가시성 개선
            Stack(
              children: [
                // 1. 글자 뒤에 아주 얇은 외곽선 효과를 주어 경계를 명확히 함
                Text(
                  "-FIT",
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1.2
                      ..color = Colors.black.withOpacity(0.1), // 미세한 테두리
                  ),
                ),
                // 2. 메인 글자색 (기존보다 약간 더 진한 라임색으로 조정)
                Text(
                  "-FIT",
                  style: TextStyle(
                    color: const Color(0xFFB3EB00), // 가시성을 위해 채도를 약간 높인 라임
                    fontWeight: FontWeight.w900,
                    fontSize: 22.sp,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.notifications_none, color: Colors.black, size: 26.sp),
              onPressed: () {}
          ),
          IconButton(
              icon: Icon(Icons.search, color: Colors.black, size: 26.sp),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen())
              )
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const HomeSlider(),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("인기 브랜드", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                      Text("전체보기", style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                    ],
                  ),
                ),
                const HomeBrandSection(),
                SizedBox(height: 20.h),
                const HomeCategories(),
                const SelectClothesFeed(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}