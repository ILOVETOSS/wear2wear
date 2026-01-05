import 'package:flutter/material.dart';
import '../main.dart';
import '../services/swap_service.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SwapService service = SwapService();
    final String uid = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("REQUESTS", style: TextStyle(color: Color(0xFFE2FF00))), backgroundColor: Colors.black),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getReceivedRequests(uid),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) return const Center(child: Text("요청이 없습니다."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _miniImg(req['sender_clothes_id'], "상대의 제안"),
                        const Icon(Icons.swap_horiz, color: Colors.white),
                        _miniImg(req['receiver_clothes_id'], "나의 옷"),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: () => service.rejectRequest(req['id']), child: const Text("거절", style: TextStyle(color: Colors.red)))),
                        Expanded(child: ElevatedButton(
                          onPressed: () => service.acceptRequest(req['id']), // 수정됨: 인자 1개
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2FF00)),
                          child: const Text("수락", style: TextStyle(color: Colors.black)),
                        )),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _miniImg(String id, String label) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase.from('clothes').select().eq('id', id).maybeSingle(),
      builder: (context, snap) {
        final url = snap.data?['image_url'];
        return Column(
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white10, image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        );
      },
    );
  }
}