import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // 🔥 XFile 사용
import '../services/database_service.dart';
import '../main.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  XFile? _pickedFile; // 🔥 File? 대신 XFile? 사용
  Uint8List? _webImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedFile = image;
        _webImage = bytes;
      });
    }
  }

  void _handleUpload() async {
    if (_pickedFile == null || _brandController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사진과 브랜드명을 입력해주세요!")));
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    bool success = await _dbService.uploadClothingItem(
      imageFile: _pickedFile!, // 🔥 XFile 전달
      brand: _brandController.text,
      title: _titleController.text,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      _brandController.clear();
      _titleController.clear();
      setState(() {
        _pickedFile = null;
        _webImage = null;
      });
      MainNavigationScreen.navKey.currentState?.changeTab(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("의류 등록"), backgroundColor: Colors.black),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D4D)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _pickedFile != null ? const Color(0xFFFF4D4D) : Colors.white24),
                ),
                child: _webImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(_webImage!, fit: BoxFit.cover))
                    : const Icon(Icons.add_a_photo, size: 40, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_brandController, "브랜드"),
            _buildTextField(_titleController, "상품명"),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D4D),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("나의 옷장에 등록하기", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70)),
    );
  }
}