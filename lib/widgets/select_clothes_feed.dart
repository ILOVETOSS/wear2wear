import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart'; // supabase 전역 변수 참조
import 'home_item_card.dart'; // 🔥 GridviewItemCard 대신 실제 파일명인 home_item_card로 연결

class SelectClothesFeed extends StatefulWidget {
  const SelectClothesFeed({Key? key}) : super(key: key);

  @override
  State<SelectClothesFeed> createState() => _SelectClothesFeedState();
}

class _SelectClothesFeedState extends State<SelectClothesFeed> {

  // 1. 스왑 제안 로직 (기존 앱 기능 유지)
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
              content: Text("${targetItem['brand']}에 스왑 제안 완료!"),
              backgroundColor: const Color(0xFFE2FF00)
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("제안 전송 실패"), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  // 2. 내 옷장 선택 시트
  void _showMyClosetPicker(Map<String, dynamic> targetItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 500.h,
          child: Column(
            children: [
              const Text("제안할 내 옷 선택", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', supabase.auth.currentUser!.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("내 옷이 없습니다.", style: TextStyle(color: Colors.white54)));
                    }
                    final myItems = snapshot.data!;
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.8
                      ),
                      itemCount: myItems.length,
                      itemBuilder: (context, index) {
                        final item = myItems[index];
                        return GestureDetector(
                          onTap: () => _sendSwapProposal(item, targetItem),
                          child: Column(
                            children: [
                              Expanded(
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(item['image_url'], fit: BoxFit.cover)
                                  )
                              ),
                              SizedBox(height: 5.h),
                              Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1),
                            ],
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

  // 3. 상세 바텀시트
  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(item['image_url'] ?? '', fit: BoxFit.cover)
                    ),
                    SizedBox(height: 20.h),
                    Text(item['brand'] ?? 'BRAND', style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(item['title'] ?? 'ITEM', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15.h),
                    Text(item['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 상세 시트 닫기
                  _showMyClosetPicker(item); // 내 옷 선택 시트 열기
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2FF00),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: const Text("스왑 제안하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('clothes').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));

        // 내 옷이 아닌 것만 필터링
        final items = snapshot.data!.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.7
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => HomeItemCard( // 🔥 HomeItemCard로 이름 수정 완료
              item: items[index],
              onTap: () => _showItemDetail(items[index])
          ),
        );
      },
    );
  }
}