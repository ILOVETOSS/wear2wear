import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart'; // supabase 전역 변수 참조
import 'home_item_card.dart';

import '../screens/item_detail_screen.dart';

class SelectClothesFeed extends StatefulWidget {
  const SelectClothesFeed({Key? key}) : super(key: key);

  @override
  State<SelectClothesFeed> createState() => _SelectClothesFeedState();
}

class _SelectClothesFeedState extends State<SelectClothesFeed> {

  // 1. 스왑 제안 로직 (유지)
  Future<void> _sendSwapProposal(Map<String, dynamic> myItem, Map<String, dynamic> targetItem) async {
    try {
      await supabase.from('swaps').insert({
        'from_user_id': supabase.auth.currentUser!.id,
        'to_user_id': targetItem['user_id'],
        'my_item_id': myItem['id'],
        'target_item_id': targetItem['id'],
        'status': 'pending', // 상태값 추가
      });
      if (mounted) {
        Navigator.pop(context);
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

  // 2. 내 옷장 선택 시트 (유지)
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

  // 🔥 3. 상세 페이지로 이동 기능 (바텀시트 대신 페이지 이동으로 교체)
  void _navigateToDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // 최신순 정렬 추가
      stream: supabase.from('clothes').stream(primaryKey: ['id']).order('created_at'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));

        // 내 옷이 아닌 것만 필터링 (남의 옷만 홈에 노출)
        final items = snapshot.data!.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.72 // 카드 비율 최적화
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return HomeItemCard(
              item: item,
              onTap: () => _navigateToDetail(item), // 클릭 시 상세 페이지(정품/거래방식 포함)로 이동
            );
          },
        );
      },
    );
  }
}