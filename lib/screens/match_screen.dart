import 'package:flutter/material.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'chat_screen.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SwapService service = SwapService();
    final String uid = supabase.auth.currentUser!.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true,
          title: const Text(
            "ACTIVITY",
            style: TextStyle(
              color: Color(0xFFE2FF00),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFE2FF00),
            labelColor: Color(0xFFE2FF00),
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "채팅방"),
              Tab(text: "내 활동"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 탭 1: 수락된 채팅 목록
            _buildChatList(uid),
            // 탭 2: 통합된 요청 목록 (받은 것 + 보낸 것)
            _buildCombinedRequestList(uid, service),
          ],
        ),
      ),
    );
  }

  // --- 탭 1: 채팅방 목록 (수정됨) ---
  Widget _buildChatList(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('swaps').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
        }

        final all = snapshot.data ?? [];
        // 🔥 필드명 수정: sender_id -> from_user_id, receiver_id -> to_user_id
        final accepted = all.where((c) =>
        (c['from_user_id'] == uid || c['to_user_id'] == uid) && c['status'] == 'accepted'
        ).toList();

        if (accepted.isEmpty) {
          return const Center(child: Text("진행 중인 채팅이 없습니다.", style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          itemCount: accepted.length,
          itemBuilder: (context, index) {
            final chat = accepted[index];
            final isIRequested = chat['from_user_id'] == uid;
            // 🔥 필드명 수정: receiver_clothes_id -> target_item_id 등
            final targetClothesId = isIRequested ? chat['target_item_id'] : chat['my_item_id'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: supabase.from('clothes').select().eq('id', targetClothesId ?? '').maybeSingle(),
              builder: (context, snap) {
                final brand = snap.data?['brand'] ?? "스왑 대화";
                final imageUrl = snap.data?['image_url'];

                return ListTile(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(swapId: chat['id']))
                  ),
                  leading: CircleAvatar(
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    backgroundColor: Colors.white10,
                    child: imageUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
                  ),
                  title: Text(brand, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("대화를 계속하려면 터치하세요", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFE2FF00)),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 탭 2: 통합 스왑 현황 (수정됨) ---
  Widget _buildCombinedRequestList(String uid, SwapService service) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('swaps').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE2FF00)));
        }

        final all = snapshot.data ?? [];
        // 🔥 필드명 수정: from_user_id, to_user_id
        final requests = all.where((c) =>
        (c['from_user_id'] == uid || c['to_user_id'] == uid) && c['status'] == 'pending'
        ).toList();

        if (requests.isEmpty) {
          return const Center(child: Text("대기 중인 요청이 없습니다.", style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) => _requestCard(context, requests[index], service, uid),
        );
      },
    );
  }

  Widget _requestCard(BuildContext context, Map<String, dynamic> req, SwapService service, String uid) {
    // 🔥 필드명 수정: receiver_id -> to_user_id
    final bool isReceived = req['to_user_id'] == uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isReceived ? const Color(0xFFE2FF00).withOpacity(0.3) : Colors.white10
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReceived ? const Color(0xFFE2FF00) : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isReceived ? "받은 제안" : "보낸 제안",
                  style: TextStyle(
                      color: isReceived ? Colors.black : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const Text("대기 중", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 🔥 필드명 수정: sender_clothes_id -> my_item_id / target_item_id에 맞게 매칭
              _miniImg(isReceived ? req['my_item_id'] : req['my_item_id'], isReceived ? "상대의 옷" : "나의 옷"),
              const Icon(Icons.swap_horiz, color: Color(0xFFE2FF00), size: 30),
              _miniImg(isReceived ? req['target_item_id'] : req['target_item_id'], isReceived ? "나의 옷" : "상대의 옷"),
            ],
          ),
          const SizedBox(height: 20),
          if (isReceived)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => service.rejectRequest(req['id']),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                    child: const Text("거절", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => service.acceptRequest(req['id']),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2FF00)),
                    child: const Text("수락", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          else
            const Text(
              "상대방의 응답을 기다리고 있습니다",
              style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _miniImg(String? id, String label) {
    if (id == null) return const SizedBox();
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase.from('clothes').select().eq('id', id).maybeSingle(),
      builder: (context, snap) {
        final url = snap.data?['image_url'];
        return Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white10,
                image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
              ),
              child: url == null ? const Icon(Icons.image_not_supported, color: Colors.white10) : null,
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        );
      },
    );
  }
}