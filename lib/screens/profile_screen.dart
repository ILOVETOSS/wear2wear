import 'package:flutter/material.dart';
import '../main.dart';
import '../services/swap_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final SwapService swapService = SwapService(); // 옷 데이터를 가져올 서비스

    return Scaffold(
      backgroundColor: Colors.black, // 배경을 검은색으로 (디자인 통일)
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
      // 🔥 StreamBuilder를 사용하여 내 옷 데이터를 실시간으로 가져옵니다.
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: swapService.getMyCloset(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
          }

          final myItems = snapshot.data ?? [];

          return Column(
            children: [
              // --- 유저 정보 영역 ---
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFF1A1A1A),
                      child: Icon(Icons.person, color: Colors.white24, size: 40),
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
                        Text(
                          "내 옷장: ${myItems.length}벌",
                          style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),

              // --- 내 등록 아이템 리스트 영역 ---
              Expanded(
                child: myItems.isEmpty
                    ? const Center(
                  child: Text(
                    "등록된 옷이 없습니다.\n옷을 등록하면 여기에 나타납니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2줄씩 보기
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: myItems.length,
                  itemBuilder: (context, index) {
                    final item = myItems[index];
                    return _buildClosetItem(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 개별 옷 카드 디자인
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