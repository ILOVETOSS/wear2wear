import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "ACTIVITY",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black26,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            indicatorWeight: 4,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabs: const [
              Tab(text: "채팅방"),
              Tab(text: "내 활동"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChatList(uid),
            _buildCombinedRequestList(uid, service),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('swaps').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black), // 🔥 검정색
          );
        }

        final all = snapshot.data ?? [];
        final accepted = all.where((c) =>
        (c['from_user_id'] == uid || c['to_user_id'] == uid) && c['status'] == 'accepted'
        ).toList();

        if (accepted.isEmpty) {
          return const Center(
            child: Text(
              "진행 중인 채팅이 없습니다.",
              style: TextStyle(color: Colors.black26, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: accepted.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, color: Colors.black12),
          itemBuilder: (context, index) {
            final chat = accepted[index];
            final isIRequested = chat['from_user_id'] == uid;
            final targetClothesId = isIRequested ? chat['target_item_id'] : chat['my_item_id'];

            return FutureBuilder<Map<String, dynamic>?>(
              future: supabase.from('clothes').select().eq('id', targetClothesId ?? '').maybeSingle(),
              builder: (context, snap) {
                final brand = snap.data?['brand']?.toString().toUpperCase() ?? "SWAP CHAT";
                final imageUrl = snap.data?['image_url'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(swapId: chat['id']))
                  ),
                  leading: Container(
                    width: 55.w,
                    height: 55.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: const Color(0xFFF5F5F5),
                      border: Border.all(color: Colors.black12),
                      image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                    ),
                    child: imageUrl == null ? const Icon(Icons.person, color: Colors.black12) : null,
                  ),
                  title: Text(brand, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                  subtitle: const Text("대화를 계속하려면 터치하세요", style: TextStyle(color: Colors.black38, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 16),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCombinedRequestList(String uid, SwapService service) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('swaps').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black), // 🔥 검정색
          );
        }

        final all = snapshot.data ?? [];
        final requests = all.where((c) =>
        (c['from_user_id'] == uid || c['to_user_id'] == uid) && c['status'] == 'pending'
        ).toList();

        if (requests.isEmpty) {
          return const Center(
            child: Text(
              "대기 중인 요청이 없습니다.",
              style: TextStyle(color: Colors.black26, fontWeight: FontWeight.bold),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) => _requestCard(context, requests[index], service, uid),
        );
      },
    );
  }

  Widget _requestCard(BuildContext context, Map<String, dynamic> req, SwapService service, String uid) {
    final bool isReceived = req['to_user_id'] == uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
        border: Border.all(
            color: isReceived ? Colors.black : Colors.black12,
            width: 1.5
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isReceived ? Colors.black : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isReceived ? "받은 제안" : "보낸 제안",
                  style: TextStyle(
                      color: isReceived ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900
                  ),
                ),
              ),
              const Text("대기 중", style: TextStyle(color: Colors.black26, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniImg(req['my_item_id'], isReceived ? "상대의 옷" : "나의 옷"),
              Icon(Icons.swap_horiz_rounded, color: Colors.black, size: 32.sp),
              _miniImg(req['target_item_id'], isReceived ? "나의 옷" : "상대의 옷"),
            ],
          ),
          const SizedBox(height: 24),
          if (isReceived)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => service.rejectRequest(req['id']),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    child: const Text("거절", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => service.acceptRequest(req['id']),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    child: const Text("수락", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: const Text(
                "상대방의 응답을 기다리고 있습니다",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w600),
              ),
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
              width: 85.w, height: 85.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: Colors.black12),
                image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
              ),
              child: url == null ? const Icon(Icons.image_not_supported, color: Colors.black12) : null,
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}