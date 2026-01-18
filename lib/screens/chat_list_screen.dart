import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CHATS",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black12, height: 1.0),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('swaps').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final allChats = snapshot.data ?? [];
          final acceptedChats = allChats.where((c) =>
          (c['sender_id'] == uid || c['receiver_id'] == uid) && c['status'] == 'accepted'
          ).toList();

          if (acceptedChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 60.sp, color: Colors.black12),
                  SizedBox(height: 16.h),
                  Text("진행 중인 채팅이 없습니다.",
                      style: TextStyle(color: Colors.black26, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: acceptedChats.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, color: Colors.black12),
            itemBuilder: (context, index) {
              final chat = acceptedChats[index];
              final bool isIRequested = chat['sender_id'] == uid;
              final targetClothesId = isIRequested ? chat['receiver_clothes_id'] : chat['sender_clothes_id'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: supabase.from('clothes').select().eq('id', targetClothesId).maybeSingle(),
                builder: (context, itemSnap) {
                  final itemData = itemSnap.data;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(swapId: chat['id']))
                    ),
                    leading: Container(
                      width: 55.w,
                      height: 55.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black12),
                        image: (itemData != null && itemData['image_url'] != null)
                            ? DecorationImage(
                          image: NetworkImage(itemData['image_url']),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: itemData == null
                          ? const Icon(Icons.checkroom_outlined, color: Colors.black12)
                          : null,
                    ),
                    title: Text(
                        itemData?['brand']?.toUpperCase() ?? "SWAP CHAT",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        itemData?['title'] ?? "채팅방에 입장하여 대화를 나누세요",
                        style: TextStyle(color: Colors.black45, fontSize: 12.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 16.sp),
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