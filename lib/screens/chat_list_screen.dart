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

  // ✅ 팝업창을 띄우는 함수 (기능 유지)
  void _showLeaveDialog(String swapId) {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 클릭하면 닫히게
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("채팅방 나가기", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("이 채팅방에서 나가시겠습니까?\n모든 대화 내용이 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 먼저 닫기
              await _chatService.leaveChat(swapId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("채팅방에서 나갔습니다.")),
                );
              }
            },
            child: const Text("나가기", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        // 기능 유지: 내 아이디 포함 채팅방 실시간 구독
        stream: supabase.from('swaps').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("에러가 발생했습니다."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

          final chats = snapshot.data!.where((chat) =>
          chat['sender_id'] == myId || chat['receiver_id'] == myId).toList();

          if (chats.isEmpty) return const Center(child: Text("참여 중인 채팅이 없습니다."));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final String swapId = chat['id'].toString();

              // ✅ 확실한 롱프레스 인식을 위해 GestureDetector로 감쌈
              return GestureDetector(
                onLongPress: () {
                  debugPrint("꾹 누름 인식됨: $swapId"); // 터미널에서 확인용
                  _showLeaveDialog(swapId);
                },
                child: Container(
                  color: Colors.transparent, // 투명 배경이 있어야 빈 공간도 터치를 인식함
                  child: ListTile(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(swapId: swapId))
                    ),
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}