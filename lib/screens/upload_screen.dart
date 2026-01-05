import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../main.dart';
import '../services/database_service.dart';
// 💡 아래 경로를 실제 MainNavigationScreen이 있는 파일 경로로 수정하세요!
// import 'main_navigation_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _brandController = TextEditingController();
  final _titleController = TextEditingController();
  XFile? _pickedFile;
  bool _isUploading = false;

  void _handleUpload() async {
    if (_pickedFile == null || _brandController.text.isEmpty) return;

    setState(() => _isUploading = true);
    final newItem = await _dbService.uploadClothingItem(
      imageFile: _pickedFile!,
      brand: _brandController.text,
      title: _titleController.text,
    );

    if (newItem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("등록 성공!")));

      // ✅ 원래 쓰시던 방식 그대로 유지 (단, MainNavigationScreen 클래스가 정의되어 있어야 함)
      // 만약 여전히 에러가 난다면 MainNavigationScreen.navKey가 main.dart 등에 선언되어 있는지 확인하세요.
      try {
        MainNavigationScreen.navKey.currentState?.changeTab(0);
      } catch (e) {
        // navKey 방식이 안될 경우를 대비한 안전장치
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("등록 실패...")));
    }
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Supabase 옷 등록")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (img != null) setState(() => _pickedFile = img);
              },
              child: Container(
                height: 250, width: double.infinity, color: Colors.grey[900],
                child: _pickedFile == null
                    ? const Icon(Icons.add_a_photo)
                    : (kIsWeb ? Image.network(_pickedFile!.path) : Image.file(File(_pickedFile!.path))),
              ),
            ),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: "Brand")),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Item Name")),
            const SizedBox(height: 30),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                onPressed: _handleUpload,
                child: const Text("등록하기")
            ),
          ],
        ),
      ),
    );
  }
}