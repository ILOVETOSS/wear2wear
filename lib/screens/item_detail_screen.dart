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

  String? _selectedTradeType; // 선택된 거래 방식

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

  // 🔥 거래 방식별 모달 표시
  void _showTradeModal(String tradeType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) => _buildTradeModalContent(tradeType),
    );
  }

  Widget _buildTradeModalContent(String tradeType) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tradeType == 'instant'
                    ? '즉시 구매'
                    : tradeType == 'swap'
                    ? '교환 제안'
                    : '플랫폼 재고 교환',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          if (tradeType == 'instant') ..._buildInstantBuyContent(),
          if (tradeType == 'swap') ..._buildSwapContent(),
          if (tradeType == 'platform') ..._buildPlatformSwapContent(),
        ],
      ),
    );
  }

  List<Widget> _buildInstantBuyContent() {
    return [
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            _buildPriceRow("상품 가격", "450,000원"),
            SizedBox(height: 8.h),
            _buildPriceRow("플랫폼 수수료 (12%)", "54,000원"),
            Divider(height: 24.h, color: Colors.black12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "최종 결제금액",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "504,000원",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 24.h),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _showPaymentSuccess();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          "결제하기",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSwapContent() {
    return [
      Text(
        "교환 제안할 내 옷을 선택하세요",
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14.sp,
        ),
      ),
      SizedBox(height: 16.h),
      SizedBox(
        height: 200.h,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('clothes')
              .stream(primaryKey: ['id'])
              .eq('user_id', _supabase.auth.currentUser!.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            final myItems = snapshot.data!;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.8,
              ),
              itemCount: myItems.length,
              itemBuilder: (context, index) {
                final item = myItems[index];
                return GestureDetector(
                  onTap: () => _sendSwapRequest(item),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10.r),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10.r),
                              ),
                              child: Image.network(
                                item['image_url'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['brand'] ?? '',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item['title'] ?? '',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 9.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      SizedBox(height: 16.h),
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "교환 수수료",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14.sp,
              ),
            ),
            Text(
              "8,000원",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPlatformSwapContent() {
    return [
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "교환 조합",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _buildSwapItemPreview("내 옷", "NIKE Tee", "300,000원")),
                SizedBox(width: 8.w),
                Icon(Icons.add, color: Colors.black, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(child: _buildSwapItemPreview("차액", "150,000원", "", isDiff: true)),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward, color: Colors.black, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(child: _buildSwapItemPreview("SUPREME", "Hoodie", "")),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 16.h),
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            _buildPriceRow("차액 결제", "150,000원"),
            SizedBox(height: 8.h),
            _buildPriceRow("플랫폼 수수료 (15%)", "22,500원"),
            Divider(height: 24.h, color: Colors.black12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "총 결제금액",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "172,500원",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 24.h),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _showPaymentSuccess();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          "결제하기",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ];
  }

  Widget _buildSwapItemPreview(String brand, String title, String price, {bool isDiff = false}) {
    return Column(
      children: [
        Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: isDiff ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: isDiff ? Colors.black : const Color(0xFFEEEEEE)),
          ),
          child: Center(
            child: isDiff
                ? Text(
              "차액",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            )
                : const Icon(Icons.checkroom, color: Colors.black12, size: 30),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          brand,
          style: TextStyle(
            color: Colors.black,
            fontSize: 10.sp,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (title.isNotEmpty)
          Text(
            title,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 9.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (price.isNotEmpty)
          Text(
            price,
            style: TextStyle(
              color: Colors.black,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _sendSwapRequest(Map<String, dynamic> myItem) async {
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
            content: Text(
              "🚀 스왑 제안을 보냈습니다!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ 제안 전송 실패"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "결제 완료",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "거래가 성공적으로 완료되었습니다",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildPriceRow("결제 금액", "504,000원"),
                    SizedBox(height: 8.h),
                    _buildPriceRow("결제 방법", "카드"),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 60.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  "확인",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  color: Colors.black,
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
            // 이미지 영역
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
                if (allImages.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        allImages.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? Colors.black
                                : Colors.black.withOpacity(0.2),
                          ),
                        ),
                      ),
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
                  Text(
                    widget.item['brand'] ?? 'Brand',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item['title'] ?? 'Title',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.black12, thickness: 1),
                  const SizedBox(height: 20),
                  const Text(
                    "상품 상세 정보",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow("정품 여부", authStatus),
                  _buildInfoRow("희망 거래", tradeType),
                  _buildInfoRow("아이템 상태", widget.item['condition'] ?? "좋음"),
                  _buildInfoRow("사이즈", widget.item['size'] ?? "FREE"),
                  _buildInfoRow("카테고리", widget.item['category'] ?? "기타"),

                  // 🔥 거래 방식 선택 영역
                  if (!isMyItem) ...[
                    const SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "거래 방식 선택",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // 즉시 구매
                          GestureDetector(
                            onTap: () => _showTradeModal('instant'),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "즉시 구매",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        "450,000원 (수수료 12%)",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                                ],
                              ),
                            ),
                          ),

                          // 내 옷과 교환
                          GestureDetector(
                            onTap: () => _showTradeModal('swap'),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "내 옷과 교환",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        "순수교환 8,000원 | 차액교환 15%",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                                ],
                              ),
                            ),
                          ),

                          // 플랫폼 재고로 교환
                          GestureDetector(
                            onTap: () => _showTradeModal('platform'),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2, size: 16, color: Colors.black),
                                          SizedBox(width: 8.w),
                                          Text(
                                            "플랫폼 재고로 교환",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        "내 옷 + 차액 150,000원",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 120),
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