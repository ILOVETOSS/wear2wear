import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'community_screen.dart'; // ✅ SearchScreen 대신 CommunityScreen 임포트
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
  String _currentAddress = "위치 확인 중...";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _currentAddress = "GPS를 켜주세요");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => _currentAddress = "위치 권한 거부됨");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        setState(() {
          _currentAddress = placemarks[0].subLocality ?? placemarks[0].thoroughfare ?? "위치 미설정";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _currentAddress = "위치 확인 실패");
    }
  }

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
            // ✅ 브랜드명 SWAP-FIT으로 변경 및 스타일 조정
            Text("SWAP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22.sp)),
            Text("-FIT", style: TextStyle(color: const Color(0xFFE2FF00), fontWeight: FontWeight.w900, fontSize: 22.sp)),
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.notifications_none, color: Colors.black, size: 26.sp),
              onPressed: () {}
          ),
          IconButton(
              icon: Icon(Icons.search, color: Colors.black, size: 26.sp),
              // ✅ 에러 수정: SearchScreen() -> CommunityScreen()으로 변경
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityScreen())
              )
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.black, size: 14.sp),
                SizedBox(width: 4.w),
                Text(_currentAddress, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 12.sp)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const HomeSlider(),

                // ✅ 브랜드 섹션
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
                SizedBox(height: 100.h), // 하단 네비게이션 바 고려하여 여백 확보
              ],
            ),
          ),
        ],
      ),
    );
  }
}