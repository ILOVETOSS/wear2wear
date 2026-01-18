import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/wishlist_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final PageController _pageController = PageController();
  final _supabase = Supabase.instance.client;
  final WishlistService _wishlistService = WishlistService();

  int _currentPage = 0;
  bool _isInWishlist = false;
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadItemStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadItemStatus() async {
    final clothesId = widget.item['id'].toString();

    final wishlist = await _wishlistService.checkWishlist(clothesId);
    final liked = await _wishlistService.checkLike(clothesId);
    final count = await _wishlistService.getLikesCount(clothesId);

    if (mounted) {
      setState(() {
        _isInWishlist = wishlist;
        _isLiked = liked;
        _likesCount = count;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final success = await _wishlistService.toggleWishlist(widget.item['id'].toString());
    if (success && mounted) {
      setState(() => _isInWishlist = !_isInWishlist);
    }
  }

  Future<void> _toggleLike() async {
    final success = await _wishlistService.toggleLike(widget.item['id'].toString());
    if (success && mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
      });
    }
  }

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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚀 스왑 제안을 보냈습니다!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 500.h,
          child: Column(
            children: [
              const Text("제안할 내 옷 선택",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(height: 20.h),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('clothes')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', _supabase.auth.currentUser!.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
                    final myItems = snapshot.data!;
                    if (myItems.isEmpty) return const Center(child: Text("내 옷장에 옷이 없습니다.", style: TextStyle(color: Colors.black54)));

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
                                  style: const TextStyle(color: Colors.black, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final List<String> allImages = [];
    if (widget.item['image_urls'] != null) {
      allImages.addAll(List<String>.from(widget.item['image_urls']));
    } else if (widget.item['image_url'] != null) {
      allImages.add(widget.item['image_url']);
    }

    final bool isMyItem = widget.item['user_id'] == _supabase.auth.currentUser?.id;
    final String authStatus = widget.item['auth_status'] ?? '모름';
    final String tradeType = widget.item['trade_type'] ?? '둘다 가능';

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: Icon(
                  _isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                  color: _isInWishlist ? Colors.black : Colors.black, // 🔥 네온색 제거, 항상 검정
                  size: 20,
                ),
                onPressed: _toggleWishlist,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.black,
                  size: 20,
                ),
                onPressed: _toggleLike,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.black26, size: 50),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: Row(
                    children: [
                      _buildBadge(authStatus, Colors.black),
                      const SizedBox(width: 8),
                      _buildBadge(tradeType, Colors.black12, isBorder: true),
                    ],
                  ),
                ),
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
                          color: _currentPage == index ? Colors.black : Colors.black.withOpacity(0.2),
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
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_likesCount',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(widget.item['brand'] ?? 'Brand',
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(widget.item['title'] ?? 'Title',
                      style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 20),
                  const Text("상품 상세 정보", style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
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
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: ElevatedButton(
          onPressed: _showMyClosetPicker,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text("스왑 제안하기",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {bool isBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBorder ? Colors.white.withOpacity(0.8) : color,
        borderRadius: BorderRadius.circular(8),
        border: isBorder ? Border.all(color: Colors.black12) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isBorder ? Colors.black : Colors.white,
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
          Text(label, style: const TextStyle(color: Colors.black38, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}