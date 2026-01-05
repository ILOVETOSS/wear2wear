import 'package:flutter/material.dart';
import '../main.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String swapId; // 매치된 스왑 ID
  const ChatScreen({super.key, required this.swapId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  Map<String, dynamic>? swapData;
  Map<String, dynamic>? senderItem;
  Map<String, dynamic>? receiverItem;

  @override
  void initState() {
    super.initState();
    _loadSwapInfo();
  }

  // 기존 Mock 기반에서 실제 DB 정보 로드로 변경
  Future<void> _loadSwapInfo() async {
    final data = await supabase.from('swaps').select().eq('id', widget.swapId).single();
    final sItem = await supabase.from('clothes').select().eq('id', data['sender_clothes_id']).single();
    final rItem = await supabase.from('clothes').select().eq('id', data['receiver_clothes_id']).single();

    setState(() {
      swapData = data;
      senderItem = sItem;
      receiverItem = rItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SWAP CHAT", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 🔥 기존 디자인 유지: 상단 스왑 정보 배너
          if (swapData != null) _buildRequestBanner(),

          // 🔥 실시간 채팅 메시지 영역
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChatMessages(widget.swapId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!;
                if (msgs.isEmpty) return const Center(child: Text("첫 메시지를 보내보세요!", style: TextStyle(color: Colors.white24)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final isMe = msgs[index]['sender_id'] == supabase.auth.currentUser?.id;
                    return _buildChatBubble(msgs[index]['content'], isMe);
                  },
                );
              },
            ),
          ),

          _buildInputField(),
        ],
      ),
    );
  }

  // --- 기존 디자인 코드들 유지 및 연동 ---

  Widget _buildRequestBanner() {
    bool isConfirmed = swapData?['status'] == 'accepted';
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConfirmed ? Colors.green.withOpacity(0.1) : const Color(0xFFE2FF00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isConfirmed ? Colors.green : const Color(0xFFE2FF00), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniItem(senderItem, "상대 옷"),
          const Icon(Icons.swap_horiz, color: Colors.white, size: 30),
          _miniItem(receiverItem, "나의 옷"),
        ],
      ),
    );
  }

  Widget _miniItem(Map<String, dynamic>? item, String label) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: item != null ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover) : null,
            color: Colors.white10,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildChatBubble(String content, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE2FF00) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(color: isMe ? Colors.black : Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "메시지 보내기...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFFE2FF00)),
              onPressed: () {
                if (_msgController.text.trim().isEmpty) return;
                _chatService.sendMessage(widget.swapId, _msgController.text.trim());
                _msgController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}