import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final String myId = supabase.auth.currentUser!.id;

  // 채팅방 나가기 확인 다이얼로그 함수
  void _showLeaveDialog(String swapId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("채팅방 나가기", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("이 채팅방에서 나가시겠습니까?\n나가면 대화 내용이 모두 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기
              await _chatService.leaveChat(swapId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("채팅방에서 나갔습니다.")),
                );
              }
            },
            child: const Text("나가기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CHATS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 내 아이디가 포함된 채팅방 목록 실시간 구독
        stream: supabase.from('swaps').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

          final chats = snapshot.data!.where((chat) =>
          chat['sender_id'] == myId || chat['receiver_id'] == myId).toList();

          if (chats.isEmpty) return const Center(child: Text("참여 중인 채팅이 없습니다."));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final String swapId = chat['id'].toString();

              return ListTile(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(swapId: swapId))
                ),
                // ✅ 꾹 눌렀을 때 실행되는 기능
                onLongPress: () => _showLeaveDialog(swapId),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF5F5F5),
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(
                    "채팅방 ID: ${swapId.substring(0, 5)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                subtitle: const Text("꾹 눌러서 채팅방 나가기"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
              );
            },
          );
        },
      ),
    );
  }
}