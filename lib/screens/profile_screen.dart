import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/wishlist_service.dart';
import 'upload_screen.dart';
import 'item_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUid;
  final Map<String, dynamic>? editItem;

  const ProfileScreen({
    super.key,
    this.targetUid,
    this.editItem,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImageCropper _imageCropper = ImageCropper();
  final WishlistService _wishlistService = WishlistService();

  bool _isUploading = false;
  late String _displayUid;
  bool _isMe = false;

  int _activeMenuIndex = 0;

  @override
  void initState() {
    super.initState();
    final currentUser = supabase.auth.currentUser;
    _displayUid = widget.targetUid ?? currentUser?.id ?? '';
    _isMe = _displayUid == currentUser?.id;
  }

  Future<void> _updateProfileImage() async {
    if (!_isMe) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    final croppedFile = await _imageCropper.cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '프로필 사진 편집',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.black,
        ),
        IOSUiSettings(title: '프로필 사진 편집'),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 520, height: 520),
        ),
      ],
    );

    if (croppedFile == null) return;
    if (mounted) setState(() => _isUploading = true);

    try {
      final imageBytes = await croppedFile.readAsBytes();
      final fileExt = croppedFile.path.split('.').last;
      final fileName = '$_displayUid.$fileExt';

      await supabase.storage.from('avatars').uploadBinary(
          fileName, imageBytes, fileOptions: FileOptions(upsert: true));

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      final String finalImageUrl = "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}";

      await supabase.from('profiles').upsert({
        'id': _displayUid,
        'avatar_url': finalImageUrl,
        'updated_at': DateTime.now().toIso8601String()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("프로필 사진이 업데이트되었습니다.")),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showItemDetailSheet(Map<String, dynamic> item) {
    final List<String> allImages = [];
    if (item['image_url'] != null) allImages.add(item['image_url'].toString());
    if (item['image_urls'] != null && item['image_urls'] is List) {
      allImages.addAll(List<String>.from(item['image_urls'].map((e) => e.toString())));
    }

    int activeIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 400.h,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: allImages.length,
                          onPageChanged: (index) => setModalState(() => activeIndex = index),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                              child: Image.network(allImages[index], width: double.infinity, fit: BoxFit.cover),
                            );
                          },
                        ),
                        Positioned(
                          top: 20, right: 20,
                          child: IconButton(
                            icon: const CircleAvatar(
                                backgroundColor: Colors.black,
                                child: Icon(Icons.close, color: Colors.white, size: 20)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 20, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(allImages.length, (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: activeIndex == index ? 10 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: activeIndex == index ? Colors.black : Colors.black12,
                                ),
                              )),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['brand']?.toUpperCase() ?? 'BRAND',
                              style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 14.sp, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(item['title'] ?? 'ITEM NAME',
                              style: TextStyle(color: Colors.black, fontSize: 24.sp, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 25),
                          const Divider(color: Colors.black12),
                          _buildDetailRow("상태", item['condition'] ?? "좋음"),
                          _buildDetailRow("사이즈", item['size'] ?? "FREE"),
                          _buildDetailRow("카테고리", item['category'] ?? "기타"),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: _isMe ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => UploadScreen(editItem: item)));
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("수정하기", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(item);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("삭제하기", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ) : ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("교환 신청하기", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("삭제할까요?", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text("취소", style: TextStyle(color: Colors.black38))),
          TextButton(
            onPressed: () async {
              await supabase.from('clothes').delete().eq('id', item['id']);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
        title: Text(_isMe ? "MY PAGE" : "CLOSET", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isMe) IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.black45),
              onPressed: () async => await supabase.auth.signOut()),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            if (_isMe) ...[
              _buildSubscriptionCard(),
              const Divider(height: 8, color: Color(0xFFF8F8F8)),
              _buildIconMenuGrid(),
              const Divider(height: 8, color: Color(0xFFF8F8F8)),
              _buildTradeStats(),
              const Divider(height: 8, color: Color(0xFFF8F8F8)),
              _buildSettlementInfo(),
              const Divider(height: 8, color: Color(0xFFF8F8F8)),
            ],
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: _updateProfileImage,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('profiles').stream(primaryKey: ['id']).eq('id', _displayUid),
              builder: (context, profileSnap) {
                final avatarUrl = profileSnap.data?.isNotEmpty == true ? profileSnap.data!.first['avatar_url'] : null;
                return Stack(
                  children: [
                    CircleAvatar(
                      radius: 38.w,
                      backgroundColor: const Color(0xFFF5F5F5),
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          : (avatarUrl == null ? Icon(Icons.person, color: Colors.black12, size: 40.w) : null),
                    ),
                    if (_isMe)
                      Positioned(bottom: 0, right: 0,
                          child: CircleAvatar(radius: 12.w, backgroundColor: Colors.black,
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 12.w))),
                  ],
                );
              },
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isMe ? (supabase.auth.currentUser?.email?.split('@')[0] ?? "User") : "상대방의 옷장",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.black)),
                const SizedBox(height: 6),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
                  builder: (context, snap) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                    child: Text("TOTAL ${snap.data?.length ?? 0} ITEMS",
                        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 구독 상태 카드
  Widget _buildSubscriptionCard() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SWAP BOX 구독중",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "월 29,900원",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "해지하기",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "다음 배송: 2026.02.15",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 44.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              "이번 달 큐레이션 보기",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconMenuGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuItem(0, Icons.checkroom_outlined, "내 옷장"),
          _buildMenuItem(1, Icons.swap_horiz_rounded, "스왑내역"),
          _buildMenuItem(2, Icons.bookmark_border_rounded, "위시리스트"),
          _buildMenuItem(3, Icons.favorite_border_rounded, "하트목록"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    bool isActive = _activeMenuIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeMenuIndex = index),
      child: Column(
        children: [
          Icon(icon, size: 28.w, color: isActive ? Colors.black : Colors.black26),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
              color: isActive ? Colors.black : Colors.black38)),
        ],
      ),
    );
  }

  // 🔥 거래 현황 카드
  Widget _buildTradeStats() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "이번 달 거래 현황",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem("3", "즉시구매"),
              ),
              Expanded(
                child: _buildStatItem("5", "교환완료"),
              ),
              Expanded(
                child: _buildStatItem("2", "위탁판매"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  // 🔥 정산 정보 카드
  Widget _buildSettlementInfo() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "이번 달 정산 예정",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "840,000원",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              "정산내역",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeMenuIndex) {
      case 0: return _buildMyClothesTab();
      case 1: return _buildSwapHistoryTab();
      case 2: return _buildWishlistTab();
      case 3: return _buildLikedItemsTab();
      default: return _buildMyClothesTab();
    }
  }

  Widget _buildMyClothesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('clothes').stream(primaryKey: ['id']).eq('user_id', _displayUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyState("등록된 옷이 없습니다.");
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 15.h, crossAxisSpacing: 15.w, childAspectRatio: 0.78),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildClosetItem(items[index]),
        );
      },
    );
  }

  Widget _buildSwapHistoryTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('swaps').select()
          .or('from_user_id.eq.$_displayUid,to_user_id.eq.$_displayUid')
          .eq('status', 'accepted')
          .order('updated_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        final swaps = snapshot.data ?? [];
        if (swaps.isEmpty) return _buildEmptyState("완료된 스왑이 없습니다.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          itemCount: swaps.length,
          itemBuilder: (context, index) => _buildSwapHistoryCard(swaps[index]),
        );
      },
    );
  }

  Widget _buildWishlistTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _wishlistService.getWishlistWithDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyState("위시리스트가 비어있습니다.");

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 15.h, crossAxisSpacing: 15.w, childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildWishlistItem(items[index]),
        );
      },
    );
  }

  Widget _buildLikedItemsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _wishlistService.getLikedItemsWithDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return _buildEmptyState("좋아요한 아이템이 없습니다.");

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 15.h, crossAxisSpacing: 15.w, childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildLikedItem(items[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 60.sp, color: Colors.black12),
            SizedBox(height: 16.h),
            Text(message, style: TextStyle(color: Colors.black26, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapHistoryCard(Map<String, dynamic> swap) {
    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait([
        supabase.from('clothes').select().eq('id', swap['my_item_id']).maybeSingle(),
        supabase.from('clothes').select().eq('id', swap['target_item_id']).maybeSingle(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final myItem = snapshot.data![0];
        final targetItem = snapshot.data![1];

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("스왑 완료", style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r)),
                    child: Text("완료", style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSwapItemPreviewProfile(myItem, "내 아이템"),
                  Icon(Icons.swap_horiz_rounded, color: Colors.black, size: 28.sp),
                  _buildSwapItemPreviewProfile(targetItem, "교환 아이템"),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                "완료일: ${swap['updated_at']?.toString().split('T')[0] ?? swap['created_at']?.toString().split('T')[0] ?? ''}",
                style: TextStyle(color: Colors.black45, fontSize: 13.sp),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwapItemPreviewProfile(Map<String, dynamic>? item, String label) {
    return Column(
      children: [
        Container(
          width: 80.w, height: 80.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFFF2F2F2),
            image: item != null && item['image_url'] != null
                ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                : null,
          ),
          child: item == null ? const Icon(Icons.image_not_supported, color: Colors.black12) : null,
        ),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
        if (item != null)
          Text(item['brand'] ?? '', style: TextStyle(fontSize: 10.sp, color: Colors.black, fontWeight: FontWeight.bold), maxLines: 1),
      ],
    );
  }

  Widget _buildClosetItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showItemDetailSheet(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12.r)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(item['image_url'] ?? '', fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                    errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.black12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['brand']?.toUpperCase() ?? 'BRAND',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(item['title'] ?? 'ITEM NAME',
                    style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item))),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12.r)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(item['image_url'] ?? '', fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                        errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.black12)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['brand']?.toUpperCase() ?? 'BRAND',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text(item['title'] ?? 'ITEM',
                        style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () async {
                final success = await _wishlistService.removeFromWishlist(item['id'].toString());
                if (success && mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('위시리스트에서 제거되었습니다', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.black,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 20, right: 20),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withOpacity(0.7),
                child: const Icon(Icons.bookmark, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikedItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item))),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12.r)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(item['image_url'] ?? '', fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                        errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.black12)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['brand']?.toUpperCase() ?? 'BRAND',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text(item['title'] ?? 'ITEM',
                        style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () async {
                final success = await _wishlistService.removeLike(item['id'].toString());
                if (success && mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('좋아요가 취소되었습니다', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.black,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 150, left: 20, right: 20),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withOpacity(0.7),
                child: const Icon(Icons.favorite, color: Colors.red, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}