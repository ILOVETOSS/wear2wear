import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? swapData;
  Map<String, dynamic>? senderItem;
  Map<String, dynamic>? receiverItem;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSwapInfo();
    _markMessagesAsRead();
  }

  // 기능 유지: 읽음 처리 로직
  Future<void> _markMessagesAsRead() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('swap_id', widget.swapId)
          .neq('sender_id', myId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint("읽음 처리 에러: $e");
    }
  }

  Future<void> _loadSwapInfo() async {
    try {
      final data = await supabase.from('swaps').select().eq('id', widget.swapId).single();
      final sItem = await supabase.from('clothes').select().eq('id', data['sender_clothes_id']).single();
      final rItem = await supabase.from('clothes').select().eq('id', data['receiver_clothes_id']).single();

      if (mounted) {
        setState(() {
          swapData = data;
          senderItem = sItem;
          receiverItem = rItem;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CHAT",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black12, height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
        children: [
          if (swapData != null) _buildRequestBanner(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getChatMessages(widget.swapId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));

                final msgs = snapshot.data!;

                // 기능 유지: 새 메시지 시 자동 스크롤
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index];
                    final isMe = msg['sender_id'] == supabase.auth.currentUser?.id;

                    // 기능 유지: 날짜 구분선
                    bool showDateDivider = false;
                    DateTime currentDate = DateTime.parse(msg['created_at']).toLocal();
                    if (index == 0) {
                      showDateDivider = true;
                    } else {
                      DateTime prevDate = DateTime.parse(msgs[index - 1]['created_at']).toLocal();
                      if (prevDate.day != currentDate.day) showDateDivider = true;
                    }

                    return Column(
                      children: [
                        if (showDateDivider) _buildDateDivider(currentDate),
                        _buildChatBubble(msg, isMe),
                      ],
                    );
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

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
      child: Text(DateFormat('yyyy년 MM월 dd일').format(date),
          style: TextStyle(fontSize: 11.sp, color: Colors.black45, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe) {
    final timeStr = DateFormat('a h:mm').format(DateTime.parse(msg['created_at']).toLocal());
    final bool isRead = msg['is_read'] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (!isRead) Text("1", style: TextStyle(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              Text(timeStr, style: TextStyle(color: Colors.black26, fontSize: 10.sp)),
            ]),
            const SizedBox(width: 6),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(msg['content'],
                style: TextStyle(color: isMe ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 14.sp, height: 1.4)),
          ),
          if (!isMe) ...[
            const SizedBox(width: 6),
            Text(timeStr, style: TextStyle(color: Colors.black26, fontSize: 10.sp)),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniItem(senderItem, "상대"),
          Icon(Icons.swap_horiz_rounded, color: Colors.black, size: 24.sp),
          _miniItem(receiverItem, "나"),
        ],
      ),
    );
  }

  Widget _miniItem(Map<String, dynamic>? item, String label) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: item != null
            ? CachedNetworkImage(imageUrl: item['image_url'], width: 50.w, height: 50.w, fit: BoxFit.cover)
            : Container(width: 50.w, height: 50.w, color: Colors.white, child: const Icon(Icons.image_not_supported)),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
    ]);
  }

  // ✅ [수정 완료] 텍스트 배경 검은색 제거 + 가로 구분선 추가
  Widget _buildInputField() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0), // 가로 구분선
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  cursorColor: Colors.black,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: "메시지를 입력하세요.",
                    hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
                    filled: false, // 배경색 채우기 해제
                    border: InputBorder.none, // 테두리 제거
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.sentiment_satisfied_alt_rounded, color: Color(0xFF757575), size: 26),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  if (_msgController.text.trim().isEmpty) return;
                  final text = _msgController.text.trim();
                  _msgController.clear();
                  await _chatService.sendMessage(widget.swapId, text);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFC4C4C4), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}