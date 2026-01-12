import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
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

  // ✅ 새로운 상태 변수들
  String _authStatus = '모름'; // 정품, 가품, 모름
  String _tradeType = '둘다 가능'; // 판매만, 스왑만, 둘다 가능
  bool _agreedToDisclaimer = false; // 법적 면책 동의

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ootdContentController = TextEditingController();
  String _selectedOotdCategory = '스트릿';

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

    // ✅ 내 옷 등록일 경우 면책 동의 필수 체크
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
          'trade_type': _tradeType,    // 판매, 스왑, 둘다
          'auth_status': _authStatus,  // 정품, 가품, 모름
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("UPLOAD", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE2FF00),
          labelColor: const Color(0xFFE2FF00),
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: "내 옷 등록"), Tab(text: "OOTD 공유")],
        ),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildForm(true),
          _buildForm(false),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2FF00),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
          ),
          child: const Text("등록하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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

            // ✅ 거래 방식 선택 (판매/스왑/둘다)
            _label("거래 방식"),
            _buildChoiceChips(['판매만', '스왑만', '둘다 가능'], _tradeType, (val) {
              setState(() => _tradeType = val);
            }),
            const SizedBox(height: 20),

            // ✅ 정품 여부 선택 (정품/가품/모름)
            _label("정품 여부"),
            _buildChoiceChips(['정품', '가품', '모름'], _authStatus, (val) {
              setState(() => _authStatus = val);
            }),
            const SizedBox(height: 30),

            // ✅ 법적 면책 조항 동의
            const Divider(color: Colors.white24),
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

  // ✅ 선택 칩 위젯 (거래방식, 정품여부 공용)
  Widget _buildChoiceChips(List<String> options, String selectedValue, Function(String) onSelected) {
    return Wrap(
      spacing: 10,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: const Color(0xFFE2FF00),
          backgroundColor: const Color(0xFF1A1A1A),
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      }).toList(),
    );
  }

  // ✅ 법적 면책 조항 타일
  Widget _buildDisclaimerTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _agreedToDisclaimer ? const Color(0xFFE2FF00) : Colors.white10),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _agreedToDisclaimer,
            activeColor: const Color(0xFFE2FF00),
            checkColor: Colors.black,
            onChanged: (val) => setState(() => _agreedToDisclaimer = val!),
          ),
          const Expanded(
            child: Text(
              "본 제품이 가품일 경우 발생하는 모든 법적 책임은 등록자에게 있으며, SWAP-FIT은 어떠한 책임도 지지 않음에 동의합니다.",
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
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
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10)
        ),
        child: _webImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_webImage!, fit: BoxFit.cover))
            : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 50, color: Color(0xFFE2FF00)),
                SizedBox(height: 10),
                Text("사진 추가", style: TextStyle(color: Colors.white24)),
              ],
            )
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24),
        filled: true, fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        selectedColor: const Color(0xFFE2FF00),
        labelStyle: TextStyle(color: _selectedOotdCategory == c ? Colors.black : Colors.white),
      )).toList(),
    );
  }
}