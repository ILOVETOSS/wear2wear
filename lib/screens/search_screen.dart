import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'brand_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  List<Map<String, dynamic>> _popularKeywords = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // 인기 검색어 가져오기
      final popularData = await _supabase
          .from('popular_keywords')
          .select()
          .order('search_count', ascending: false)
          .limit(10);

      // 최근 검색어 가져오기
      List<Map<String, dynamic>> recentData = [];
      if (userId != null) {
        recentData = await _supabase
            .from('recent_searches')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10);
      }

      setState(() {
        _popularKeywords = List<Map<String, dynamic>>.from(popularData);
        _recentSearches = List<Map<String, dynamic>>.from(recentData);
      });
    } catch (e) {
      debugPrint("데이터 로드 에러: $e");
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isTyping = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isTyping = true);

    try {
      final data = await _supabase
          .from('brands')
          .select()
          .ilike('name', '%$query%')
          .limit(15);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("검색 에러: $e");
    }
  }

  // ✅ 검색 상태 완전 초기화 함수
  void _resetSearch() {
    _searchController.clear();
    setState(() {
      _isTyping = false;
      _searchResults = [];
    });
  }

  Future<void> _deleteRecentSearch(String id) async {
    await _supabase.from('recent_searches').delete().eq('id', id);
    _fetchInitialData();
  }

  Future<void> _clearAllRecent() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('recent_searches').delete().eq('user_id', userId);
      _fetchInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: _isTyping ? _buildAutoCompleteList() : _buildDefaultUI(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "브랜드, 상품, 프로필 등",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                // ✅ 검색 중일 때만 X 버튼 표시 및 클릭 시 리셋
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.grey),
                  onPressed: _resetSearch,
                )
                    : null,
              ),
            ),
          ),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.black))
        ],
      ),
    );
  }

  Widget _buildAutoCompleteList() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final brand = _searchResults[index];
        final String? logoUrl = brand['logo_url'];

        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4.h),
          leading: CircleAvatar(
            backgroundColor: Colors.grey[100],
            // ✅ 이미지 에러 핸들링: URL이 없거나 로드 실패 시 아이콘 표시
            child: (logoUrl == null || logoUrl.isEmpty)
                ? const Icon(Icons.business, color: Colors.grey)
                : ClipOval(
              child: Image.network(
                logoUrl,
                fit: BoxFit.cover,
                width: 40.r,
                height: 40.r,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image_outlined, color: Colors.grey);
                },
              ),
            ),
          ),
          title: Text(brand['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          subtitle: Text("관심 ${brand['follower_count'] ?? 0}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BrandDetailScreen(brand: brand)),
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultUI() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          _buildSectionTitle("최근 검색어", "지우기", onSubTap: _clearAllRecent),
          SizedBox(height: 10.h),
          _recentSearches.isEmpty
              ? Text("최근 검색어가 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 12.sp))
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentSearches.map((item) => _buildRecentItem(item)).toList(),
            ),
          ),
          SizedBox(height: 30.h),
          _buildSectionTitle("지금 가장 뜨는 이슈", null),
          SizedBox(height: 10.h),
          _buildIssueChips(),
          SizedBox(height: 30.h),
          _buildSectionTitle("인기 검색어", "01.11 23:00 기준"),
          SizedBox(height: 10.h),
          _buildPopularList(),
        ],
      ),
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              _searchController.text = item['keyword'];
              _onSearchChanged(item['keyword']);
            },
            child: Text(item['keyword'], style: TextStyle(color: Colors.black, fontSize: 13.sp)),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => _deleteRecentSearch(item['id'].toString()),
            child: const Icon(Icons.close, size: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueChips() {
    List<String> issues = ["연프 착장", "연봉30억 직장인의 옷", "트렌드 신발", "지금이 호카 매수 타이밍?", "겨울 여행 룩"];
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: issues.map((e) => ActionChip(
        backgroundColor: Colors.grey[100],
        label: Text(e, style: TextStyle(color: Colors.black, fontSize: 12.sp)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r), side: BorderSide.none),
        onPressed: () {
          _searchController.text = e;
          _onSearchChanged(e);
        },
      )).toList(),
    );
  }

  Widget _buildPopularList() {
    if (_popularKeywords.isEmpty) return const Text("인기 검색어가 없습니다.", style: TextStyle(color: Colors.grey));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRankColumn(_popularKeywords, 0)),
        SizedBox(width: 20.w),
        Expanded(child: _buildRankColumn(_popularKeywords, 5)),
      ],
    );
  }

  Widget _buildRankColumn(List<Map<String, dynamic>> list, int start) {
    return Column(
      children: List.generate(5, (index) {
        int realIndex = start + index;
        if (realIndex >= list.length) return const SizedBox();
        final item = list[realIndex];
        return InkWell( // 터치 피드백을 위해 InkWell 사용
          onTap: () {
            _searchController.text = item['keyword'];
            _onSearchChanged(item['keyword']);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Text("${realIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                SizedBox(width: 10.w),
                Expanded(child: Text(item['keyword'], style: TextStyle(color: Colors.black, fontSize: 13.sp))),
                if (item['is_new'] == true)
                  const Text("NEW", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, String? sub, {VoidCallback? onSubTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: Colors.black)),
        if (sub != null)
          GestureDetector(
              onTap: onSubTap,
              child: Text(sub, style: TextStyle(color: Colors.grey, fontSize: 12.sp))
          ),
      ],
    );
  }
}