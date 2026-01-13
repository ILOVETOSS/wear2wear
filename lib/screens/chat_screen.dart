import 'package:flutter/material.dart';
import '../main.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String swapId;
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

  Future<void> _loadSwapInfo() async {
    final data = await supabase.from('swaps').select().eq('id', widget.swapId).single();
    final sItem = await supabase.from('clothes').select().eq('id', data['sender_clothes_id']).single();
    final rItem = await supabase.from('clothes').select().eq('id', data['receiver_clothes_id']).single();
    setState(() { swapData = data; senderItem = sItem; receiverItem = rItem; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CHAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (swapData != null) _buildRequestBanner(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChatMessages(widget.swapId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                final msgs = snapshot.data!;
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

  Widget _buildRequestBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniItem(senderItem, "상대"),
          const Icon(Icons.swap_horiz, color: Color(0xFFE2FF00), size: 28),
          _miniItem(receiverItem, "나"),
        ],
      ),
    );
  }

  Widget _miniItem(Map<String, dynamic>? item, String label) {
    return Column(
      children: [
        Container(width: 55, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10), image: item != null ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover) : null, color: Colors.black)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ],
    );
  }

  Widget _buildChatBubble(String content, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(content, style: TextStyle(color: isMe ? Colors.black : Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "메시지를 입력하세요...", hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true, fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                if (_msgController.text.trim().isEmpty) return;
                _chatService.sendMessage(widget.swapId, _msgController.text.trim());
                _msgController.clear();
              },
              child: const CircleAvatar(backgroundColor: Color(0xFFE2FF00), child: Icon(Icons.send, color: Colors.black, size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}