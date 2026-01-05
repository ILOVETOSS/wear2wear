import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../main.dart'; // supabase 사용을 위해 추가

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentAddress = "위치 확인 중...";
  int _selectedTabIndex = 0; // 0:추천, 1:인기, 2:방금전, 3:내사이즈
  final String _mySize = "XL"; // 유저 사이즈 예시 (나중에 유저 프로필에서 가져오기)

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // 1. GPS 주소 가져오기 로직 (유지)
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _currentAddress = placemarks[0].subLocality ?? placemarks[0].thoroughfare ?? "강남구";
      });
    } catch (e) {
      setState(() => _currentAddress = "위치 설정 필요");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 200,
        leading: TextButton.icon(
          onPressed: _determinePosition,
          icon: const Icon(Icons.my_location, color: Color(0xFFE2FF00), size: 18),
          label: Text(_currentAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickFilter(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // 🔥 MockData 대신 Supabase 실시간 스트림 사용
              stream: supabase.from('clothes').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
                }

                // 🔥 필터링 로직 적용
                List<Map<String, dynamic>> items = snapshot.data!;

                // 내 옷 제외 (필요한 경우)
                items = items.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList();

                if (_selectedTabIndex == 1) { // 인기탭 (좋아요 순)
                  items.sort((a, b) => (b['likes'] ?? 0).compareTo(a['likes'] ?? 0));
                } else if (_selectedTabIndex == 2) { // 방금전 (최신순)
                  items.sort((a, b) => b['created_at'].compareTo(a['created_at']));
                } else if (_selectedTabIndex == 3) { // 내 사이즈
                  items = items.where((i) => i['size'] == _mySize).toList();
                }

                if (items.isEmpty) {
                  return const Center(child: Text("표시할 아이템이 없습니다.", style: TextStyle(color: Colors.white24)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildClothingCard(items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter() {
    final filters = ["🎯 추천", "🔥 인기", "🆕 방금 전", "📏 내 사이즈"];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: filters.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: ChoiceChip(
            selected: _selectedTabIndex == i,
            onSelected: (_) => setState(() => _selectedTabIndex = i),
            backgroundColor: const Color(0xFF1A1A1A),
            selectedColor: const Color(0xFFE2FF00), // 형광 노랑으로 통일
            label: Text(filters[i],
                style: TextStyle(color: _selectedTabIndex == i ? Colors.black : Colors.white)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildClothingCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // 상세 페이지가 생기면 여기에서 이동 처리
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 450,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            // 그라데이션 오버레이
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            // 정보 표시
            Positioned(
              bottom: 25, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2FF00), // 빨간색에서 형광노랑으로 변경
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item['brand'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text("${item['size']} · ${item['category']}",
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("새로운 스타일을 발견하세요",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFE2FF00), size: 16),
                      Text(" ${item['likes'] ?? 0}", style: const TextStyle(color: Colors.white70)),
                      const Spacer(),
                      const Text("터치하여 상세보기 ➔",
                          style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}