import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadScreen extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  const UploadScreen({super.key, this.editItem});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late TextEditingController _brandController;
  late TextEditingController _titleController;

  XFile? _mainImage;
  List<XFile?> _detailImages = [null, null, null];

  bool _isUploading = false;
  bool get isEditMode => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.editItem?['brand'] ?? '');
    _titleController = TextEditingController(text: widget.editItem?['title'] ?? '');
  }

  // 이미지 업로드 로직
  Future<String> _uploadFile(XFile file, String prefix) async {
    final bytes = await file.readAsBytes();
    final fileExt = file.name.split('.').last.toLowerCase();
    final mimeType = (fileExt == 'jpg' || fileExt == 'jpeg') ? 'jpeg' : 'png';
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await supabase.storage.from('clothing-images').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/$mimeType',
        upsert: true,
      ),
    );

    return supabase.storage.from('clothing-images').getPublicUrl(fileName);
  }

  Future<void> _handleSave() async {
    if (_brandController.text.trim().isEmpty || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("브랜드와 이름을 모두 입력해주세요.")));
      return;
    }

    if (!isEditMode && _mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("대표 사진은 필수입니다.")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("로그인 정보가 없습니다.");

      // 1. 이미지 업로드
      String mainUrl = widget.editItem?['image_url'] ?? '';
      if (_mainImage != null) {
        mainUrl = await _uploadFile(_mainImage!, 'main');
      }

      List<String> detailUrls = isEditMode
          ? List<String>.from(widget.editItem?['images'] ?? [])
          : [];

      for (var file in _detailImages) {
        if (file != null) {
          String url = await _uploadFile(file, 'detail');
          detailUrls.add(url);
        }
      }

      // 2. DB 저장
      final Map<String, dynamic> itemData = {
        'user_id': user.id,
        'brand': _brandController.text.trim(),
        'title': _titleController.text.trim(),
        'image_url': mainUrl,
        'images': detailUrls,
        'size': 'FREE',
        'category': '기타',
        'condition': '좋음',
        'owner_name': user.userMetadata?['full_name'] ?? '사용자',
      };

      if (isEditMode) {
        await supabase.from('clothes').update(itemData).eq('id', widget.editItem!['id']);
      } else {
        await supabase.from('clothes').insert(itemData);
      }

      // 3. ✅ 핵심 수정: 하얀 화면 방지 및 탭 전환
      if (mounted) {
        final mainNav = context.findAncestorStateOfType<MainNavigationScreenState>();

        if (mainNav != null) {
          // 업로드 성공 후 '프로필' 탭(index 4)으로 이동
          mainNav.changeTab(4);

          // 폼 초기화 (다시 업로드 탭으로 올 때를 대비)
          setState(() {
            _brandController.clear();
            _titleController.clear();
            _mainImage = null;
            _detailImages = [null, null, null];
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("성공적으로 등록되었습니다!")));
        } else {
          // 독립 페이지일 경우만 pop
          Navigator.of(context).pop();
        }
      }

    } catch (e) {
      debugPrint("❌ 업로드 에러: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(isEditMode ? "아이템 수정" : "새 옷 등록",
            style: const TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("대표 사진", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMainImagePicker(),
            const SizedBox(height: 30),
            const Text("상세 사진 (최대 3장)", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDetailImagePickers(),
            const SizedBox(height: 30),
            TextField(
                controller: _brandController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("브랜드명 (예: Nike, Zara)")
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("아이템 이름 (예: 빈티지 후드티)")
            ),
            const SizedBox(height: 40),
            _isUploading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)))
                : ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2FF00),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isEditMode ? "수정 완료" : "등록하기",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 100), // 탭바에 가려지지 않게 여백 추가
          ],
        ),
      ),
    );
  }

  Widget _buildMainImagePicker() {
    return GestureDetector(
      onTap: () async {
        final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 40);
        if (img != null) setState(() => _mainImage = img);
      },
      child: Container(
        height: 220, width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10)
        ),
        child: _mainImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(20),
            child: kIsWeb ? Image.network(_mainImage!.path, fit: BoxFit.cover) : Image.file(File(_mainImage!.path), fit: BoxFit.cover))
            : isEditMode
            ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(widget.editItem!['image_url'], fit: BoxFit.cover))
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Color(0xFFE2FF00), size: 45),
            SizedBox(height: 10),
            Text("사진 추가", style: TextStyle(color: Colors.white38))
          ],
        ),
      ),
    );
  }

  Widget _buildDetailImagePickers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () async {
            final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 30);
            if (img != null) setState(() => _detailImages[index] = img);
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 70) / 3,
            height: 100,
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10)
            ),
            child: _detailImages[index] != null
                ? Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: kIsWeb ? Image.network(_detailImages[index]!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : Image.file(File(_detailImages[index]!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                Positioned(right: 0, child: GestureDetector(onTap: () => setState(() => _detailImages[index] = null),
                    child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white))))
              ],
            )
                : const Icon(Icons.add, color: Colors.white24),
          ),
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2FF00), width: 1)),
    );
  }
}