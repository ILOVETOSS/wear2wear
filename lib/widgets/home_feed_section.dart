import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart'; // supabase 전역 객체
import 'home_item_card.dart';

class HomeFeedSection extends StatefulWidget {
  const HomeFeedSection({super.key});

  @override
  State<HomeFeedSection> createState() => _HomeFeedSectionState();
}

class _HomeFeedSectionState extends State<HomeFeedSection> {

  // [기존 로직] 스왑 제안 전송
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
          SnackBar(content: Text("${targetItem['brand']}에 스왑 제안을 보냈습니다!"), backgroundColor: const Color(0xFFE2FF00)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제안 실패"), backgroundColor: Colors.red));
    }
  }

  // [기존 로직] 내 옷 선택 팝업
  void _showMyClosetPicker(Map<String, dynamic> targetItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 550.h,
        child: Column(
          children: [
            const Text("제안할 내 옷 선택", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', supabase.auth.currentUser!.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final myItems = snapshot.data!;
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
                    itemCount: myItems.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _sendSwapProposal(myItems[index], targetItem),
                      child: Column(
                        children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(myItems[index]['image_url'], fit: BoxFit.cover))),
                          Text(myItems[index]['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  // [기존 로직] 상세 보기 바텀시트
  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(item['image_url'] ?? '', fit: BoxFit.cover)),
              const SizedBox(height: 20),
              Text(item['brand'] ?? 'BRAND', style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 16, fontWeight: FontWeight.bold)),
              Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(item['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); _showMyClosetPicker(item); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2FF00), minimumSize: const Size(double.infinity, 60)),
                child: const Text("스왑 제안하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.7),
          itemCount: items.length,
          itemBuilder: (context, index) => HomeItemCard(item: items[index], onTap: () => _showItemDetail(items[index])),
        );
      },
    );
  }
}