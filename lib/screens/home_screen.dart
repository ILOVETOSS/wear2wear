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
      // ✅ 전체 배경 화이트
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
                    color: Colors.black, // ✅ 블랙 포인트
                    fontWeight: FontWeight.w900,
                    fontSize: 22.sp,
                    letterSpacing: -0.5
                )
            ),
            Text(
              "-FIT",
              style: TextStyle(
                color: Colors.black, // ✅ 브랜드 컬러 대신 연한 블랙(회색빛)으로 세련되게 처리
                fontWeight: FontWeight.w900,
                fontSize: 22.sp,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
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
                      Text("인기 브랜드",
                          style: TextStyle(
                              color: Colors.black, // ✅ 블랙 텍스트
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp
                          )
                      ),
                      Text("전체보기",
                          style: TextStyle(
                              color: Colors.black38,
                              fontSize: 13.sp
                          )
                      ),
                    ],
                  ),
                ),
                const HomeBrandSection(),
                SizedBox(height: 20.h),
                // 카테고리와 피드 영역도 배경이 화이트인 상태에서 블랙 텍스트가 돋보이게 됩니다.
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