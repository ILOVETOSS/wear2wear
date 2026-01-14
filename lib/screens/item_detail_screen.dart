import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final PageController _pageController = PageController();
  final _supabase = Supabase.instance.client;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ 스왑 제안 전송 로직 (기존 유지)
  Future<void> _sendSwapProposal(Map<String, dynamic> myItem) async {
    try {
      await _supabase.from('swaps').insert({
        'from_user_id': _supabase.auth.currentUser!.id,
        'to_user_id': widget.item['user_id'],
        'my_item_id': myItem['id'],
        'target_item_id': widget.item['id'],
        'status': 'pending',
      });
      if (mounted) {
        Navigator.pop(context); // Picker 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚀 스왑 제안을 보냈습니다!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFB3EB00),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ 제안 전송 실패"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showMyClosetPicker() {
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
              const Text("제안할 내 옷 선택",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('clothes')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', _supabase.auth.currentUser!.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFB3EB00)));
                    final myItems = snapshot.data!;
                    if (myItems.isEmpty) return const Center(child: Text("내 옷장에 옷이 없습니다.", style: TextStyle(color: Colors.white54)));

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
                      itemCount: myItems.length,
                      itemBuilder: (context, index) {
                        final item = myItems[index];
                        return GestureDetector(
                          onTap: () => _sendSwapProposal(item),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(item['image_url'], fit: BoxFit.cover),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(item['title'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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

  @override
  Widget build(BuildContext context) {
    // ✅ 1. 업로드 시 저장한 image_urls 리스트 가져오기
    // 데이터가 없거나 단일 URL인 경우를 대비해 예외처리
    final List<String> allImages = [];
    if (widget.item['image_urls'] != null) {
      allImages.addAll(List<String>.from(widget.item['image_urls']));
    } else if (widget.item['image_url'] != null) {
      allImages.add(widget.item['image_url']);
    }

    final bool isMyItem = widget.item['user_id'] == _supabase.auth.currentUser?.id;
    final String authStatus = widget.item['auth_status'] ?? '모름';
    final String tradeType = widget.item['trade_type'] ?? '둘다 가능';
    final Color pointColor = const Color(0xFFB3EB00); // 일관된 라임 컬러 적용

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 상단 이미지 슬라이더 영역
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: allImages.length,
                    onPageChanged: (int page) => setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      return Image.network(
                        allImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // 이미지 로딩 실패 시 처리
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                        ),
                      );
                    },
                  ),
                ),
                // 그라데이션 오버레이 (텍스트 가독성)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                // 이미지 좌측 배지
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: Row(
                    children: [
                      _buildBadge(authStatus, authStatus == '정품' ? pointColor : Colors.white),
                      const SizedBox(width: 8),
                      _buildBadge(tradeType, Colors.white10, isBorder: true),
                    ],
                  ),
                ),
                // ✅ 이미지 페이지 인디케이터 (점)
                if (allImages.length > 1)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allImages.length, (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 8, height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index ? pointColor : Colors.white.withOpacity(0.5),
                        ),
                      )),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item['brand'] ?? 'Brand',
                      style: TextStyle(color: pointColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(widget.item['title'] ?? 'Title',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white10, thickness: 1),
                  const SizedBox(height: 20),
                  const Text("상품 상세 정보", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildInfoRow("정품 여부", authStatus),
                  _buildInfoRow("희망 거래", tradeType),
                  _buildInfoRow("아이템 상태", widget.item['condition'] ?? "좋음"),
                  _buildInfoRow("사이즈", widget.item['size'] ?? "FREE"),
                  _buildInfoRow("카테고리", widget.item['category'] ?? "기타"),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMyItem
          ? null
          : Container(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 34.h),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: ElevatedButton(
          onPressed: _showMyClosetPicker,
          style: ElevatedButton.styleFrom(
            backgroundColor: pointColor,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text("스왑 제안하기",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {bool isBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBorder ? Colors.black.withOpacity(0.5) : color,
        borderRadius: BorderRadius.circular(8),
        border: isBorder ? Border.all(color: Colors.white24) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isBorder ? Colors.white : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}