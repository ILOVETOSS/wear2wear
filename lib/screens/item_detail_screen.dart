import 'package:flutter/material.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 대표 사진과 상세 사진들을 하나의 리스트로 통합
    final List<String> allImages = [
      widget.item['image_url'],
      ...List<String>.from(widget.item['images'] ?? []),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      // 상단 바 뒤까지 이미지가 확장되도록 설정
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 이미지 슬라이더 영역
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6, // 화면의 60% 높이
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: allImages.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        allImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // 이미지 로딩 중 표시할 위젯
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
                        },
                      );
                    },
                  ),
                ),
                // 2. 하단 점(Indicator) 표시
                if (allImages.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        allImages.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? const Color(0xFFE2FF00) // 활성화된 점
                                : Colors.white.withOpacity(0.5), // 비활성화된 점
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 3. 아이템 상세 정보 영역
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item['brand'] ?? 'Brand',
                    style: const TextStyle(
                      color: Color(0xFFE2FF00),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item['title'] ?? 'Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white10, thickness: 1),
                  const SizedBox(height: 20),
                  const Text(
                    "상세 정보",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow("상태", widget.item['condition'] ?? "좋음"),
                  _buildInfoRow("사이즈", widget.item['size'] ?? "FREE"),
                  _buildInfoRow("카테고리", widget.item['category'] ?? "기타"),
                  const SizedBox(height: 50), // 하단 여백
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}