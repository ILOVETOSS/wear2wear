import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ImageCropper _imageCropper = ImageCropper();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null && mounted) {
        setState(() {
          _currentAvatarUrl = profileData['avatar_url'];
          _nicknameController.text = profileData['nickname'] ?? '';
          _bioController.text = profileData['bio'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("프로필 로드 에러: $e");
    }
  }

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final croppedFile = await _imageCropper.cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '프로필 사진 편집',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.black,
        ),
        IOSUiSettings(title: '프로필 사진 편집'),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 520, height: 520),
        ),
      ],
    );

    if (croppedFile == null) return;
    if (mounted) setState(() => _isUploading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final imageBytes = await croppedFile.readAsBytes();
      final fileExt = croppedFile.path.split('.').last;
      final fileName = '$userId.$fileExt';

      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: FileOptions(upsert: true),
      );

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      final String finalImageUrl = "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}";

      setState(() {
        _currentAvatarUrl = finalImageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("프로필 사진이 변경되었습니다"),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      debugPrint("이미지 업로드 에러: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("닉네임을 입력해주세요"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('profiles').upsert({
        'id': userId,
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar_url': _currentAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("프로필이 저장되었습니다"),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("저장 실패"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "프로필 수정",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
                : Text(
              "저장",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // 프로필 사진
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60.w,
                    backgroundColor: const Color(0xFFF5F5F5),
                    backgroundImage: _currentAvatarUrl != null
                        ? NetworkImage(_currentAvatarUrl!)
                        : null,
                    child: _isUploading
                        ? const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    )
                        : (_currentAvatarUrl == null
                        ? Icon(
                      Icons.person,
                      color: Colors.black12,
                      size: 60.w,
                    )
                        : null),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _updateProfileImage,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18.w,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 48.h),

            // 닉네임
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "닉네임",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _nicknameController,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: "닉네임을 입력하세요",
                    hintStyle: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15.sp,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 소개
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "소개",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: "자신을 소개해주세요",
                    hintStyle: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 15.sp,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 48.h),

            // 안내 문구
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.black54,
                    size: 20,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "프로필 정보는 다른 사용자에게 공개됩니다",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}