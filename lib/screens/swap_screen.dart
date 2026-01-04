import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'dart:io';
import '../data/mock_data.dart';
import '../models/clothing_item.dart';
import '../widgets/swap_card.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final AppinioSwiperController _controller = AppinioSwiperController();
  late List<ClothingItem> displayItems;

  // 🔥 중복 실행 방지를 위한 플래그 변수
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    displayItems = List.from(mockData);
  }

  void _resetCards() {
    setState(() {
      displayItems = List.from(mockData);
      _isModalOpen = false;
    });
  }

  // 🔥 내 옷 선택 모달
  void _showMyItemPicker(ClothingItem targetItem, int itemIndex) {
    // 이미 모달이 열려있다면 중복으로 띄우지 않음
    if (_isModalOpen) return;

    _isModalOpen = true; // 열림 표시
    _controller.unswipe();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text(
              "${targetItem.brand}와 교환할\n내 옷을 선택하세요",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 25),
            myItems.isEmpty
                ? const Expanded(child: Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.white54))))
                : Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: myItems.length,
                itemBuilder: (context, index) {
                  final myItem = myItems[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        matchedItems.add(targetItem);
                        displayItems.removeAt(itemIndex);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("교환 요청을 보냈습니다!"), backgroundColor: Colors.green));
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: myItem.isLocal
                                ? Image.file(File(myItem.imageUrl), width: 140, height: 140, fit: BoxFit.cover)
                                : Image.network(myItem.imageUrl, width: 140, height: 140, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 10),
                          Text(myItem.brand, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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
    ).then((_) {
      // ✅ 모달이 닫힐 때 플래그를 다시 초기화
      _isModalOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SWAP", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _resetCards)],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white24, size: 80),
                const SizedBox(height: 20),
                const Text("모든 옷을 확인했습니다!", style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _resetCards,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4D)),
                  child: const Text("다시 보기"),
                ),
              ],
            ),
          ),
          if (displayItems.isNotEmpty)
            Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: AppinioSwiper(
                      controller: _controller,
                      cardCount: displayItems.length,
                      cardBuilder: (context, index) => SwapCard(item: displayItems[index]),
                      onSwipeEnd: (previousIndex, targetIndex, activity) {
                        // 💡 방향이 오른쪽(교환)일 때만 모달 호출
                        if (activity.direction == AxisDirection.right) {
                          _showMyItemPicker(displayItems[previousIndex], previousIndex);
                        } else {
                          setState(() {
                            displayItems.removeAt(previousIndex);
                          });
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoundButton(
                        icon: Icons.close,
                        color: Colors.white,
                        onPressed: () => _controller.swipeLeft(),
                      ),
                      const SizedBox(width: 40),
                      _buildRoundButton(
                        icon: Icons.favorite,
                        color: const Color(0xFFFF4D4D),
                        onPressed: () => _controller.swipeRight(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: Colors.white12, width: 2),
      ),
      child: IconButton(icon: Icon(icon, color: color, size: 30), onPressed: onPressed),
    );
  }
}