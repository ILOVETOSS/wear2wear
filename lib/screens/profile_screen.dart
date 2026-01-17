import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'upload_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUid;
  final Map<String, dynamic>? editItem;

  const ProfileScreen({
    super.key,
    this.targetUid,
    this.editItem,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ✅ 클래스 레벨에서 인스턴스를 유지하여 초기화 문제를 방지합니다.
  final ImageCropper _imageCropper = ImageCropper();
  bool _isUploading = false;
  late String _displayUid;
  bool _isMe = false;

  int _activeMenuIndex = 0;
  final Color _pointColor = const Color(0xFFB3EB00);

  @override
  void initState() {
    super.initState();
    final currentUser = supabase.auth.currentUser;
    _displayUid = widget.targetUid ?? currentUser?.id ?? '';
    _isMe = _displayUid == currentUser?.id;
  }

  // --- 프로필 사진 업데이트 (초기화 및 웹 에러 해결 버전) ---
  Future<void> _updateProfileImage() async {
    if (!_isMe) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);

    if (image == null) return;

    // ✅ cropImage 호출 시 인스턴스화된 _imageCropper 사용
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
          presentStyle: WebPresentStyle.dialog, // 웹 초기화 에러에 가장 안정적인 방식
          size: const CropperSize(width: 520, height: 520),
          // translations 항목은 생략하여 기본값(영어)을 사용하게 함으로써 컴파일 에러 원천 차단
        ),
      ],
    );

    if (croppedFile == null) return;
    if (mounted) setState(() => _isUploading = true);

    try {
      final imageBytes = await croppedFile.readAsBytes();
      final fileExt = croppedFile.path.split('.').last;
      final fileName = '$_displayUid.$fileExt';

      await supabase.storage.from('avatars').uploadBinary(
          fileName, imageBytes, fileOptions: const FileOptions(upsert: true));

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      final String finalImageUrl = "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}";

      await supabase.from('profiles').upsert({
        'id': _displayUid,
        'avatar_url': finalImageUrl,
        'updated_at': DateTime.now().toIso8601String()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("프로필 사진이 업데이트되었습니다.")),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- 상세 정보 시트 ---
  void _showItemDetailSheet(Map<String, dynamic> item) {
    final List<String> allImages = [];
    if (item['image_url'] != null) allImages.add(item['image_url'].toString());
    if (item['images'] != null && item['images'] is List) {
      allImages.addAll(List<String>.from(item['images'].map((e) => e.toString())));
    }

    int activeIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 400.h,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: allImages.length,
                          onPageChanged: (index) => setModalState(() => activeIndex = index),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                              child: Image.network(
                                  allImages[index], width: double.infinity,
                                  fit: BoxFit.cover),
                            );
                          },
                        ),
                        Positioned(
                          top: 20, right: 20,
                          child: IconButton(
                            icon: const CircleAvatar(
                                backgroundColor: Colors.black,
                                child: Icon(Icons.close, color: Colors.white, size: 20)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 20, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (index) =>
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: activeIndex == index ? 10 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: activeIndex == index ? Colors.black : Colors.black12,
                                    ),
                                  )),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['brand']?.toUpperCase() ?? 'BRAND',
                              style: TextStyle(
                                  color: Colors.black.withOpacity(0.4),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(item['title'] ?? 'ITEM NAME',
                              style: TextStyle(color: Colors.black, fontSize: 24.sp, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 25),
                          const Divider(color: Colors.black12),
                          _buildDetailRow("상태", item['condition'] ?? "좋음"),
                          _buildDetailRow("사이즈", item['size'] ?? "FREE"),
                          _buildDetailRow("카테고리", item['category'] ?? "기타"),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: _isMe ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => UploadScreen(editItem: item)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: _pointColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("수정하기", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(item);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("삭제하기", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ) : ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: _pointColor,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("교환 신청하기", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("삭제할까요?", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.black38))),
          TextButton(
            onPressed: () async {
              await supabase.from('clothes').delete().eq('id', item['id']);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isMe ? "MY PAGE" : "CLOSET", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isMe) IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.black45), onPressed: () async => await supabase.auth.signOut()),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            if (_isMe) _buildIconMenuGrid(),
            const Divider(height: 8, color: Color(0xFFF8F8F8)),
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: _updateProfileImage,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _displayUid),
              builder: (context, profileSnap) {
                final avatarUrl = profileSnap.data?.isNotEmpty == true ? profileSnap.data!.first['avatar_url'] : null;
                return Stack(
                  children: [
                    CircleAvatar(
                      radius: 38.w,
                      backgroundColor: const Color(0xFFF5F5F5),
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          : (avatarUrl == null ? Icon(Icons.person, color: Colors.black12, size: 40.w) : null),
                    ),
                    if (_isMe)
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 12.w, backgroundColor: Colors.black, child: Icon(Icons.camera_alt, color: _pointColor, size: 12.w))),
                  ],
                );
              },
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isMe ? (supabase.auth.currentUser?.email?.split('@')[0] ?? "User") : "상대방의 옷장",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.black)),
                const SizedBox(height: 6),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
                  builder: (context, snap) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                    child: Text("TOTAL ${snap.data?.length ?? 0} ITEMS", style: TextStyle(color: _pointColor, fontSize: 10.sp, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconMenuGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuItem(0, Icons.checkroom_outlined, "내 옷장"),
          _buildMenuItem(1, Icons.swap_horiz_rounded, "스왑내역"),
          _buildMenuItem(2, Icons.bookmark_border_rounded, "위시리스트"),
          _buildMenuItem(3, Icons.favorite_border_rounded, "하트목록"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    bool isActive = _activeMenuIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeMenuIndex = index),
      child: Column(
        children: [
          Icon(icon, size: 28.w, color: isActive ? Colors.black : Colors.black26),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: isActive ? FontWeight.w900 : FontWeight.w500, color: isActive ? Colors.black : Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeMenuIndex) {
      case 0: return _buildMyClothesTab();
      case 1: return _buildSwapHistoryTab();
      case 2: return _buildWishlistTab();
      case 3: return _buildLikedItemsTab();
      default: return _buildMyClothesTab();
    }
  }

  Widget _buildMyClothesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _pointColor));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyState("등록된 옷이 없습니다.");
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15.h, crossAxisSpacing: 15.w, childAspectRatio: 0.78),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildClosetItem(items[index]),
        );
      },
    );
  }

  Widget _buildSwapHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('swaps').select().or('from_user_id.eq.$_displayUid,to_user_id.eq.$_displayUid').eq('status', 'accepted'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _pointColor));
        final swaps = snapshot.data ?? [];
        if (swaps.isEmpty) return _buildEmptyState("완료된 스왑이 없습니다.");
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          itemCount: swaps.length,
          itemBuilder: (context, index) => _buildSwapHistoryCard(swaps[index]),
        );
      },
    );
  }

  Widget _buildWishlistTab() => _buildEmptyState("위시리스트 기능 개발 중");
  Widget _buildLikedItemsTab() => _buildEmptyState("하트목록 기능 개발 중");

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80.h),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.black26))),
    );
  }

  Widget _buildSwapHistoryCard(Map<String, dynamic> swap) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("스왑 완료", style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(color: _pointColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12.r)),
                child: Text("완료", style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text("스왑 일자: ${swap['updated_at']?.toString().split('T')[0] ?? ''}", style: TextStyle(color: Colors.black45, fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _buildClosetItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showItemDetailSheet(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12.r)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.black12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['brand']?.toUpperCase() ?? 'BRAND', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(item['title'] ?? 'ITEM NAME', style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}