import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/swap_service.dart';
import '../services/authentication_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final SwapService _swapService = SwapService();
  final CardSwiperController _controller = CardSwiperController();
  final AuthenticationService _authService = AuthenticationService();

  List<Map<String, dynamic>> myClothes = [];

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
          .select('id, brand, title, image_url, user_id, price, trade_type')
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        myClothes = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("내 옷 불러오기 에러: $e");
    }
  }

  // 🔥 하트 클릭 시 거래 방식에 따라 분기 처리
  void _handleRightSwipe(Map<String, dynamic> targetItem) {
    final tradeType = targetItem['trade_type'] ?? '둘다 가능';
    final price = targetItem['price'] as int?;

    switch (tradeType) {
      case '판매만':
      // 바로 결제 프로세스
        if (price != null) {
          _handleInstantBuy(targetItem, price);
        } else {
          _showSnackBar("가격 정보가 없습니다.");
        }
        break;

      case '스왑만':
      // 내 옷 선택 -> 스왑
        _showMyItemPicker(targetItem, swapOnly: true);
        break;

      case '둘다 가능':
      // 구매 or 스왑 선택
        _showTradeTypeSelection(targetItem);
        break;

      default:
        _showSnackBar("거래 방식 정보가 없습니다.");
    }
  }

  // 🔥 구매 or 스왑 선택 다이얼로그
  void _showTradeTypeSelection(Map<String, dynamic> targetItem) {
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
            const Text("거래 방식 선택",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("${targetItem['brand']} ${targetItem['title']}",
                style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 24),

            // 즉시 구매 옵션
            _buildTradeOption(
              icon: Icons.shopping_bag_outlined,
              title: "즉시 구매",
              subtitle: targetItem['price'] != null
                  ? "${_formatPrice(targetItem['price'])}원"
                  : "가격 미정",
              onTap: () {
                Navigator.pop(ctx);
                if (targetItem['price'] != null) {
                  _handleInstantBuy(targetItem, targetItem['price']);
                } else {
                  _showSnackBar("가격 정보가 없습니다.");
                }
              },
            ),

            const SizedBox(height: 12),

            // 스왑 옵션
            _buildTradeOption(
              icon: Icons.swap_horiz_rounded,
              title: "내 옷과 교환",
              subtitle: "순수 교환 또는 차액 교환",
              onTap: () {
                Navigator.pop(ctx);
                _showMyItemPicker(targetItem, swapOnly: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // 즉시 구매 처리
  void _handleInstantBuy(Map<String, dynamic> targetItem, int price) {
    // 20만원 이상이면 정품 인증 권장
    if (_authService.needsAuthentication(price)) {
      AuthenticationService.showAuthRecommendation(context, () {
        _proceedToPurchase(targetItem, price);
      });
    } else {
      _proceedToPurchase(targetItem, price);
    }
  }

  void _proceedToPurchase(Map<String, dynamic> targetItem, int price) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("즉시 구매",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPriceRow("상품 가격", "${_formatPrice(price)}원"),
                  const SizedBox(height: 8),
                  _buildPriceRow("플랫폼 수수료 (12%)", "${_formatPrice((price * 0.12).round())}원"),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("최종 결제금액",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      Text("${_formatPrice((price * 1.12).round())}원",
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _processPayment(targetItem, price);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text("결제하기",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> targetItem, int price) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("구매가 완료되었습니다!",
                style: TextStyle(
                  color: Colors.black,  // ✅ 유지 (포인트 색상 배경이라 검은색 가능)
                  fontWeight: FontWeight.bold,
                )),
            backgroundColor: _pointColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "결제 실패",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),  // ✅ 흰색
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // 내 옷 선택 (스왑용)
  void _showMyItemPicker(Map<String, dynamic> targetItem, {required bool swapOnly}) {
    if (!mounted) return;

    final targetPrice = targetItem['price'] as int?;

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
                itemBuilder: (context, index) {
                  final myItem = myClothes[index];
                  final myPrice = myItem['price'] as int?;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleSwapRequest(targetItem, myItem, targetPrice, myPrice);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 100,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black12),
                                image: DecorationImage(
                                    image: NetworkImage(myItem['image_url']),
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (myPrice != null)
                            Text("${_formatPrice(myPrice)}원",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 스왑 요청 처리 (차액 계산 포함)
  Future<void> _handleSwapRequest(
      Map<String, dynamic> targetItem,
      Map<String, dynamic> myItem,
      int? targetPrice,
      int? myPrice) async {

    // 둘 다 가격이 있으면 차액 교환
    if (targetPrice != null && myPrice != null) {
      final diff = (targetPrice - myPrice).abs();

      if (diff > 0) {
        _showDiffSwapConfirmation(targetItem, myItem, targetPrice, myPrice, diff);
      } else {
        await _sendRequest(targetItem, myItem, swapType: 'pure');
      }
    } else {
      await _sendRequest(targetItem, myItem, swapType: 'pure');
    }
  }

  // 차액 교환 확인 다이얼로그
  void _showDiffSwapConfirmation(
      Map<String, dynamic> targetItem,
      Map<String, dynamic> myItem,
      int targetPrice,
      int myPrice,
      int diff) {
    final iMustPay = targetPrice > myPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("차액 교환",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(iMustPay
                ? "내 옷 가격이 ${_formatPrice(diff)}원 더 낮습니다."
                : "상대 옷 가격이 ${_formatPrice(diff)}원 더 낮습니다.",
                style: const TextStyle(color: Colors.black, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildPriceRow("차액", "${_formatPrice(diff)}원"),
                  _buildPriceRow("수수료 (15%)", "${_formatPrice((diff * 0.15).round())}원"),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(iMustPay ? "내가 지불" : "상대가 지불",
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      Text("${_formatPrice((diff * 1.15).round())}원",
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
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
            child: const Text("취소", style: TextStyle(color: Colors.black38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendRequest(targetItem, myItem,
                  swapType: 'diff', diffAmount: diff, iMustPay: iMustPay);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("교환 제안", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(
      Map<String, dynamic> targetItem,
      Map<String, dynamic> myItem,
      {String swapType = 'pure',
        int? diffAmount,
        bool iMustPay = false}) async {
    try {
      // ✅ 수정: named 인자 대신 위치 인자 사용
      await _swapService.sendSwapRequest(
        targetItem['user_id'],      // receiverId (위치 1)
        targetItem['id'],           // receiverClothesId (위치 2)
        myItem['id'],               // myClothesId (위치 3)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              swapType == 'diff'
                  ? "차액 교환 제안을 보냈습니다!"
                  : "교환 요청 성공! ❤️",
              style: const TextStyle(
                color: Colors.black,  // ✅ 유지 (포인트 색상 배경)
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: _pointColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "실패: $e",
              style: const TextStyle(
                color: Colors.white,  // ✅ 흰색
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
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
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,  // ✅ 흰색 글자
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                        _handleRightSwipe(items[prev]);
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
    final isPartner = item['is_partner_brand'] == true;
    final price = item['price'] as int?;
    final tradeType = item['trade_type'] ?? '둘다 가능';

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

            // 파트너 브랜드 배지
            if (isPartner)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.black, size: 16),
                      const SizedBox(width: 4),
                      const Text("공식",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            // 거래 방식 배지
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tradeType,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Positioned(
                bottom: 25,
                left: 20,
                right: 20,
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

                    if (price != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPartner ? Colors.black : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("${_formatPrice(price)}원",
                            style: TextStyle(
                                color: isPartner ? _pointColor : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleBtn(Icons.close, Colors.red, () => _controller.swipe(CardSwiperDirection.left)),
        const SizedBox(width: 40),
        _circleBtn(Icons.favorite, _pointColor, () => _controller.swipe(CardSwiperDirection.right)),
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
              shape: BoxShape.circle,
              border: Border.all(color: col, width: 2)),
          child: Icon(icon, color: col, size: 35)),
    );
  }
}