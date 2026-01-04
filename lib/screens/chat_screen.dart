import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../data/mock_data.dart';

class ChatScreen extends StatefulWidget {
  final ClothingItem item;
  const ChatScreen({super.key, required this.item});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ClothingItem? selectedMyItem; // 내가 제안한 옷 저장
  bool isConfirmed = false;     // 최종 스왑 확정 여부

  // 내 옷 선택 바텀시트
  void _showMyItemPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("제안할 내 옷 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: myItems.isEmpty
                  ? const Center(child: Text("등록된 내 옷이 없습니다.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: myItems.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    setState(() => selectedMyItem = myItems[index]);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: NetworkImage(myItems[index].imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.item.ownerName}님과 대화")),
      body: Column(
        children: [
          // 🔥 상단 스왑 요청 상태 카드
          _buildRequestBanner(),

          const Expanded(child: Center(child: Text("채팅 메시지가 없습니다.", style: TextStyle(color: Colors.white24)))),

          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildRequestBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConfirmed ? Colors.green.withOpacity(0.1) : const Color(0xFFFF4D4D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isConfirmed ? Colors.green : const Color(0xFFFF4D4D), width: 1),
      ),
      child: Column(
        children: [
          Text(
            isConfirmed ? "🎉 스왑 성사 완료!" : "🔥 스왑 제안 정보",
            style: TextStyle(fontWeight: FontWeight.bold, color: isConfirmed ? Colors.green : const Color(0xFFFF4D4D)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 내 옷 (선택 전/후)
              Column(
                children: [
                  GestureDetector(
                    onTap: isConfirmed ? null : _showMyItemPicker,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                        image: selectedMyItem != null
                            ? DecorationImage(image: NetworkImage(selectedMyItem!.imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: selectedMyItem == null ? const Icon(Icons.add, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text("나의 옷", style: TextStyle(fontSize: 12)),
                ],
              ),
              const Icon(Icons.swap_horiz, color: Colors.white, size: 30),
              // 상대방 옷
              Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: NetworkImage(widget.item.imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text("${widget.item.brand}", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (selectedMyItem == null)
            const Text("교환할 내 옷을 선택해주세요", style: TextStyle(fontSize: 13, color: Colors.white70))
          else if (!isConfirmed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4D)),
                onPressed: () => setState(() => isConfirmed = true),
                child: const Text("스왑 확정하기"),
              ),
            )
          else
            const Text("성공적으로 교환되었습니다!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: TextField(decoration: const InputDecoration(hintText: "메시지 보내기"))),
            IconButton(icon: const Icon(Icons.send, color: Color(0xFFFF4D4D)), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}