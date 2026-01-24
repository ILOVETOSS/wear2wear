import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/wishlist_service.dart';
import '../services/authentication_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _supabase = Supabase.instance.client;
  final WishlistService _wishlistService = WishlistService();
  final AuthenticationService _authService = AuthenticationService();

  bool _isInWishlist = false;
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadItemStatus();
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.all(24.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tradeType == 'instant' ? '즉시 구매' : '교환 제안',
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInstantBuyContent() {
    final price = widget.item['price'] as int? ?? 450000;
    final fee = (price * 0.12).round();
    final total = price + fee;

    return [
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            _buildPriceRow("상품 가격", "${_formatPrice(price)}원"),
            SizedBox(height: 8.h),
            _buildPriceRow("플랫폼 수수료 (12%)", "${_formatPrice(fee)}원"),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              height: 1,
              color: Colors.grey[300],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "최종 결제금액",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "${_formatPrice(total)}원",
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
      SizedBox(height: 16.h),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // 🔥 20만원 이상이면 정품 인증 권장
            if (_authService.needsAuthentication(price)) {
              Navigator.pop(context);
              AuthenticationService.showAuthRecommendation(context, () {
                _showPaymentSuccess();
              });
            } else {
              Navigator.pop(context);
              _showPaymentSuccess();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: Text(
            "결제하기",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
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
        height: 280.h,
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
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.75,
              ),
              itemCount: myItems.length,
              itemBuilder: (context, index) {
                final item = myItems[index];
                final myPrice = item['price'] as int?;
                final targetPrice = widget.item['price'] as int?;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);

                    // 🔥 차액 계산
                    if (myPrice != null && targetPrice != null) {
                      final diff = (targetPrice - myPrice).abs();
                      if (diff > 0) {
                        _showDiffSwapConfirmation(item, myPrice, targetPrice, diff);
                      } else {
                        _sendSwapRequest(item, swapType: 'pure');
                      }
                    } else {
                      _sendSwapRequest(item, swapType: 'pure');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                            child: Image.network(
                              item['image_url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
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
                              if (myPrice != null)
                                Text(
                                  "${_formatPrice(myPrice)}원",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  // 🔥 차액 교환 확인 다이얼로그
  void _showDiffSwapConfirmation(
      Map<String, dynamic> myItem,
      int myPrice,
      int targetPrice,
      int diff) {
    final iMustPay = targetPrice > myPrice;
    final totalPayment = (diff * 1.15).round(); // 차액 + 15% 수수료

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "차액 교환",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              iMustPay
                  ? "내 옷 가격이 ${_formatPrice(diff)}원 더 낮습니다."
                  : "상대 옷 가격이 ${_formatPrice(diff)}원 더 낮습니다.",
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildPriceRow("내 옷", "${_formatPrice(myPrice)}원"),
                  _buildPriceRow("상대 옷", "${_formatPrice(targetPrice)}원"),
                  const Divider(height: 16),
                  _buildPriceRow("차액", "${_formatPrice(diff)}원"),
                  _buildPriceRow("수수료 (15%)", "${_formatPrice((diff * 0.15).round())}원"),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        iMustPay ? "내가 지불" : "상대가 지불",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "${_formatPrice(totalPayment)}원",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "취소",
              style: TextStyle(color: Colors.black38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSwapRequest(myItem, swapType: 'diff', diffAmount: diff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "교환 제안",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _sendSwapRequest(
      Map<String, dynamic> myItem,
      {String swapType = 'pure',
        int? diffAmount}) async {
    try {
      await _supabase.from('swaps').insert({
        'from_user_id': _supabase.auth.currentUser!.id,
        'to_user_id': widget.item['user_id'],
        'my_item_id': myItem['id'],
        'target_item_id': widget.item['id'],
        'status': 'pending',
        'swap_type': swapType,
        'diff_amount': diffAmount ?? 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              swapType == 'diff'
                  ? "🚀 차액 교환 제안을 보냈습니다!"
                  : "🚀 스왑 제안을 보냈습니다!",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "확인",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
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
    final String authStatus = widget.item['auth_status'] ?? '모름';
    final bool isMyItem = widget.item['user_id'] == _supabase.auth.currentUser?.id;
    final String tradeType = widget.item['trade_type'] ?? '둘다 가능';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleWishlist,
                          child: Icon(
                            _isInWishlist ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: Image.network(
                  widget.item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.black12, size: 50),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24.w),
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
                  SizedBox(height: 12.h),
                  Text(
                    widget.item['brand']?.toUpperCase() ?? 'BRAND',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.item['title'] ?? 'Title',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    height: 1,
                    color: const Color(0xFFEEEEEE),
                  ),
                  SizedBox(height: 24.h),
                  _buildInfoRow("정품 여부", authStatus),
                  _buildInfoRow("사이즈", widget.item['size'] ?? 'L'),
                  _buildInfoRow("상태", widget.item['condition'] ?? '상급'),
                  _buildInfoRow("거래 방식", tradeType),

                  SizedBox(height: 32.h),

                  if (!isMyItem && tradeType != '스왑만') Container(
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
                        SizedBox(height: 12.h),
                        if (tradeType == '판매만' || tradeType == '둘다 가능')
                          _buildTradeOption(
                            title: "즉시 구매",
                            subtitle: "${_formatPrice(widget.item['price'] ?? 450000)}원 (수수료 0%)",
                            onTap: () => _showTradeModal('instant'),
                            isBold: true,
                          ),
                        if (tradeType == '둘다 가능') SizedBox(height: 8.h),
                        if (tradeType == '스왑만' || tradeType == '둘다 가능')
                          _buildTradeOption(
                            title: "내 옷과 교환",
                            subtitle: "순수교환 8,000원 | 차액교환 0%",
                            onTap: () => _showTradeModal('swap'),
                          ),
                      ],
                    ),
                  ),

                  if (!isMyItem && tradeType == '스왑만')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showTradeModal('swap'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "교환 제안하기",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                          ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black45,
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
      ),
    );
  }

  Widget _buildTradeOption({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isBold = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isBold ? Colors.black : const Color(0xFFEEEEEE),
            width: isBold ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }
}