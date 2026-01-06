import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  // 📸 프로필 이미지 선택 및 업로드 함수 (웹/모바일 공용)
  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // 용량 최적화
    );

    if (image == null) return;

    if (mounted) setState(() => _isUploading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw '로그인이 필요합니다.';

      // 🔥 웹 환경 에러 해결: File 대신 readAsBytes 사용
      final imageBytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}.$fileExt';

      // 1. Supabase Storage 업로드 (uploadBinary 사용)
      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true, // 기존 파일 덮어쓰기 허용
        ),
      );

      // 2. 공개 URL 생성
      final String imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // 3. Database(profiles 테이블) 업데이트
      await supabase.from('profiles').upsert({
        'id': user.id,
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("프로필 사진이 성공적으로 변경되었습니다!")),
        );
      }
    } catch (e) {
      debugPrint("🔥🔥 프로필 업로드 상세 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("업로드 실패: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- 유저 정보 영역 ---
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 프로필 이미지 클릭 섹션
                GestureDetector(
                  onTap: _isUploading ? null : _updateProfileImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🔥 실시간 갱신을 위해 StreamBuilder 적용
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', user?.id ?? ''),
                        builder: (context, profileSnap) {
                          final profileData = profileSnap.data?.isNotEmpty == true ? profileSnap.data!.first : null;
                          final avatarUrl = profileData?['avatar_url'];

                          return CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF1A1A1A),
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null
                                ? const Icon(Icons.person, color: Colors.white24, size: 40)
                                : null,
                          );
                        },
                      ),
                      if (_isUploading)
                        const CircularProgressIndicator(color: Color(0xFFE2FF00)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFE2FF00), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email ?? "정보 없음",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    // 내 옷 개수 실시간 반영
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: swapService.getMyCloset(),
                      builder: (context, snap) => Text(
                        "내 옷장: ${snap.data?.length ?? 0}벌",
                        style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // --- 내 등록 아이템 리스트 영역 ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: swapService.getMyCloset(),
              builder: (context, snapshot) {
                final myItems = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
                }
                if (myItems.isEmpty) {
                  return const Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.white54)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.75,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item['image_url'] ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['brand'] ?? 'No Brand',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item['title'] ?? '멋진 옷',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}