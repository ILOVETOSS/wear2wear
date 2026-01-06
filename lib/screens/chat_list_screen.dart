import 'package:flutter/material.dart';
import '../main.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CHATS", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🔥 .or() 필터 대신 전체 스트림을 가져와서 아래에서 필터링합니다.
        stream: supabase.from('swaps').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final allChats = snapshot.data ?? [];
          // 🔥 내가 참여자(sender or receiver)이고 상태가 accepted인 것만 필터링
          final acceptedChats = allChats.where((c) =>
          (c['sender_id'] == uid || c['receiver_id'] == uid) && c['status'] == 'accepted'
          ).toList();

          if (acceptedChats.isEmpty) return const Center(child: Text("진행 중인 채팅이 없습니다.", style: TextStyle(color: Colors.white24)));

          return ListView.builder(
            itemCount: acceptedChats.length,
            itemBuilder: (context, index) {
              final chat = acceptedChats[index];
              final bool isIRequested = chat['sender_id'] == uid;
              // 상대방 옷 정보를 가져오기 위한 ID 설정
              final targetClothesId = isIRequested ? chat['receiver_clothes_id'] : chat['sender_clothes_id'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: supabase.from('clothes').select().eq('id', targetClothesId).maybeSingle(),
                builder: (context, itemSnap) {
                  return ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(swapId: chat['id']))),
                    leading: CircleAvatar(
                      backgroundImage: (itemSnap.data != null && itemSnap.data!['image_url'] != null)
                          ? NetworkImage(itemSnap.data!['image_url'])
                          : null,
                      backgroundColor: Colors.white10,
                    ),
                    title: Text(itemSnap.data?['brand'] ?? "스왑 채팅", style: const TextStyle(color: Colors.white)),
                    subtitle: const Text("채팅방에 입장하여 대화를 나누세요", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFE2FF00)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}