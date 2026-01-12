import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_screen.dart';
import 'dart:typed_data'; // 웹 이미지 처리를 위해 추가

class ProfileScreen extends StatefulWidget {
  final String? targetUid; // 👈 타인 프로필 조회를 위한 ID
  final Map<String, dynamic>? editItem; // 👈 에러 해결을 위한 파라미터 정의

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
  late String _displayUid; // 실제 화면에 보여줄 유저의 ID
  bool _isMe = false;      // 내 프로필인지 여부

  @override
  void initState() {
    super.initState();
    final currentUser = supabase.auth.currentUser;
    // targetUid가 있으면 타인 프로필, 없으면 내 프로필
    _displayUid = widget.targetUid ?? currentUser?.id ?? '';
    _isMe = _displayUid == currentUser?.id;
  }

  // 📸 프로필 이미지 업데이트 (내 프로필일 때만 작동)
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

  // 🔥 아이템 상세 정보 바텀 시트
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
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // --- 이미지 슬라이더 ---
                  SizedBox(
                    height: 400,
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
                            icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
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
                                  color: activeIndex == index ? const Color(0xFFE2FF00) : Colors.white24,
                                ),
                              )),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // --- 상세 정보 ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['brand'] ?? 'BRAND', style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(item['title'] ?? 'ITEM NAME', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white12),
                          _buildDetailRow("상태", item['condition'] ?? "좋음"),
                          _buildDetailRow("사이즈", item['size'] ?? "FREE"),
                          _buildDetailRow("카테고리", item['category'] ?? "기타"),
                        ],
                      ),
                    ),
                  ),
                  // --- 버튼 영역 (본인일 때만 수정/삭제 노출) ---
                  if (_isMe) Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => UploadScreen(editItem: item)));
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("수정하기"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(item);
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text("삭제하기"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ) else Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: ElevatedButton(
                      onPressed: () { /* 교환 신청 로직 */ },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2FF00),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("교환 신청하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("삭제하시겠습니까?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              await supabase.from('clothes').delete().eq('id', item['id']);
              if (mounted) { Navigator.pop(context); setState(() {}); }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SwapService swapService = SwapService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isMe ? "나의 프로필" : "프로필", style: const TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_isMe) IconButton(
              icon: const Icon(Icons.logout, color: Colors.white54),
              onPressed: () async => await supabase.auth.signOut()
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 헤더: 프로필 이미지 및 정보 ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _updateProfileImage,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _displayUid),
                    builder: (context, profileSnap) {
                      final avatarUrl = profileSnap.data?.isNotEmpty == true ? profileSnap.data!.first['avatar_url'] : null;
                      return CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFE2FF00),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF1A1A1A),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white24, size: 40) : (_isUploading ? const CircularProgressIndicator() : null),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isMe ? (supabase.auth.currentUser?.email ?? "User") : "상대방 옷장", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
                      builder: (context, snap) => Text("옷장 ${snap.data?.length ?? 0}벌", style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // --- 옷장 그리드 ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
                final items = snapshot.data ?? [];
                if (items.isEmpty) return const Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.white24)));

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
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
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(item['image_url'] ?? '', width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['brand'] ?? 'BRAND', style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item['title'] ?? 'ITEM', style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}