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

  Future<void> _loadMyClothes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase.from('clothes').select().eq('user_id', user.id);
    setState(() => myClothes = List<Map<String, dynamic>>.from(data));
  }

  // 내 옷 선택 바텀시트
  void _showMyItemPicker(Map<String, dynamic> targetItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("제안할 내 옷 선택", style: TextStyle(color: Color(0xFFE2FF00), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: myClothes.isEmpty
                  ? const Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.white54)))
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
                      image: DecorationImage(image: NetworkImage(myClothes[index]['image_url']), fit: BoxFit.cover),
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

  Future<void> _sendRequest(Map<String, dynamic> targetItem, Map<String, dynamic> myItem) async {
    try {
      await _swapService.sendSwapRequest(
        receiverId: targetItem['user_id'],
        receiverClothesId: targetItem['id'].toString(), // 상대방 옷 ID
        myClothesId: myItem['id'].toString(),           // 내 옷 ID
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("교환 요청 성공! ❤️")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("실패: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('clothes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          final items = snapshot.data?.where((i) => i['user_id'] != supabase.auth.currentUser?.id).toList() ?? [];
          if (items.isEmpty) return const Center(child: Text("교환할 옷이 없습니다."));

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("SWAP", style: TextStyle(color: Color(0xFFE2FF00), fontSize: 28, fontWeight: FontWeight.bold)),
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: items.length,
                    numberOfCardsDisplayed: 1,
                    backCardOffset: const Offset(0, 0),
                    padding: const EdgeInsets.all(20),
                    onSwipe: (prev, curr, dir) {
                      if (dir == CardSwiperDirection.right) _showMyItemPicker(items[prev]);
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
          Positioned.fill(child: Image.network(item['image_url'], fit: BoxFit.cover)),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)])))),
          Positioned(bottom: 20, left: 20, child: Text(item['brand'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleBtn(Icons.close, Colors.red, () => _controller.swipe(CardSwiperDirection.left)),
        const SizedBox(width: 40),
        _circleBtn(Icons.favorite, const Color(0xFFE2FF00), () => _controller.swipe(CardSwiperDirection.right)),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color col, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: col, width: 2)), child: Icon(icon, color: col, size: 35)),
    );
  }
}