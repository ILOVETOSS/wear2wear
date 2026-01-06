import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentAddress = "위치 확인 중...";
  int _selectedTabIndex = 0; // 0:추천, 1:인기, 2:방금전, 3:내사이즈
  final String _mySize = "XL";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // 1. GPS 위치 정보 가져오기
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
        _currentAddress = placemarks[0].subLocality ?? placemarks[0].thoroughfare ?? "강남구";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _currentAddress = "위치 설정 필요");
    }
  }

  // ---------------------------------------------------------
  // 🆕 2. 실제 스왑 제안 데이터베이스 전송 함수
  // ---------------------------------------------------------
  Future<void> _sendSwapProposal(Map<String, dynamic> myItem, Map<String, dynamic> targetItem) async {
    try {
      await supabase.from('swaps').insert({
        'from_user_id': supabase.auth.currentUser!.id,
        'to_user_id': targetItem['user_id'],
        'my_item_id': myItem['id'],
        'target_item_id': targetItem['id'],
      });

      if (mounted) {
        Navigator.pop(context); // 내 옷 선택 시트 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${targetItem['brand']}에 대한 스왑 제안을 보냈습니다!"),
            backgroundColor: const Color(0xFFE2FF00),
          ),
        );
      }
    } catch (e) {
      debugPrint("🔥🔥 스왑 제안 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("제안 전송에 실패했습니다. 다시 시도해 주세요."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ---------------------------------------------------------
  // 🆕 3. 내 옷 선택 팝업 시트 (스왑할 내 아이템 고르기)
  // ---------------------------------------------------------
  void _showMyClosetPicker(Map<String, dynamic> targetItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 550,
          child: Column(
            children: [
              const Text("교환 제안할 내 옷 선택",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  // 내 아이템만 필터링해서 가져옴
                  stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', supabase.auth.currentUser!.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("등록된 내 옷이 없습니다.\n프로필에서 옷을 먼저 등록해 주세요.",
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)));
                    }

                    final myItems = snapshot.data!;
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8
                      ),
                      itemCount: myItems.length,
                      itemBuilder: (context, index) {
                        final item = myItems[index];
                        return GestureDetector(
                          onTap: () => _sendSwapProposal(item, targetItem), // 클릭 시 제안 전송
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(item['image_url'], fit: BoxFit.cover, width: double.infinity),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(item['title'] ?? '제목 없음',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // 4. 아이템 상세 보기 바텀 시트
  // ---------------------------------------------------------
  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(item['image_url'] ?? '', width: double.infinity, height: 350, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['brand'] ?? 'BRAND',
                              style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                            child: Text(item['condition'] ?? '상태 미지정', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(item['title'] ?? '멋진 아이템', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12),
                      const Text("상세 설명", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 10),
                      Text(item['description'] ?? '등록된 설명이 없습니다.', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
                      const SizedBox(height: 30),

                      // 상대방 프로필 정보
                      FutureBuilder<Map<String, dynamic>?>(
                        future: supabase.from('profiles').select().eq('id', item['user_id'] ?? '').maybeSingle(),
                        builder: (context, snap) {
                          final profile = snap.data;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile!['avatar_url']) : null,
                                  child: profile?['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white24) : null,
                                ),
                                const SizedBox(width: 12),
                                Text(profile?['email']?.split('@')[0] ?? 'Swapper', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // 하단 고정 버튼 영역
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 상세 시트 닫기
                    _showMyClosetPicker(item); // 🔥 내 옷장 선택 시트 열기 호출
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2FF00),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("스왑 제안하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        actions: [IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {})],
      ),
      body: Column(
        children: [
          _buildQuickFilter(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('clothes').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
                }
                final items = snapshot.data ?? [];
                // 내 옷은 피드에서 제외
                final displayItems = items.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) => _buildClothingCard(displayItems[index]),
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
            selectedColor: const Color(0xFFE2FF00),
            label: Text(filters[i], style: TextStyle(color: _selectedTabIndex == i ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildClothingCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(item['image_url'] ?? ''), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.85)]),
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
                        decoration: BoxDecoration(color: const Color(0xFFE2FF00), borderRadius: BorderRadius.circular(8)),
                        child: Text(item['brand'] ?? 'BRAND', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text("${item['size']} · ${item['category'] ?? '미정'}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item['title'] ?? "스타일리시한 아이템", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: Color(0xFFE2FF00), size: 18),
                      Spacer(),
                      Text("터치하여 상세보기 ➔", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold, fontSize: 14)),
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