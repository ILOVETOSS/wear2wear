import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'item_detail_screen.dart';

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

  // ✅ 초기 데이터 (테스트용)
  List<String> _recentSearches = ["나이키", "아디다스", "스투시"];

  final Color _pointColor = const Color(0xFFB3EB00);

  final List<Map<String, dynamic>> _trendingBrands = [
    {'name': 'NIKE', 'icon': Icons.bolt},
    {'name': 'ADIDAS', 'icon': Icons.api},
    {'name': 'STUSSY', 'icon': Icons.waves},
    {'name': 'SUPREME', 'icon': Icons.crop_square},
    {'name': 'ZARA', 'icon': Icons.text_fields},
  ];

  // ✅ 최근 검색어 저장 및 검색 실행 함수
  void _handleSearch(String query) {
    String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      // 리스트 업데이트
      _recentSearches.remove(trimmedQuery);
      _recentSearches.insert(0, trimmedQuery);
      if (_recentSearches.length > 10) _recentSearches.removeLast();

      _searchQuery = trimmedQuery;
      _searchController.text = trimmedQuery;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: _pointColor,
              decoration: InputDecoration(
                hintText: "브랜드 또는 아이템 검색",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: _pointColor, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white38, size: 16),
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
              onSubmitted: (val) => _handleSearch(val), // 엔터 치면 저장
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                  _isSearching = _searchQuery.isNotEmpty;
                });
              },
            ),
          ),
        ),
      ),
      // 검색창이 완전히 비어있을 때만 홈(최근 검색어)을 보여줌
      body: (_searchQuery.isEmpty) ? _buildSearchHome() : _buildSearchResults(),
    );
  }

  Widget _buildSearchHome() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ✅ 최근 검색어 섹션
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("최근 검색어",
                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              GestureDetector(
                onTap: () => setState(() => _recentSearches.clear()),
                child: const Text("전체 삭제", style: TextStyle(color: Colors.black38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recentSearches.map((keyword) => _buildRecentChip(keyword)).toList(),
          ),
          const SizedBox(height: 40),
        ],

        const Text("인기 브랜드",
            style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
              onTap: () => _handleSearch(b['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b['icon'], color: Colors.black, size: 28),
                    const SizedBox(height: 8),
                    Text(b['name'],
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _handleSearch(label),
            child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _recentSearches.remove(label)),
            child: const Icon(Icons.close, size: 14, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('clothes').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _pointColor));

        final results = snapshot.data!.where((item) {
          final title = item['title']?.toString().toLowerCase() ?? "";
          final brand = item['brand']?.toString().toLowerCase() ?? "";
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || brand.contains(query);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text("'$_searchQuery'에 대한 결과가 없습니다.",
                style: const TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 15,
            childAspectRatio: 0.72,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return GestureDetector(
              onTap: () {
                _handleSearch(_searchQuery); // 상세 페이지 갈 때도 현재 검색어 기록 저장
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          item['image_url'] ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.image_not_supported, color: Colors.black12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['brand']?.toUpperCase() ?? 'BRAND',
                              style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(item['title'] ?? 'ITEM',
                              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}