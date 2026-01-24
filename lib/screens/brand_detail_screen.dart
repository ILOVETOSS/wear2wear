import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/brand_service.dart';
import 'item_detail_screen.dart';

class BrandDetailScreen extends StatefulWidget {
  final Map<String, dynamic> brand;

  const BrandDetailScreen({super.key, required this.brand});

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  final _supabase = Supabase.instance.client;
  final BrandService _brandService = BrandService();

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String _selectedFilter = '전체';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _checkFollowStatus();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await _supabase
          .from('clothes')
          .select()
          .eq('brand_id', widget.brand['id'])
          .order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("상품 데이터 로드 에러: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFollowStatus() async {
    final isFollowing = await _brandService.isFollowing(widget.brand['id']);
    if (mounted) {
      setState(() => _isFollowing = isFollowing);
    }
  }

  Future<void> _toggleFollow() async {
    final success = await _brandService.toggleFollow(widget.brand['id']);
    if (success && mounted) {
      setState(() => _isFollowing = !_isFollowing);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFollowing ? "브랜드를 팔로우했습니다" : "팔로우를 취소했습니다",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 필터링된 상품 목록
    var filteredProducts = _products;
    if (_selectedFilter == '즉시구매') {
      filteredProducts = _products.where((p) =>
      p['trade_type'] == '판매만' || p['trade_type'] == '둘다 가능'
      ).toList();
    } else if (_selectedFilter == '교환가능') {
      filteredProducts = _products.where((p) =>
      p['trade_type'] == '스왑만' || p['trade_type'] == '둘다 가능'
      ).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.home_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrandHeader(),
            SizedBox(height: 20.h),

            // 🔥 거래 방식 필터
            // 🔥 거래 방식 필터
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: ['전체', '즉시구매', '교환가능'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20.r),
                          border: isSelected ? null : Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Text(
                          "$filter (${_getFilteredCount(filter)})",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            filteredProducts.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                mainAxisSpacing: 15.h,
                crossAxisSpacing: 12.w,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductItem(product);
              },
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  int _getFilteredCount(String filter) {
    if (filter == '전체') return _products.length;
    if (filter == '즉시구매') {
      return _products.where((p) =>
      p['trade_type'] == '판매만' || p['trade_type'] == '둘다 가능'
      ).length;
    }
    if (filter == '교환가능') {
      return _products.where((p) =>
      p['trade_type'] == '스왑만' || p['trade_type'] == '둘다 가능'
      ).length;
    }
    return 0;
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.brand['name'] ?? '브랜드명',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (widget.brand['is_official'] == true)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              "공식",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "팔로워 ${widget.brand['follower_count'] ?? 0} · 상품 ${_products.length}",
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 35.r,
                backgroundColor: Colors.grey[100],
                backgroundImage: widget.brand['logo_url'] != null && widget.brand['logo_url'].isNotEmpty
                    ? NetworkImage(widget.brand['logo_url'])
                    : null,
                child: widget.brand['logo_url'] == null || widget.brand['logo_url'].isEmpty
                    ? Icon(Icons.store, size: 30.sp, color: Colors.black26)
                    : null,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 🔥 팔로우 버튼
          ElevatedButton(
            onPressed: _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? const Color(0xFFF5F5F5) : Colors.black,
              foregroundColor: _isFollowing ? Colors.black : Colors.white,
              minimumSize: Size(double.infinity, 44.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: _isFollowing ? const BorderSide(color: Colors.black) : BorderSide.none,
              ),
              elevation: 0,
            ),
            child: Text(
              _isFollowing ? "팔로잉" : "팔로우",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 🔥 프로모션 정보
          if (widget.brand['promotion_text'] != null && widget.brand['promotion_text'].isNotEmpty) ...[
            SizedBox(height: 16.h),
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
                    "🔥 진행중인 프로모션",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.brand['promotion_text'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.brand['discount_rate'] != null && widget.brand['discount_rate'] > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      "최대 ${widget.brand['discount_rate']}% 할인",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: product)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
                image: product['image_url'] != null
                    ? DecorationImage(
                  image: NetworkImage(product['image_url']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: product['image_url'] == null
                  ? const Center(child: Icon(Icons.image, color: Colors.black12))
                  : null,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            product['title'] ?? '상품명 없음',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),

          // 🔥 거래 타입 태그
          Wrap(
            spacing: 4.w,
            children: [
              if (product['trade_type'] == '판매만')
                _buildTag("즉시구매", Colors.black, Colors.white),
              if (product['trade_type'] == '스왑만')
                _buildTag("교환", Colors.white, Colors.black, hasBorder: true),
              if (product['trade_type'] == '둘다 가능') ...[
                _buildTag("즉시구매", Colors.black, Colors.white),
                _buildTag("교환", Colors.white, Colors.black, hasBorder: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color bgColor, Color textColor, {bool hasBorder = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        border: hasBorder ? Border.all(color: Colors.black) : null,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 50.sp, color: Colors.grey[300]),
          SizedBox(height: 10.h),
          Text(
            "$_selectedFilter 상품이 없습니다.",
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}