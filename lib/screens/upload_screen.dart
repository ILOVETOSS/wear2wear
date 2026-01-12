import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UploadScreen extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  const UploadScreen({super.key, this.editItem});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late TextEditingController _brandController;
  late TextEditingController _titleController;
  late TextEditingController _priceController;

  XFile? _mainImage;
  List<XFile?> _detailImages = [null, null, null];

  bool _isUploading = false;
  bool get isEditMode => widget.editItem != null;

  // ✅ 추가된 상태 변수들
  String _authenticity = '모름'; // 정품, 가품, 모름
  String _tradeType = '둘다 가능'; // 교환만, 판매만, 둘다 가능
  bool _responsibilityAgreed = false;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.editItem?['brand'] ?? '');
    _titleController = TextEditingController(text: widget.editItem?['title'] ?? '');
    _priceController = TextEditingController(text: widget.editItem?['price']?.toString() ?? '');
  }

  // 정품 선택 시 책임 동의 팝업
  void _showResponsibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("⚠️ 정품 인증 주의사항", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: const Text(
          "해당 제품이 정품이 아닐 경우, 모든 민·형사상 책임은 게시자 본인에게 있으며 서비스 이용이 영구 제한될 수 있습니다. 이에 동의하십니까?",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _authenticity = '모름';
                _responsibilityAgreed = false;
              });
              Navigator.pop(context);
            },
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _responsibilityAgreed = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("동의 및 진행", style: TextStyle(color: Color(0xFFE2FF00))),
          ),
        ],
      ),
    );
  }

  Future<String> _uploadFile(XFile file, String prefix) async {
    final bytes = await file.readAsBytes();
    final fileExt = file.name.split('.').last.toLowerCase();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await supabase.storage.from('clothing-images').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
    );

    return supabase.storage.from('clothing-images').getPublicUrl(fileName);
  }

  Future<void> _handleSave() async {
    if (_brandController.text.trim().isEmpty || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("브랜드와 이름을 입력해주세요.")));
      return;
    }

    if (_authenticity == '정품' && !_responsibilityAgreed) {
      _showResponsibilityDialog();
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("로그인 정보가 없습니다.");

      String mainUrl = widget.editItem?['image_url'] ?? '';
      if (_mainImage != null) mainUrl = await _uploadFile(_mainImage!, 'main');

      List<String> detailUrls = isEditMode ? List<String>.from(widget.editItem?['images'] ?? []) : [];
      for (var file in _detailImages) {
        if (file != null) detailUrls.add(await _uploadFile(file, 'detail'));
      }

      final Map<String, dynamic> itemData = {
        'user_id': user.id,
        'brand': _brandController.text.trim(),
        'title': _titleController.text.trim(),
        'price': _tradeType == '교환만' ? 0 : int.tryParse(_priceController.text) ?? 0,
        'image_url': mainUrl,
        'images': detailUrls,
        'authenticity': _authenticity,
        'trade_type': _tradeType,
        'responsibility_agreed': _responsibilityAgreed,
        'owner_name': user.userMetadata?['full_name'] ?? '사용자',
      };

      if (isEditMode) {
        await supabase.from('clothes').update(itemData).eq('id', widget.editItem!['id']);
      } else {
        await supabase.from('clothes').insert(itemData);
      }

      if (mounted) {
        MainNavigationScreen.navKey.currentState?.changeTab(4);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("등록 완료!")));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(isEditMode ? "아이템 수정" : "새 옷 등록", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("대표 사진"),
            _buildMainImagePicker(),
            const SizedBox(height: 24),
            _sectionTitle("상세 사진 (최대 3장)"),
            _buildDetailImagePickers(),
            const SizedBox(height: 32),

            // ✅ 정가품 선택 섹션
            _sectionTitle("정가품 여부"),
            Row(
              children: ['정품', '가품', '모름'].map((type) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(type)),
                    selected: _authenticity == type,
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(color: _authenticity == type ? const Color(0xFFE2FF00) : Colors.black),
                    onSelected: (val) {
                      setState(() => _authenticity = type);
                      if (type == '정품') _showResponsibilityDialog();
                    },
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // ✅ 거래 방식 선택 섹션
            _sectionTitle("거래 방식"),
            Row(
              children: ['교환만', '판매만', '둘다 가능'].map((type) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(type)),
                    selected: _tradeType == type,
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(color: _tradeType == type ? const Color(0xFFE2FF00) : Colors.black),
                    onSelected: (val) => setState(() => _tradeType = type),
                  ),
                ),
              )).toList(),
            ),
            if (_tradeType != '교환만') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration("판매 가격 (₩)"),
              ),
            ],
            const SizedBox(height: 24),

            TextField(controller: _brandController, style: const TextStyle(color: Colors.black), decoration: _inputDecoration("브랜드명")),
            const SizedBox(height: 16),
            TextField(controller: _titleController, style: const TextStyle(color: Colors.black), decoration: _inputDecoration("아이템 이름")),

            const SizedBox(height: 40),
            _isUploading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isEditMode ? "수정 완료" : "등록하기", style: const TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
  );

  Widget _buildMainImagePicker() {
    return GestureDetector(
      onTap: () async {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 40);
        if (img != null) setState(() => _mainImage = img);
      },
      child: Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: _mainImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(16), child: kIsWeb ? Image.network(_mainImage!.path, fit: BoxFit.cover) : Image.file(File(_mainImage!.path), fit: BoxFit.cover))
            : const Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildDetailImagePickers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) => GestureDetector(
        onTap: () async {
          final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30);
          if (img != null) setState(() => _detailImages[index] = img);
        },
        child: Container(
          width: (MediaQuery.of(context).size.width - 64) / 3,
          height: 100,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: _detailImages[index] != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(_detailImages[index]!.path, fit: BoxFit.cover) : Image.file(File(_detailImages[index]!.path), fit: BoxFit.cover))
              : const Icon(Icons.add, color: Colors.grey),
        ),
      )),
    );
  }
}