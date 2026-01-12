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
  Uint8List? _webImage; // 웹 이미지 호환용
  bool _isUploading = false;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ootdContentController = TextEditingController();
  String _selectedOotdCategory = '스트릿';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _brandController.text = widget.editItem?['brand'] ?? '';
    _titleController.text = widget.editItem?['title'] ?? '';
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
    if (_mainImage == null) return;
    setState(() => _isUploading = true);

    bool success = false;
    if (_tabController.index == 0) {
      success = await _dbService.uploadClothingItem(
        imageFile: _mainImage!,
        brand: _brandController.text,
        title: _titleController.text,
        extraData: {'trade_type': '둘다 가능'},
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

  Widget _buildImagePickerWidget() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: _webImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_webImage!, fit: BoxFit.cover))
            : const Center(child: Icon(Icons.add_a_photo_outlined, size: 50, color: Color(0xFFE2FF00))),
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
      )).toList(),
    );
  }
}