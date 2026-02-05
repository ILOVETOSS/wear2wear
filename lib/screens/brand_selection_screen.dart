// lib/screens/brand_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BrandSelectionScreen extends StatefulWidget {
  final String? initialBrand;

  const BrandSelectionScreen({super.key, this.initialBrand});

  @override
  State<BrandSelectionScreen> createState() => _BrandSelectionScreenState();
}

class _BrandSelectionScreenState extends State<BrandSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBrand;

  // 브랜드 리스트 (실제로는 DB에서 가져올 수 있음)
  final List<Map<String, String>> _brands = [
    {'name': 'NIKE', 'name_kr': '나이키'},
    {'name': 'ADIDAS', 'name_kr': '아디다스'},
    {'name': 'STUSSY', 'name_kr': '스투시'},
    {'name': 'SUPREME', 'name_kr': '슈프림'},
    {'name': 'CARHARTT', 'name_kr': '칼하트'},
    {'name': 'STONE ISLAND', 'name_kr': '스톤 아일랜드'},
    {'name': 'CHROME HEARTS', 'name_kr': '크롬하츠'},
    {'name': 'RICK OWENS', 'name_kr': '릭 오웬스'},
    {'name': 'BALENCIAGA', 'name_kr': '발렌시아가'},
    {'name': 'GUCCI', 'name_kr': '구찌'},
    {'name': 'PRADA', 'name_kr': '프라다'},
    {'name': 'LOUIS VUITTON', 'name_kr': '루이비통'},
    {'name': 'ZARA', 'name_kr': '자라'},
    {'name': 'UNIQLO', 'name_kr': '유니클로'},
    {'name': 'COS', 'name_kr': '코스'},
    {'name': 'ACNE STUDIOS', 'name_kr': '아크네 스튜디오'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.initialBrand;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredBrands {
    if (_searchQuery.isEmpty) return _brands;

    return _brands.where((brand) {
      final name = brand['name']!.toLowerCase();
      final nameKr = brand['name_kr']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || nameKr.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "브랜드 선택",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedBrand != null
                ? () => Navigator.pop(context, _selectedBrand)
                : null,
            child: Text(
              "완료",
              style: TextStyle(
                color: _selectedBrand != null ? Colors.black : Colors.black26,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색창
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.sp,
              ),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "브랜드 검색",
                hintStyle: TextStyle(
                  color: const Color(0xFFCCCCCC),
                  fontSize: 15.sp,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black26),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // 브랜드 리스트
          Expanded(
            child: _filteredBrands.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60.sp,
                    color: Colors.black12,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "검색 결과가 없습니다",
                    style: TextStyle(
                      color: Colors.black26,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _filteredBrands.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF5F5F5),
              ),
              itemBuilder: (context, index) {
                final brand = _filteredBrands[index];
                final isSelected = _selectedBrand == brand['name'];

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedBrand = brand['name'];
                    });
                  },
                  leading: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        brand['name']![0],
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    brand['name']!,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    brand['name_kr']!,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13.sp,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: 24.sp,
                  )
                      : Icon(
                    Icons.circle_outlined,
                    color: Colors.black12,
                    size: 24.sp,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}