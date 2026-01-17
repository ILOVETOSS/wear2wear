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

  // ✅ 최근 검색어 리스트
  List<String> _recentSearches = ["나이키", "아디다스", "스투시"];

  final List<Map<String, dynamic>> _trendingBrands = [
    {'name': 'NIKE', 'icon': Icons.bolt},
    {'name': 'ADIDAS', 'icon': Icons.api},
    {'name': 'STUSSY', 'icon': Icons.waves},
    {'name': 'SUPREME', 'icon': Icons.crop_square},
    {'name': 'ZARA', 'icon': Icons.text_fields},
  ];

  // ✅ 검색어 저장 및 실행 핵심 기능
  void _handleSearch(String query) {
    String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      // 중복 제거 후 맨 앞으로 추가
      _recentSearches.remove(trimmedQuery);
      _recentSearches.insert(0, trimmedQuery);

      // 최대 10개 유지
      if (_recentSearches.length > 10) _recentSearches.removeLast();

      _searchQuery = trimmedQuery;
      _searchController.text = trimmedQuery;
      // 키보드 닫기
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.only(right: 24.w),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.w600),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: "검색어를 입력하세요",
              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 15.sp, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.black, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.cancel, color: Colors.black26, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                  });
                },
              )
                  : null,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            // ✅ 엔터 쳤을 때 검색 기록 저장
            onSubmitted: (val) => _handleSearch(val),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
          ),
        ),
      ),
      // 검색어가 비어있을 때는 홈, 있을 때는 결과창
      body: (_searchQuery.isEmpty) ? _buildSearchHome() : _buildSearchResults(),
    );
  }

  Widget _buildSearchHome() {
    return ListView(
      padding: EdgeInsets.all(24.w),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RECENT",
                  style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.w900)),
              GestureDetector(
                onTap: () => setState(() => _recentSearches.clear()),
                child: Text("Clear All", style: TextStyle(color: Colors.grey[400], fontSize: 12.sp)),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _recentSearches.map((keyword) => _buildRecentChip(keyword)).toList(),
          ),
          SizedBox(height: 48.h),
        ],

        Text("TRENDING BRAND",
            style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 20.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.0,
          ),
          itemCount: _trendingBrands.length,
          itemBuilder: (context, index) {
            final b = _trendingBrands[index];
            return GestureDetector(
              // ✅ 브랜드 클릭 시 검색 기록에 추가
              onTap: () => _handleSearch(b['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b['icon'], color: Colors.black, size: 24.sp),
                    SizedBox(height: 8.h),
                    Text(b['name'],
                        style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w800)),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            // ✅ 기존 기록 클릭 시 다시 검색
            onTap: () => _handleSearch(label),
            child: Text(label, style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => setState(() => _recentSearches.remove(label)),
            child: const Icon(Icons.close, size: 14, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('clothes').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

        final results = snapshot.data!.where((item) {
          final title = item['title']?.toString().toLowerCase() ?? "";
          final brand = item['brand']?.toString().toLowerCase() ?? "";
          final query = _searchQuery.toLowerCase();
          return title.contains(query) || brand.contains(query);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text("'$_searchQuery' 결과 없음",
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(20.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20.w,
            crossAxisSpacing: 15.w,
            childAspectRatio: 0.75,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return GestureDetector(
              onTap: () {
                // ✅ 아이템 상세 페이지 들어갈 때도 현재 검색어를 기록에 남김
                _handleSearch(_searchQuery);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          item['image_url'] ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: Colors.black12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['brand']?.toUpperCase() ?? 'BRAND',
                            style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4.h),
                        Text(item['title'] ?? 'ITEM',
                            style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.w500),
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