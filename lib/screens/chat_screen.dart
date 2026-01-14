import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // ✅ 공통 포인트 컬러
  final Color _pointColor = const Color(0xFFB3EB00);

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
      backgroundColor: Colors.white, // ✅ 화이트 배경
      appBar: AppBar(
        title: const Text("CHAT",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black12, height: 1.0), // 상단 구분선
        ),
      ),
      body: Column(
        children: [
          if (swapData != null) _buildRequestBanner(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChatMessages(widget.swapId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _pointColor));
                final msgs = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

  // ✅ 스왑 정보 배너 테마 수정
  Widget _buildRequestBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // 연회색 배경
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniItem(senderItem, "상대"),
          Icon(Icons.swap_horiz, color: Colors.black, size: 28.sp),
          _miniItem(receiverItem, "나"),
        ],
      ),
    );
  }

  Widget _miniItem(Map<String, dynamic>? item, String label) {
    return Column(
      children: [
        Container(
            width: 55.w,
            height: 55.w,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
                image: item != null ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover) : null,
                color: Colors.white
            )
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ✅ 채팅 버블 테마 수정
  Widget _buildChatBubble(String content, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.black : const Color(0xFFF5F5F5), // 내 메시지는 블랙, 상대는 연회색
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 18),
          ),
        ),
        child: Text(
            content,
            style: TextStyle(
                color: isMe ? _pointColor : Colors.black, // 내 메시지 글자는 라임색
                fontWeight: FontWeight.w600,
                fontSize: 14.sp
            )
        ),
      ),
    );
  }

  // ✅ 입력창 테마 수정 (로그인/업로드 화면과 통일)
  Widget _buildInputField() {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12))
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black, // 블랙 입력창
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
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
                child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.send_rounded, color: _pointColor, size: 20) // 라임색 아이콘
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}