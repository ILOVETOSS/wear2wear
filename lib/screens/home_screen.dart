import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_slider.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_brand_section.dart'; // 🔥 브랜드 섹션 추가됨
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentAddress = placemarks[0].subLocality ?? placemarks[0].thoroughfare ?? "위치 미설정";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _currentAddress = "위치 확인 실패");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📍 위치 표시 헤더
            Padding(
              padding: EdgeInsets.only(left: 20.w, top: 10.h, bottom: 5.h),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: const Color(0xFFE2FF00), size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(_currentAddress, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ],
              ),
            ),
            const HomeSearchBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const HomeSlider(),
                  const HomeBrandSection(), // 🆕 브랜드 섹션 (이미지 적용)
                  SizedBox(height: 10.h),
                  const HomeCategories(),    // 🎯 추천/인기 등 칩
                  const SelectClothesFeed(), // 메인 피드
                  SizedBox(height: 100.h),   // 바텀바 간섭 방지
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}