import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/swap_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final SwapService _swapService = SwapService();
  final CardSwiperController _controller = CardSwiperController();
  List<Map<String, dynamic>> myClothes = [];

  // ✅ 공통 포인트 컬러 (네온 라임)
  final Color _pointColor = const Color(0xFFB3EB00);

  @override
  void initState() {
    super.initState();
    _loadMyClothes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMyClothes() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('clothes')
          .select('id, brand, title, image_url, user_id')
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        myClothes = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("내 옷 불러오기 에러: $e");
    }
  }

  void _showMyItemPicker(Map<String, dynamic> targetItem) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("제안할 내 옷 선택",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: myClothes.isEmpty
                  ? const Center(
                  child: Text("등록된 옷이 없습니다.",
                      style: TextStyle(color: Colors.black38)))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: myClothes.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendRequest(targetItem, myClothes[index]);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black12),
                      image: DecorationImage(
                          image: NetworkImage(myClothes[index]['image_url']),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(
      Map<String, dynamic> targetItem, Map<String, dynamic> myItem) async {
    try {
      await _swapService.sendSwapRequest(
        receiverId: targetItem['user_id'],
        receiverClothesId: targetItem['id'],
        myClothesId: myItem['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("교환 요청 성공! ❤️", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: _pointColor,
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("실패: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("SWAP",
            style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('clothes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("에러: ${snapshot.error}"));

          final items = snapshot.data
              ?.where((i) => i['user_id'] != supabase.auth.currentUser?.id)
              .toList() ?? [];

          if (items.isEmpty) {
            return const Center(
                child: Text("교환할 옷이 없습니다.", style: TextStyle(color: Colors.black38)));
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: items.length,
                    numberOfCardsDisplayed: items.length > 1 ? 2 : 1,
                    backCardOffset: const Offset(0, 15),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    onSwipe: (prev, curr, dir) {
                      if (dir == CardSwiperDirection.right) {
                        _showMyItemPicker(items[prev]);
                      }
                      return true;
                    },
                    cardBuilder: (context, index, x, y) => _buildCard(items[index]),
                  ),
                ),
                _buildButtons(),
                const SizedBox(height: 110),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned.fill(
                child: Image.network(item['image_url'], fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, color: Colors.grey)))),
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.6, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7)
                            ])))),
            Positioned(
                bottom: 25,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['brand']?.toUpperCase() ?? 'UNKNOWN',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    Text(item['title'] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  // ✅ 하단 버튼 영역 (기존 스타일 유지)
  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 기존의 테두리 형태 X 버튼
        _circleBtn(Icons.close, Colors.red, () => _controller.swipe(CardSwiperDirection.left)),
        const SizedBox(width: 40),
        // 기존의 테두리 형태 하트 버튼 (라임색 적용)
        _circleBtn(Icons.favorite, _pointColor, () => _controller.swipe(CardSwiperDirection.right)),
      ],
    );
  }

  // ✅ 기존의 테두리 형태 버튼 위젯
  Widget _circleBtn(IconData icon, Color col, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: col, width: 2)), // 기존의 테두리 방식
          child: Icon(icon, color: col, size: 35)),
    );
  }
}