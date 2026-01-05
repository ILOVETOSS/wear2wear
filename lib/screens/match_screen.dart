import 'package:flutter/material.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'chat_screen.dart'; // 채팅 화면 임포트 확인

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SwapService service = SwapService();
    final String uid = supabase.auth.currentUser!.id;

    return DefaultTabController(
      length: 2, // 탭 2개: 받은 요청, 보낸 요청
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("SWAP ACTIVITY",
              style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          bottom: const TabBar(
            indicatorColor: Color(0xFFE2FF00),
            labelColor: Color(0xFFE2FF00),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "받은 요청"),
              Tab(text: "보낸 요청"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. 받은 요청 탭
            _buildRequestList(context, service.getReceivedRequests(uid), service, isReceived: true),
            // 2. 보낸 요청 탭 (service에 getSentRequests 함수가 있어야 함)
            _buildRequestList(context, service.getSentRequests(), service, isReceived: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(BuildContext context, Stream<List<Map<String, dynamic>>> stream, SwapService service, {required bool isReceived}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text("내역이 없습니다.", style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _miniImg(req['sender_clothes_id'], isReceived ? "상대의 제안" : "나의 옷"),
                      const Icon(Icons.swap_horiz, color: Colors.white),
                      _miniImg(req['receiver_clothes_id'], isReceived ? "나의 옷" : "상대의 옷"),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 상태 및 액션 버튼
                  if (isReceived && req['status'] == 'pending')
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: () => service.rejectRequest(req['id']), child: const Text("거절", style: TextStyle(color: Colors.red)))),
                        Expanded(child: ElevatedButton(
                          onPressed: () async {
                            // 1. 수락 처리
                            await service.acceptRequest(req['id']);
                            // 2. 채팅방으로 이동
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ChatScreen(swapId: req['id'])),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2FF00)),
                          child: const Text("수락 및 채팅", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        )),
                      ],
                    )
                  else if (req['status'] == 'accepted')
                  // 이미 수락된 경우 바로 채팅방 가기 버튼 표시
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(swapId: req['id'])),
                          );
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2FF00))),
                        child: const Text("채팅하기", style: TextStyle(color: Color(0xFFE2FF00))),
                      ),
                    )
                  else
                  // 대기 중이거나 거절된 경우 상태 텍스트 표시
                    Text(
                      req['status'] == 'pending' ? "상대방의 답변을 기다리는 중..." : "거절됨",
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniImg(String id, String label) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase.from('clothes').select().eq('id', id).maybeSingle(),
      builder: (context, snap) {
        final url = snap.data?['image_url'];
        return Column(
          children: [
            Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white10,
                    image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null
                )
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        );
      },
    );
  }
}