import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../main.dart';

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
  final List<String> _existingImageUrls = []; // 🔥 기존 이미지 URL 저장
  bool _isUploading = false;

  String _authStatus = '모름';
  String _tradeType = '둘다 가능';
  bool _agreedToDisclaimer = false;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ootdContentController = TextEditingController();
  String _selectedOotdCategory = '스트릿';

  // 🔥 수정 모드인지 확인
  bool get isEditMode => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 🔥 수정 모드일 때 기존 데이터 불러오기
    if (isEditMode) {
      _loadExistingData();
    }
  }

  // 🔥 기존 데이터 로드
  void _loadExistingData() {
    final item = widget.editItem!;

    _brandController.text = item['brand'] ?? '';
    _titleController.text = item['title'] ?? '';
    _authStatus = item['auth_status'] ?? '모름';
    _tradeType = item['trade_type'] ?? '둘다 가능';
    _agreedToDisclaimer = item['disclaimer_agreed'] ?? false;

    // 기존 이미지 URL 로드
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

    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 50,
    );

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

  // 🔥 기존 이미지 제거
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

  Future<void> _handleSave() async {
    final totalImages = _selectedImages.length + _existingImageUrls.length;
    if (totalImages == 0) {
      _showSnackBar("최소 1장의 이미지를 선택해주세요.");
      return;
    }

    if (_tabController.index == 0 && !_agreedToDisclaimer) {
      _showSnackBar("법적 책임 면책 조항에 동의해야 등록이 가능합니다.");
      return;
    }

    setState(() => _isUploading = true);

    bool success = false;

    if (_tabController.index == 0) {
      if (isEditMode) {
        // 🔥 수정 모드
        success = await _updateClothingItem();
      } else {
        // 신규 등록
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
        Navigator.pop(context, true); // 🔥 true를 반환하여 수정 완료 알림
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

  // 🔥 옷 수정 로직
  Future<bool> _updateClothingItem() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // 새로 업로드할 이미지들 처리
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

      // 기존 이미지 + 새 이미지 합치기
      final allImageUrls = [..._existingImageUrls, ...newUploadedUrls];

      // DB 업데이트
      await supabase.from('clothes').update({
        'brand': _brandController.text,
        'title': _titleController.text,
        'image_url': allImageUrls.isNotEmpty ? allImageUrls[0] : null,
        'image_urls': allImageUrls,
        'trade_type': _tradeType,
        'auth_status': _authStatus,
        'disclaimer_agreed': _agreedToDisclaimer,
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
            _buildMinimalField(_brandController, "브랜드", "브랜드명을 입력하세요"),
            SizedBox(height: 30.h),
            _buildMinimalField(_titleController, "아이템 명", "아이템 명을 입력하세요"),
            SizedBox(height: 40.h),
            _sectionLabel("거래 방식"),
            _buildMinimalBoxChips(['판매만', '스왑만', '둘다 가능'], _tradeType, (val) {
              setState(() => _tradeType = val);
            }),
            SizedBox(height: 30.h),
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
            _buildMinimalField(_ootdContentController, "코디 설명", "스타일을 설명해주세요", maxLines: 3),
          ],
        ],
      ),
    );
  }

  // 🔥 기존 이미지 + 새 이미지 모두 표시
  Widget _buildMultiImagePicker() {
    final totalCount = _existingImageUrls.length + _selectedImages.length;

    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount + 1,
        itemBuilder: (context, index) {
          // 첫 번째는 추가 버튼
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

          // 기존 이미지 표시
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

          // 새로 추가한 이미지 표시
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

  Widget _buildMinimalField(TextEditingController controller, String label, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14.sp)),
        TextField(
          controller: controller,
          maxLines: maxLines,
          cursorColor: Colors.black,
          showCursor: true,
          style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14.sp),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black12, width: 1.0),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 0),
          ),
        ),
      ],
    );
  }

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