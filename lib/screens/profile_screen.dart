import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 유저의 UID 가져오기
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("내 프로필", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // 로그아웃 후 로직이 필요하다면 여기에 추가 (예: 로그인 화면 이동)
            },
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.white)))
          : SingleChildScrollView(
        child: Column(
          children: [
            // 1. 프로필 상단 레이아웃
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, size: 45, color: Colors.white54)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.email?.split('@')[0] ?? "스왑 마스터",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  const Text("반갑습니다! 옷장 정리 중이에요.", style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat("팔로워", "256"),
                      _buildStat("평점", "4.9"),
                      _buildStat("스왑", "42"),
                    ],
                  ),
                ],
              ),
            ),

            // 2. 탭 바 영역
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Color(0xFFFF4D4D),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: [Tab(text: "나의 옷장"), Tab(text: "리뷰"), Tab(text: "정보")],
                  ),
                  SizedBox(
                    height: 600, // 충분한 높이 확보
                    child: TabBarView(
                      children: [
                        _buildWardrobeGrid(uid), // 서버 데이터 연동
                        const Center(child: Text("받은 리뷰가 없습니다.", style: TextStyle(color: Colors.white54))),
                        const Center(child: Text("내 정보 설정", style: TextStyle(color: Colors.white54))),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  // 🔥 Firestore 실시간 데이터 그리드
  Widget _buildWardrobeGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      // 정렬(orderBy)을 사용하므로 Firebase Console에서 '색인(Index)' 생성이 필수입니다.
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('ownerUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // 인덱스 미생성 시 여기서 에러 메시지와 함께 생성 링크가 콘솔에 뜹니다.
          debugPrint("Firestore Error: ${snapshot.error}");
          return Center(child: Text("데이터를 불러오지 못했습니다.\n콘솔의 인덱스 링크를 확인하세요.",
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D4D)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text(
                "옷장이 비어있습니다.\n옷을 먼저 등록해보세요!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              )
          );
        }

        final items = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          physics: const NeverScrollableScrollPhysics(), // SingleChildScrollView 내 중복 스크롤 방지
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? "";

            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.white10,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // 404 에러 시 여기서 URL을 출력합니다.
                    debugPrint("❌ Image 404 Error: $imageUrl");
                    return const Icon(Icons.broken_image, color: Colors.white24);
                  },
                )
                    : const Icon(Icons.image_not_supported, color: Colors.white24),
              ),
            );
          },
        );
      },
    );
  }
}