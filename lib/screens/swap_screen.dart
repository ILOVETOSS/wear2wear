import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMyClothes();
  }

  // 메모리 릭 방지: dispose 시 컨트롤러 해제
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadMyClothes() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 컬럼명을 brand로 명시하여 brand_name 에러 방지
      final data = await supabase
          .from('clothes')
          .select('id, brand, title, image_url, user_id')
          .eq('user_id', user.id);

      // 🔥 핵심 수정: 비동기 작업 후 화면이 여전히 살아있는지(mounted) 확인
      if (!mounted) return;

      setState(() {
        myClothes = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("내 옷 불러오기 에러: $e");
    }
  }

  void _showMyItemPicker(Map<String, dynamic> targetItem) {
    // 바텀시트를 띄우기 전 context가 유효한지 확인
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("제안할 내 옷 선택",
                style: TextStyle(
                    color: Color(0xFFE2FF00),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: myClothes.isEmpty
                  ? const Center(
                  child: Text("등록된 옷이 없습니다.",
                      style: TextStyle(color: Colors.white54)))
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
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                          image: NetworkImage(myClothes[index]['image_url']),
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(
      Map<String, dynamic> targetItem, Map<String, dynamic> myItem) async {
    try {
      // id가 uuid라면 toString() 없이 그대로 전달하는 것이 안전함
      await _swapService.sendSwapRequest(
        receiverId: targetItem['user_id'],
        receiverClothesId: targetItem['id'], // uuid 대응
        myClothesId: myItem['id'],           // uuid 대응
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("교환 요청 성공! ❤️"), backgroundColor: Colors.blueAccent));
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
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // primaryKey는 uuid 타입인 id 사용
        stream: supabase.from('clothes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("에러: ${snapshot.error}"));

          final items = snapshot.data
              ?.where((i) => i['user_id'] != supabase.auth.currentUser?.id)
              .toList() ?? [];

          if (items.isEmpty) {
            return const Center(
                child: Text("교환할 옷이 없습니다.", style: TextStyle(color: Colors.white54)));
          }

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("SWAP",
                    style: TextStyle(
                        color: Color(0xFFE2FF00),
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: items.length,
                    numberOfCardsDisplayed: items.length > 1 ? 2 : 1,
                    backCardOffset: const Offset(0, 10),
                    padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
              child: Image.network(item['image_url'], fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, color: Colors.white24)))),
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8)
                          ])))),
          Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['brand'] ?? 'Unknown', // brand_name 이슈 대응
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  Text(item['title'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleBtn(Icons.close, Colors.red,
                () => _controller.swipe(CardSwiperDirection.left)),
        const SizedBox(width: 40),
        _circleBtn(Icons.favorite, const Color(0xFFE2FF00),
                () => _controller.swipe(CardSwiperDirection.right)),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color col, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(color: col, width: 2)),
          child: Icon(icon, color: col, size: 35)),
    );
  }
}