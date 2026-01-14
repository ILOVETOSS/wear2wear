import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 추가됨
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

  XFile? _mainImage;
  Uint8List? _webImage;
  bool _isUploading = false;

  // ✅ 기존 기능 그대로 유지
  String _authStatus = '모름';
  String _tradeType = '둘다 가능';
  bool _agreedToDisclaimer = false;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ootdContentController = TextEditingController();
  String _selectedOotdCategory = '스트릿';

  // ✅ 테마 컬러 변수
  final Color _pointColor = const Color(0xFFB3EB00); // 네온 라임

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _mainImage = img;
        _webImage = bytes;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미지를 선택해주세요.")));
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
    if (_tabController.index == 0) {
      success = await _dbService.uploadClothingItem(
        imageFile: _mainImage!,
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
        imageFile: _mainImage!,
        category: _selectedOotdCategory,
        content: _ootdContentController.text,
      );
    }

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 배경 화이트로 변경
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
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // ✅ 버튼 블랙
              foregroundColor: _pointColor,  // ✅ 글자 라임
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0
          ),
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
          _buildImagePickerWidget(),
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
            const SizedBox(height: 20),
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

  Widget _buildChoiceChips(List<String> options, String selectedValue, Function(String) onSelected) {
    return Wrap(
      spacing: 10,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: Colors.black, // ✅ 선택시 블랙 배경
          backgroundColor: const Color(0xFFF5F5F5), // ✅ 미선택시 연회색
          labelStyle: TextStyle(
            color: isSelected ? _pointColor : Colors.black54, // ✅ 선택시 라임 글자
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

  Widget _buildImagePickerWidget() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12)
        ),
        child: _webImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_webImage!, fit: BoxFit.cover))
            : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text("제품 사진 추가", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
              ],
            )
        ),
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
        color: Colors.black, // ✅ 로그인 필드와 동일하게 블랙 배경
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white), // ✅ 글자는 화이트
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
        ),
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