import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../data/mock_data.dart';
import '../models/clothing_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentAddress = "위치 확인 중...";
  int _selectedTabIndex = 0; // 0:추천, 1:인기, 2:방금전, 3:내사이즈
  final String _mySize = "XL"; // 유저 사이즈 예시

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // GPS로 실제 주소 가져오기
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

  // 필터링 로직
  List<ClothingItem> _getFilteredItems() {
    List<ClothingItem> items = List.from(mockData);

    if (_selectedTabIndex == 1) { // 인기탭
      items.sort((a, b) => b.likes.compareTo(a.likes));
    } else if (_selectedTabIndex == 2) { // 방금전
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedTabIndex == 3) { // 내 사이즈
      items = items.where((item) => item.size == _mySize).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 150,
        leading: TextButton.icon(
          onPressed: _determinePosition,
          icon: const Icon(Icons.my_location, color: Color(0xFFFF4D4D), size: 18),
          label: Text(_currentAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Column(
        children: [
          _buildQuickFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) => _buildClothingCard(filteredItems[index]),
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
            backgroundColor: Colors.grey[900],
            selectedColor: const Color(0xFFFF4D4D),
            label: Text(filters[i], style: const TextStyle(color: Colors.white)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildClothingCard(ClothingItem item) {
    return GestureDetector(
      onTap: () {
        // 터치 시 바로 스왑 신청 기능 실행
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item.brand} 교환 신청 페이지로 이동합니다.")),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 450,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
            Positioned(
              bottom: 25, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFFF4D4D), borderRadius: BorderRadius.circular(8)),
                        child: Text(item.brand, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Text("${item.size} · ${item.category}", style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("${item.ownerName}님의 옷", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFF4D4D), size: 16),
                      Text(" ${item.likes}", style: const TextStyle(color: Colors.white70)),
                      const Spacer(),
                      const Text("터치하여 스왑 ➔", style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.bold)),
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