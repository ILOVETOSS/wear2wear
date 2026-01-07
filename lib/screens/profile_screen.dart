import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  // 📸 프로필 이미지 업데이트
  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;
    if (mounted) setState(() => _isUploading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw '로그인이 필요합니다.';
      final imageBytes = await image.readAsBytes();
      final fileName = '${user.id}.${image.path.split('.').last}';
      await supabase.storage.from('avatars').uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));
      final String imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      await supabase.from('profiles').upsert({'id': user.id, 'avatar_url': imageUrl, 'updated_at': DateTime.now().toIso8601String()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("프로필 사진이 변경되었습니다!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("업로드 실패: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // 🔥 상세 정보 바텀 시트 (static 에러 수정 및 슬라이드 최적화)
  void _showItemDetailSheet(Map<String, dynamic> item) {
    // 1. 이미지 데이터 정리
    final List<String> allImages = [];
    if (item['image_url'] != null) allImages.add(item['image_url'].toString());
    if (item['images'] != null && item['images'] is List) {
      allImages.addAll(List<String>.from(item['images'].map((e) => e.toString())));
    }

    // 바텀시트 내부 상태 관리를 위한 변수 (static 제거)
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
                    height: 450,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: allImages.length,
                          physics: const ClampingScrollPhysics(), // 슬라이드 우선 순위 강화
                          onPageChanged: (index) {
                            // 🔥 setModalState를 통해 activeIndex를 업데이트해야 점이 바뀝니다.
                            setModalState(() {
                              activeIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                              child: Image.network(
                                allImages[index],
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                        // 닫기 버튼
                        Positioned(
                          top: 20, right: 20,
                          child: IconButton(
                            icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // 🔥 하단 점 (Indicator)
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 25, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: activeIndex == index ? 10 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: activeIndex == index
                                        ? const Color(0xFFE2FF00)
                                        : Colors.white.withOpacity(0.3),
                                  ),
                                );
                              }),
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
                          Text(item['title'] ?? 'ITEM NAME', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 25),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 20),
                          _buildDetailRow("상태", item['condition'] ?? "좋음"),
                          _buildDetailRow("사이즈", item['size'] ?? "FREE"),
                          _buildDetailRow("카테고리", item['category'] ?? "기타"),
                        ],
                      ),
                    ),
                  ),
                  // --- 버튼 영역 ---
                  Padding(
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
        content: const Text("복구할 수 없습니다.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              await supabase.from('clothes').delete().eq('id', item['id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final SwapService swapService = SwapService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("프로필", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: () async => await supabase.auth.signOut()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isUploading ? null : _updateProfileImage,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', user?.id ?? ''),
                    builder: (context, profileSnap) {
                      final avatarUrl = profileSnap.data?.isNotEmpty == true ? profileSnap.data!.first['avatar_url'] : null;
                      return CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFE2FF00),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF1A1A1A),
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white24, size: 40) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.email ?? "User", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: swapService.getMyCloset(),
                      builder: (context, snap) => Text("나의 옷장 ${snap.data?.length ?? 0}벌", style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: swapService.getMyCloset(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
                final myItems = snapshot.data ?? [];
                if (myItems.isEmpty) return const Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.white24)));

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.72,
                  ),
                  itemCount: myItems.length,
                  itemBuilder: (context, index) => _buildClosetItem(myItems[index]),
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
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 40)),
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