import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import 'home_item_card.dart';

class HomeFeedSection extends StatefulWidget {
  const HomeFeedSection({super.key});

  @override
  State<HomeFeedSection> createState() => _HomeFeedSectionState();
}

class _HomeFeedSectionState extends State<HomeFeedSection> {

  // ✅ 스왑 제안 전송 (스낵바 스타일 수정)
  Future<void> _sendSwapProposal(Map<String, dynamic> myItem, Map<String, dynamic> targetItem) async {
    try {
      await supabase.from('swaps').insert({
        'from_user_id': supabase.auth.currentUser!.id,
        'to_user_id': targetItem['user_id'],
        'my_item_id': myItem['id'],
        'target_item_id': targetItem['id'],
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${targetItem['brand']}에 스왑 제안을 보냈습니다!",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black, // ✅ 검정 배경으로 변경
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제안 실패"), backgroundColor: Colors.red));
    }
  }

  // ✅ 내 옷 선택 팝업 (하양 배경 / 검정 텍스트)
  void _showMyClosetPicker(Map<String, dynamic> targetItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // ✅ 하양 배경
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 550.h,
        child: Column(
          children: [
            const Text("제안할 내 옷 선택",
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)), // ✅ 검정 텍스트
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', supabase.auth.currentUser!.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                  final myItems = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
                    itemCount: myItems.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _sendSwapProposal(myItems[index], targetItem),
                      child: Column(
                        children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(myItems[index]['image_url'], fit: BoxFit.cover))),
                          const SizedBox(height: 8),
                          Text(myItems[index]['title'] ?? '',
                              style: const TextStyle(color: Colors.black, fontSize: 12)), // ✅ 검정 텍스트
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 상세 보기 바텀시트 (하양 배경 / 검정 포인트)
  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
            color: Colors.white, // ✅ 하양 배경
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(item['image_url'] ?? '', fit: BoxFit.cover)),
              const SizedBox(height: 20),
              // ✅ 브랜드명 (검정색 강조)
              Text(item['brand'] ?? 'BRAND',
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              Text(item['title'] ?? '',
                  style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(item['description'] ?? '',
                  style: const TextStyle(color: Colors.black54, fontSize: 15)),
              const SizedBox(height: 30),
              // ✅ 버튼 (검정 배경 / 흰 글자)
              ElevatedButton(
                onPressed: () { Navigator.pop(context); _showMyClosetPicker(item); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // ✅ 검정 포인트
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("스왑 제안하기",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('clothes').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
        final items = snapshot.data!.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => HomeItemCard(item: items[index], onTap: () => _showItemDetail(items[index])),
        );
      },
    );
  }
}