import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandDetailScreen extends StatefulWidget {
  final Map<String, dynamic> brand;

  const BrandDetailScreen({super.key, required this.brand});

  @override
  State<BrandDetailScreen> createState() => _BrandDetailScreenState();
}

class _BrandDetailScreenState extends State<BrandDetailScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await _supabase
          .from('products')
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

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("상품 목록 (${_products.length})",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  const Icon(Icons.tune, color: Colors.black, size: 20),
                ],
              ),
            ),
            _products.isEmpty
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
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductItem(product);
              },
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.brand['name'] ?? '브랜드명',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                SizedBox(height: 4.h),
                Text("팔로워 ${widget.brand['follower_count'] ?? 0} · 상품 ${_products.length}",
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
              ],
            ),
          ),
          CircleAvatar(
            radius: 35.r,
            backgroundColor: Colors.grey[100],
            backgroundImage: NetworkImage(widget.brand['logo_url'] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
              image: DecorationImage(
                image: NetworkImage(product['image_url'] ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          product['name'] ?? '상품명 없음',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4.h),
        Text(
          "${product['price'] ?? 0}원",
          style: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
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
          Text("등록된 상품이 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        ],
      ),
    );
  }
}