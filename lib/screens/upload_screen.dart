import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/database_service.dart';

class UploadScreen extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  const UploadScreen({super.key, this.editItem});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();

  // ✅ 사진 관리를 위한 리스트 (최대 4장)
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _webImages = [];
  bool _isUploading = false;

  // 상태 관리 변수들
  String _authStatus = '모름';
  String _tradeType = '둘다 가능';
  bool _agreedToDisclaimer = false;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ootdContentController = TextEditingController();
  String _selectedOotdCategory = '스트릿';

  // 디자인 포인트 컬러
  final Color _pointColor = const Color(0xFFB3EB00);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ✅ 다중 이미지 선택 (최대 4장 제한)
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사진은 최대 4장까지 등록 가능합니다.")),
      );
      return;
    }

    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 50,
    );

    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        if (_selectedImages.length < 4) {
          final bytes = await file.readAsBytes();
          setState(() {
            _selectedImages.add(file);
            _webImages.add(bytes);
          });
        }
      }
    }
  }

  // ✅ 이미지 개별 삭제
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _webImages.removeAt(index);
    });
  }

  // ✅ 데이터 저장 로직
  Future<void> _handleSave() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("최소 1장의 이미지를 선택해주세요.")));
      return;
    }

    if (_tabController.index == 0 && !_agreedToDisclaimer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("법적 책임 면책 조항에 동의해야 등록이 가능합니다.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    bool success = false;

    // ✅ DatabaseService에 리스트 전체(imageFiles) 전달
    if (_tabController.index == 0) {
      success = await _dbService.uploadClothingItem(
        imageFiles: _selectedImages,
        brand: _brandController.text,
        title: _titleController.text,
        extraData: {
          'trade_type': _tradeType,
          'auth_status': _authStatus,
          'disclaimer_agreed': _agreedToDisclaimer,
        },
      );
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
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("등록 중 오류가 발생했습니다. DB 설정을 확인해주세요.")),
        );
      }
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("UPLOAD",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [Tab(text: "내 옷 등록"), Tab(text: "OOTD 공유")],
        ),
      ),
      body: _isUploading
          ? Center(child: CircularProgressIndicator(color: _pointColor))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildForm(true),
          _buildForm(false),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 34.h), // 하단 여백 최적화
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isUploading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: _pointColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0),
          child: const Text("등록하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildForm(bool isClothing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 가로 스크롤 이미지 피커
          _buildMultiImagePicker(),
          const SizedBox(height: 30),

          if (isClothing) ...[
            _label("브랜드"),
            _buildTextField(_brandController, "예: 나이키"),
            const SizedBox(height: 20),
            _label("아이템 명"),
            _buildTextField(_titleController, "예: 조던 1 레트로"),
            const SizedBox(height: 30),
            _label("거래 방식"),
            _buildChoiceChips(['판매만', '스왑만', '둘다 가능'], _tradeType, (val) {
              setState(() => _tradeType = val);
            }),
            const SizedBox(height: 20),
            _label("정품 여부"),
            _buildChoiceChips(['정품', '가품', '모름'], _authStatus, (val) {
              setState(() => _authStatus = val);
            }),
            const SizedBox(height: 30),
            const Divider(color: Colors.black12),
            const SizedBox(height: 10),
            _buildDisclaimerTile(),
          ] else ...[
            _label("카테고리"),
            _buildOotdCategoryChips(),
            const SizedBox(height: 20),
            _label("코디 설명"),
            _buildTextField(_ootdContentController, "스타일을 설명해주세요", maxLines: 4),
          ],
        ],
      ),
    );
  }

  // ✅ 다중 이미지 선택 UI (가로 스크롤)
  Widget _buildMultiImagePicker() {
    return SizedBox(
      height: 110.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 110.h,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                    const SizedBox(height: 5),
                    Text("${_selectedImages.length}/4",
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          int imgIndex = index - 1;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                Container(
                  width: 110.h,
                  height: 110.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: MemoryImage(_webImages[imgIndex]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => _removeImage(imgIndex),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildChoiceChips(List<String> options, String selectedValue, Function(String) onSelected) {
    return Wrap(
      spacing: 10,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: Colors.black,
          backgroundColor: const Color(0xFFF5F5F5),
          labelStyle: TextStyle(
            color: isSelected ? _pointColor : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }

  Widget _buildDisclaimerTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _agreedToDisclaimer ? Colors.black : Colors.transparent),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _agreedToDisclaimer,
            activeColor: Colors.black,
            checkColor: _pointColor,
            onChanged: (val) => setState(() => _agreedToDisclaimer = val!),
          ),
          const Expanded(
            child: Text(
              "본 제품이 가품일 경우 발생하는 모든 법적 책임은 등록자에게 있으며, SWAP-FIT은 어떠한 책임도 지지 않음에 동의합니다.",
              style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOotdCategoryChips() {
    final cats = ['스트릿', '미니멀', '빈티지', '캐주얼'];
    return Wrap(
      spacing: 10,
      children: cats.map((c) => ChoiceChip(
        label: Text(c),
        selected: _selectedOotdCategory == c,
        onSelected: (v) => setState(() => _selectedOotdCategory = c),
        selectedColor: Colors.black,
        backgroundColor: const Color(0xFFF5F5F5),
        labelStyle: TextStyle(
          color: _selectedOotdCategory == c ? _pointColor : Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )).toList(),
    );
  }
}