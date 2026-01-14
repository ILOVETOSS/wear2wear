import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isUploading = false;
  late String _displayUid;
  bool _isMe = false;

  final Color _pointColor = const Color(0xFFB3EB00);

  @override
  void initState() {
    super.initState();
    final currentUser = supabase.auth.currentUser;
    _displayUid = widget.targetUid ?? currentUser?.id ?? '';
    _isMe = _displayUid == currentUser?.id;
  }

  Future<void> _updateProfileImage() async {
    if (!_isMe) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    if (mounted) setState(() => _isUploading = true);

    try {
      final imageBytes = await image.readAsBytes();
      final fileName = '$_displayUid.${image.path.split('.').last}';

      await supabase.storage.from('avatars').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(upsert: true)
      );

      final String imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase.from('profiles').upsert({
        'id': _displayUid,
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String()
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("프로필 사진이 변경되었습니다!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("업로드 실패: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
                              child: Image.network(allImages[index], width: double.infinity, fit: BoxFit.cover),
                            );
                          },
                        ),
                        Positioned(
                          top: 20, right: 20,
                          child: IconButton(
                            icon: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.close, color: Colors.white, size: 20)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 20, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: activeIndex == index ? 10 : 7, height: 7,
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
                              style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 14.sp, fontWeight: FontWeight.w900)),
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
                              elevation: 0,
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
                              elevation: 0,
                            ),
                            child: const Text("삭제하기", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ) : ElevatedButton(
                      onPressed: () { /* 교환 신청 로직 */ },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: _pointColor,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
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
              if (mounted) { Navigator.pop(context); setState(() {}); }
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
        title: Text(_isMe ? "MY CLOSET" : "CLOSET",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isMe) IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.black45),
              onPressed: () async => await supabase.auth.signOut()
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _updateProfileImage,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _displayUid),
                    builder: (context, profileSnap) {
                      final avatarUrl = profileSnap.data?.isNotEmpty == true ? profileSnap.data!.first['avatar_url'] : null;
                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                        child: CircleAvatar(
                          radius: 38.w,
                          backgroundColor: const Color(0xFFF5F5F5),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? const Icon(Icons.person, color: Colors.black12, size: 40) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isMe ? (supabase.auth.currentUser?.email?.split('@')[0] ?? "User") : "상대방의 옷장",
                          style: TextStyle(color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
                        builder: (context, snap) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                          child: Text("TOTAL ${snap.data?.length ?? 0} ITEMS",
                              style: TextStyle(color: _pointColor, fontSize: 10.sp, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.black12, height: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _pointColor));
                final items = snapshot.data ?? [];
                if (items.isEmpty) return const Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.black26)));

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15.h,
                    crossAxisSpacing: 15.w,
                    childAspectRatio: 0.78, // 이미지 가시성을 높이기 위해 비율 조정
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildClosetItem(items[index]),
                );
              },
            ),
          ),
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
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['image_url'] ?? '',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.black12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    item['brand']?.toUpperCase() ?? 'BRAND',
                    style: TextStyle(color: Colors.black, fontSize: 11.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                ),
                const SizedBox(height: 2),
                Text(
                    item['title'] ?? 'ITEM NAME',
                    style: TextStyle(color: Colors.black45, fontSize: 13.sp, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}