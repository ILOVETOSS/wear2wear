import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // screenutil 추가
import 'profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedCat = "전체";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text("SWAP-FIT FEED",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5
            )),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Expanded(child: _buildMainFeed()),
        ],
      ),
    );
  }

  // ✅ 카테고리 필터 수정 (형광색 제거 및 검흰 통일)
  Widget _buildCategoryFilter() {
    final topics = ["전체", "스트릿", "미니멀", "빈티지", "캐주얼"];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: topics.map((e) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: ChoiceChip(
            label: Text(e),
            selected: _selectedCat == e,
            onSelected: (v) => setState(() => _selectedCat = e),
            // ✅ 선택 시 검정 배경, 미선택 시 연한 회색 배경
            selectedColor: Colors.black,
            backgroundColor: const Color(0xFFF5F5F5),
            labelStyle: TextStyle(
              // ✅ 선택 시 흰색 글자, 미선택 시 검정색 글자
                color: _selectedCat == e ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13.sp
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
            showCheckmark: false, // 체크마크 숨겨서 더 깔끔하게
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMainFeed() {
    final stream = _selectedCat == "전체"
        ? _supabase.from('community_posts').stream(primaryKey: ['id']).order('created_at')
        : _supabase.from('community_posts').stream(primaryKey: ['id']).eq('category', _selectedCat).order('created_at');

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("게시글이 없습니다.", style: TextStyle(color: Colors.grey)));
        }
        final posts = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostItem(posts[index]),
        );
      },
    );
  }

  Widget _buildPostItem(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFF5F5F5),
                child: Icon(Icons.person, color: Colors.black26)
            ),
            title: Text(p['publisher_name'] ?? 'USER',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            subtitle: Text(p['category'],
                style: const TextStyle(color: Colors.black45, fontSize: 12)), // 회색에서 진한 블랙계열로
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUid: p['publisher_id']))),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(p['image_url'], width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['content'] ?? "",
                    style: const TextStyle(color: Colors.black, fontSize: 15, height: 1.4)),
                const SizedBox(height: 12),
                // ✅ 포인트 컬러를 파란색에서 검정색으로 변경 (검흰 통일)
                const Text("교환 신청 가능",
                    style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(thickness: 1, color: Color(0xFFF5F5F5)),
        ],
      ),
    );
  }
}