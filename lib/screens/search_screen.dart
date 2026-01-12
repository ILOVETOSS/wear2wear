import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart'; // 상세 페이지나 프로필 이동을 위해 필요

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  // 인기 브랜드 리스트 (검색 전 가이드용)
  final List<Map<String, dynamic>> _trendingBrands = [
    {'name': 'NIKE', 'icon': Icons.bolt},
    {'name': 'ADIDAS', 'icon': Icons.api},
    {'name': 'STUSSY', 'icon': Icons.waves},
    {'name': 'SUPREME', 'icon': Icons.crop_square},
    {'name': 'ZARA', 'icon': Icons.text_fields},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 다크 테마 유지
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "브랜드 또는 아이템 검색",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFE2FF00), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white24, size: 16),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                    _isSearching = false;
                  });
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            // ✅ 한 글자만 쳐도 바로 필터링되도록 설정
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
                _isSearching = _searchQuery.isNotEmpty;
              });
            },
          ),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildSearchHome(),
    );
  }

  // 1. 검색 전: 인기 브랜드 가이드
  Widget _buildSearchHome() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("인기 브랜드",
            style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15,
          ),
          itemCount: _trendingBrands.length,
          itemBuilder: (context, index) {
            final b = _trendingBrands[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.text = b['name'];
                  _searchQuery = b['name'];
                  _isSearching = true;
                });
              },
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b['icon'], color: const Color(0xFFE2FF00), size: 28),
                    const SizedBox(height: 8),
                    Text(b['name'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. 검색 결과: 실시간 필터링 (아이템만 표시)
  Widget _buildSearchResults() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // 'clothes' 테이블에서 실시간으로 데이터 가져오기
      stream: _supabase.from('clothes').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));

        // ✅ 한 글자라도 포함되어 있으면 리스트에 노출 (대소문자 구분 없음)
        final results = snapshot.data!.where((item) {
          final title = item['title'].toString().toLowerCase();
          final brand = item['brand'].toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || brand.contains(query);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text("'$_searchQuery'에 대한 검색 결과가 없습니다.",
                style: const TextStyle(color: Colors.white24)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.75,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        item['image_url'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => const Icon(Icons.image_not_supported, color: Colors.white10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['brand'] ?? 'BRAND',
                            style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item['title'] ?? 'ITEM',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}