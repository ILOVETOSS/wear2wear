import 'package:flutter/material.dart';
import '../main.dart';
import '../services/swap_service.dart';

class MyClosetScreen extends StatelessWidget {
  const MyClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final SwapService swapService = SwapService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("MY CLOSET", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async => await supabase.auth.signOut(),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: swapService.getMyCloset(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
          }

          final myItems = snapshot.data ?? [];

          return Column(
            children: [
              // 프로필 영역
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 35, backgroundColor: Color(0xFF1A1A1A), child: Icon(Icons.person, color: Colors.white24, size: 40)),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.email?.split('@')[0] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("등록된 옷 ${myItems.length}벌", style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              // 내 옷 목록
              Expanded(
                child: myItems.isEmpty
                    ? const Center(child: Text("등록된 옷이 없습니다.", style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.75,
                  ),
                  itemCount: myItems.length,
                  itemBuilder: (context, index) => _buildClosetItem(myItems[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClosetItem(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(item['image_url'] ?? '', width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.white24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['brand'] ?? 'No Brand', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                Text("Size: ${item['size'] ?? 'M'}", style: const TextStyle(color: Color(0xFFE2FF00), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}