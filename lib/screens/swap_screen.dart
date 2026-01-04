import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:io';
import '../data/mock_data.dart';
import '../models/clothing_item.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final CardSwiperController _controller = CardSwiperController();
  late List<ClothingItem> displayItems;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    displayItems = List.from(mockData);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 데이터 초기화 함수
  void _resetCards() {
    setState(() {
      displayItems = List.from(mockData);
      _isModalOpen = false;
    });
  }

  // 내 옷 선택 모달 (오른쪽 스와이프 시 발생)
  void _showMyItemPicker(ClothingItem targetItem) {
    if (_isModalOpen) return;
    _isModalOpen = true;

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
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "${targetItem.brand}와 교환할\n내 옷을 선택하세요",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 25),
            myItems.isEmpty
                ? const Expanded(
              child: Center(
                child: Text(
                  "등록된 옷이 없습니다.",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
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
                        displayItems.removeWhere((item) => item.id == targetItem.id);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("교환 요청을 보냈습니다!"),
                          backgroundColor: Colors.green,
                        ),
                      );
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
                          Text(
                            myItem.brand,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
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
    ).then((_) => _isModalOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "CLO-SWAP",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE2FF00),
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _resetCards,
          )
        ],
      ),
      body: Stack(
        children: [
          // 카드가 없을 때 표시되는 배경
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white24, size: 80),
                const SizedBox(height: 20),
                const Text("모든 옷을 확인했습니다!", style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resetCards,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D4D),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("다시 보기", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          if (displayItems.isNotEmpty)
            Column(
              children: [
                // 카드 스와이퍼 영역
                Expanded(
                  child: CardSwiper(
                    controller: _controller,
                    cardsCount: displayItems.length,
                    numberOfCardsDisplayed: 2,
                    backCardOffset: const Offset(0, 30),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    scale: 0.9,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      if (direction == CardSwiperDirection.right) {
                        _showMyItemPicker(displayItems[previousIndex]);
                      }
                      if (currentIndex == null) {
                        setState(() {
                          displayItems.clear();
                        });
                      }
                      return true;
                    },
                    cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                      return _buildSwapCard(displayItems[index]);
                    },
                  ),
                ),

                // 하단 버튼 영역 (내비바 높이 고려)
                Padding(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoundButton(
                        icon: Icons.close,
                        color: Colors.white,
                        onPressed: () => _controller.swipe(CardSwiperDirection.left),
                      ),
                      const SizedBox(width: 50),
                      _buildRoundButton(
                        icon: Icons.favorite,
                        color: const Color(0xFFFF4D4D),
                        onPressed: () => _controller.swipe(CardSwiperDirection.right),
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

  // 카드 위젯 디자인
  Widget _buildSwapCard(ClothingItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 이미지
            Positioned.fill(
              child: item.isLocal
                  ? Image.file(File(item.imageUrl), fit: BoxFit.cover)
                  : Image.network(item.imageUrl, fit: BoxFit.cover),
            ),

            // 텍스트 가독성을 위한 오버레이
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // 정보 텍스트
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.brand.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900, // ✅ 에러 수정된 부분
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2FF00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "SIZE: ${item.size}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 원형 버튼 위젯
  Widget _buildRoundButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: color, size: 34),
        ),
      ),
    );
  }
}