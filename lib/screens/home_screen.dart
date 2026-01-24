import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'search_screen.dart';
import '../main.dart';
import 'item_detail_screen.dart';
import 'brand_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = '전체';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              "SWAP",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 22.sp,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "-FIT",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 22.sp,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black, size: 26.sp),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            // 🔥 프리미엄 계정 배너 (SWAP BOX 대체)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PREMIUM",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "프리미엄으로 업그레이드",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "무제한 스왑 + 광고 제거",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "가입하기",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 🔥 거래 타입 필터 (위탁판매, 플랫폼재고 제거)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                          filter,
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

            SizedBox(height: 20.h),

            // 🔥 파트너 브랜드 섹션
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "파트너 브랜드",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "공식 재고 · 정품 보장",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.chevron_right, color: Colors.black26, size: 20.sp),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        {'brand': 'NIKE', 'desc': '신상 50% 할인', 'count': 24},
                        {'brand': 'STUSSY', 'desc': '시즌오프 재고', 'count': 18},
                        {'brand': 'ADIDAS', 'desc': 'B급 특가', 'count': 32},
                      ].map((b) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BrandDetailScreen(
                                  brand: {
                                    'id': b['brand'],
                                    'name': b['brand'],
                                    'logo_url': '',
                                    'follower_count': 1250,
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 160.w,
                            margin: EdgeInsets.only(right: 12.w),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "공식",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  b['brand'] as String,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  b['desc'] as String,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "${b['count']}개 상품",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // 🔥 일반 아이템 그리드
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('clothes').stream(primaryKey: ['id']).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                // 🔥 필터링 로직
                var items = snapshot.data!
                    .where((i) => i['user_id'] != supabase.auth.currentUser?.id)
                    .toList();

                // 선택된 필터에 따라 아이템 필터링
                if (_selectedFilter == '즉시구매') {
                  items = items.where((item) =>
                  item['trade_type'] == '판매만' || item['trade_type'] == '둘다 가능'
                  ).toList();
                } else if (_selectedFilter == '교환가능') {
                  items = items.where((item) =>
                  item['trade_type'] == '스왑만' || item['trade_type'] == '둘다 가능'
                  ).toList();
                }

                // 결과가 없을 때 처리
                if (items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 100.h),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60.sp, color: Colors.black12),
                          SizedBox(height: 16.h),
                          Text(
                            _selectedFilter == '전체'
                                ? "등록된 상품이 없습니다."
                                : "$_selectedFilter 상품이 없습니다.",
                            style: TextStyle(color: Colors.black26, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.h,
                      crossAxisSpacing: 16.w,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: const Color(0xFFEEEEEE)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Image.network(
                                        item['image_url'] ?? '',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Icon(Icons.image_not_supported, color: Colors.black12)),
                                      ),
                                    ),
                                  ),
                                  // 🔥 정품 배지
                                  if (item['auth_status'] == '정품')
                                    Positioned(
                                      top: 8.h,
                                      left: 8.w,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          "공식",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              item['brand']?.toUpperCase() ?? 'BRAND',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              item['title'] ?? '',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            // 🔥 거래 타입 태그
                            Wrap(
                              spacing: 4.w,
                              children: [
                                if (item['trade_type'] == '판매만')
                                  _buildTag("즉시구매", Colors.black, Colors.white),
                                if (item['trade_type'] == '스왑만')
                                  _buildTag("교환", Colors.white, Colors.black, hasBorder: true),
                                if (item['trade_type'] == '둘다 가능') ...[
                                  _buildTag("즉시구매", Colors.black, Colors.white),
                                  _buildTag("교환", Colors.white, Colors.black, hasBorder: true),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            SizedBox(height: 100.h),
          ],
        ),
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
}