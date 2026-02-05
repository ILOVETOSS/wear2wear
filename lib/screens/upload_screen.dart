import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'brand_selection_screen.dart';
import 'option_selection_screen.dart';

class UploadScreen extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  const UploadScreen({super.key, this.editItem});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();

  final List<XFile> _selectedImages = [];
  final List<Uint8List> _webImages = [];
  final List<String> _existingImageUrls = [];
  bool _isUploading = false;

  String? _selectedBrand;
  String? _selectedCategory;
  String? _selectedSize;
  String? _selectedCondition;
  String _authStatus = '모름';
  String _tradeType = '둘다 가능';
  bool _agreedToDisclaimer = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ootdContentController = TextEditingController();
  String _selectedOotdCategory = '스트릿';

  // 카테고리 옵션
  final List<String> _categories = ['아우터', '상의', '하의', '신발', '가방', '액세서리'];
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', 'FREE'];
  final List<String> _conditions = ['상급', '중급', '하급'];

  bool get isEditMode => widget.editItem != null;
  bool get _showPriceInput => _tradeType == '판매만' || _tradeType == '둘다 가능';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (isEditMode) _loadExistingData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _ootdContentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final item = widget.editItem!;
    _selectedBrand = item['brand'];
    _titleController.text = item['title'] ?? '';
    _priceController.text = item['price']?.toString() ?? '';
    _authStatus = item['auth_status'] ?? '모름';
    _tradeType = item['trade_type'] ?? '둘다 가능';
    _agreedToDisclaimer = item['disclaimer_agreed'] ?? false;

    if (item['image_urls'] != null && item['image_urls'] is List) {
      _existingImageUrls.addAll(
          List<String>.from(item['image_urls'].map((e) => e.toString()))
      );
    } else if (item['image_url'] != null) {
      _existingImageUrls.add(item['image_url'].toString());
    }
    setState(() {});
  }

  Future<void> _pickImages() async {
    final totalImages = _selectedImages.length + _existingImageUrls.length;
    if (totalImages >= 10) {
      _showSnackBar("사진은 최대 10장까지 등록 가능합니다.");
      return;
    }

    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 50);

    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        final currentTotal = _selectedImages.length + _existingImageUrls.length;
        if (currentTotal < 10) {
          final bytes = await file.readAsBytes();
          setState(() {
            _selectedImages.add(file);
            _webImages.add(bytes);
          });
        }
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _webImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.black),
    );
  }

  // 브랜드 선택
  Future<void> _selectBrand() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BrandSelectionScreen(
          initialBrand: _selectedBrand,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBrand = result;
      });
    }
  }

  // 카테고리 선택
  Future<void> _selectCategory() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => OptionSelectionScreen(
          title: '카테고리',
          options: _categories,
          initialValue: _selectedCategory,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  // 사이즈 선택
  Future<void> _selectSize() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => OptionSelectionScreen(
          title: '사이즈',
          options: _sizes,
          initialValue: _selectedSize,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSize = result;
      });
    }
  }

  // 상태 선택
  Future<void> _selectCondition() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => OptionSelectionScreen(
          title: '상태',
          options: _conditions,
          initialValue: _selectedCondition,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCondition = result;
      });
    }
  }

  Future<void> _handleSave() async {
    final totalImages = _selectedImages.length + _existingImageUrls.length;
    if (totalImages == 0) {
      _showSnackBar("최소 1장의 이미지를 선택해주세요.");
      return;
    }

    if (_tabController.index == 0) {
      if (_selectedBrand == null || _selectedBrand!.isEmpty) {
        _showSnackBar("브랜드를 선택해주세요.");
        return;
      }

      if (!_agreedToDisclaimer) {
        _showSnackBar("법적 책임 면책 조항에 동의해야 등록이 가능합니다.");
        return;
      }

      if (_showPriceInput) {
        if (_priceController.text.trim().isEmpty) {
          _showSnackBar("가격을 입력해주세요.");
          return;
        }
        final price = int.tryParse(_priceController.text.trim());
        if (price == null || price <= 0) {
          _showSnackBar("올바른 가격을 입력해주세요.");
          return;
        }
      }
    }

    setState(() => _isUploading = true);

    bool success = false;

    if (_tabController.index == 0) {
      if (isEditMode) {
        success = await _updateClothingItem();
      } else {
        success = await _dbService.uploadClothingItem(
          imageFiles: _selectedImages,
          brand: _selectedBrand!,
          title: _titleController.text,
          extraData: {
            'trade_type': _tradeType,
            'auth_status': _authStatus,
            'disclaimer_agreed': _agreedToDisclaimer,
            'price': _showPriceInput ? int.tryParse(_priceController.text.trim()) : null,
            'category': _selectedCategory,
            'size': _selectedSize,
            'condition': _selectedCondition,
          },
        );
      }
    } else {
      success = await _dbService.uploadCommunityPost(
        imageFiles: _selectedImages,
        category: _selectedOotdCategory,
        content: _ootdContentController.text,
      );
    }

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isEditMode ? "수정이 완료되었습니다!" : "등록이 완료되었습니다!",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            backgroundColor: Colors.black,
          ),
        );
      } else {
        _showSnackBar("${isEditMode ? '수정' : '등록'} 중 오류가 발생했습니다.");
      }
    }
  }

  Future<bool> _updateClothingItem() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      List<String> newUploadedUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final String fileName = 'clothing/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Uint8List bytes = await _selectedImages[i].readAsBytes();

        await supabase.storage.from('clothing-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
        );

        final String url = supabase.storage.from('clothing-images').getPublicUrl(fileName);
        newUploadedUrls.add(url);
      }

      final allImageUrls = [..._existingImageUrls, ...newUploadedUrls];

      await supabase.from('clothes').update({
        'brand': _selectedBrand,
        'title': _titleController.text,
        'image_url': allImageUrls.isNotEmpty ? allImageUrls[0] : null,
        'image_urls': allImageUrls,
        'trade_type': _tradeType,
        'auth_status': _authStatus,
        'disclaimer_agreed': _agreedToDisclaimer,
        'price': _showPriceInput ? int.tryParse(_priceController.text.trim()) : null,
        'category': _selectedCategory,
        'size': _selectedSize,
        'condition': _selectedCondition,
      }).eq('id', widget.editItem!['id']);

      return true;
    } catch (e) {
      debugPrint("❌ 수정 에러: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            isEditMode ? "EDIT" : "UPLOAD",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18.sp)
        ),
        bottom: isEditMode ? null : TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[400],
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          tabs: const [Tab(text: "내 옷 등록"), Tab(text: "OOTD 공유")],
        ),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : isEditMode
          ? _buildForm(true)
          : TabBarView(
        controller: _tabController,
        children: [
          _buildForm(true),
          _buildForm(false),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 34.h),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isUploading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 60.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0),
          child: Text(
              isEditMode ? "수정 완료" : "등록하기",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isClothing) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMultiImagePicker(),
          SizedBox(height: 40.h),
          if (isClothing) ...[
            // 브랜드 선택 버튼
            _buildSelectionButton(
              label: "브랜드",
              value: _selectedBrand,
              hint: "브랜드를 선택하세요",
              onTap: _selectBrand,
            ),
            SizedBox(height: 30.h),

            // 제목 입력
            _buildTextField(
              controller: _titleController,
              label: "아이템 명",
              hint: "아이템 명을 입력하세요",
            ),
            SizedBox(height: 30.h),

            // 카테고리 선택
            _buildSelectionButton(
              label: "카테고리",
              value: _selectedCategory,
              hint: "카테고리를 선택하세요",
              onTap: _selectCategory,
            ),
            SizedBox(height: 30.h),

            // 사이즈 선택
            _buildSelectionButton(
              label: "사이즈",
              value: _selectedSize,
              hint: "사이즈를 선택하세요",
              onTap: _selectSize,
            ),
            SizedBox(height: 30.h),

            // 상태 선택
            _buildSelectionButton(
              label: "상태",
              value: _selectedCondition,
              hint: "상태를 선택하세요",
              onTap: _selectCondition,
            ),
            SizedBox(height: 40.h),

            _sectionLabel("거래 방식"),
            _buildMinimalBoxChips(['판매만', '스왑만', '둘다 가능'], _tradeType, (val) {
              setState(() => _tradeType = val);
            }),
            SizedBox(height: 30.h),

            if (_showPriceInput) ...[
              _buildTextField(
                controller: _priceController,
                label: "판매 가격",
                hint: "가격을 입력하세요",
                keyboardType: TextInputType.number,
                suffix: "원",
              ),
              SizedBox(height: 30.h),
            ],

            _sectionLabel("정품 여부"),
            _buildMinimalBoxChips(['정품', '가품', '모름'], _authStatus, (val) {
              setState(() => _authStatus = val);
            }),
            SizedBox(height: 40.h),
            _buildMinimalDisclaimer(),
          ] else ...[
            _sectionLabel("카테고리"),
            _buildMinimalBoxChips(['스트릿', '미니멀', '빈티지', '캐주얼'], _selectedOotdCategory, (val) {
              setState(() => _selectedOotdCategory = val);
            }),
            SizedBox(height: 30.h),
            _buildTextField(
              controller: _ootdContentController,
              label: "코디 설명",
              hint: "스타일을 설명해주세요",
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  // 선택 버튼 (브랜드, 카테고리, 사이즈, 상태)
  Widget _buildSelectionButton({
    required String label,
    String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEBEBEB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? hint,
                  style: TextStyle(
                    color: value != null ? Colors.black : const Color(0xFFCCCCCC),
                    fontSize: 15.sp,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black26,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 텍스트 입력 필드
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          cursorColor: Colors.black,
          cursorWidth: 2.0,
          cursorHeight: 20.h,
          showCursor: true,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15.sp,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFFCCCCCC),
              fontSize: 15.sp,
            ),
            suffixIcon: controller.text.isNotEmpty && maxLines == 1
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
              onPressed: () {
                controller.clear();
                setState(() {});
              },
            )
                : null,
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: Colors.black54,
              fontSize: 14.sp,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            filled: false,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEBEBEB), width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEBEBEB), width: 1),
            ),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildMultiImagePicker() {
    final totalCount = _existingImageUrls.length + _selectedImages.length;

    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100.h,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.grey[400]),
                    SizedBox(height: 4.h),
                    Text("$totalCount/10",
                        style: TextStyle(color: Colors.grey[400], fontSize: 11.sp)),
                  ],
                ),
              ),
            );
          }

          final actualIndex = index - 1;
          final existingCount = _existingImageUrls.length;

          if (actualIndex < existingCount) {
            return Container(
              width: 100.h,
              margin: EdgeInsets.only(right: 12.w),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      _existingImageUrls[actualIndex],
                      fit: BoxFit.cover,
                      width: 100.h,
                      height: 100.h,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeExistingImage(actualIndex),
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final newImageIndex = actualIndex - existingCount;
          return Container(
            width: 100.h,
            margin: EdgeInsets.only(right: 12.w),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                      _webImages[newImageIndex],
                      fit: BoxFit.cover,
                      width: 100.h,
                      height: 100.h
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeNewImage(newImageIndex),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: Text(text,
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14.sp)),
  );

  Widget _buildMinimalBoxChips(
      List<String> options, String selectedValue, Function(String) onSelected) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.black12,
                width: isSelected ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMinimalDisclaimer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToDisclaimer,
            activeColor: Colors.black,
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.black12),
            onChanged: (val) => setState(() => _agreedToDisclaimer = val!),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: const Text(
              "본 제품이 가품일 경우 발생하는 모든 법적 책임은 등록자에게 있으며, SWAP-FIT은 어떠한 책임도 지지 않음에 동의합니다.",
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}