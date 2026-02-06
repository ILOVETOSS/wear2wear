import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/swap_service.dart';
import 'match_success_screen.dart';
import 'trade_method_selection_screen.dart';
import 'office_shipping_screen.dart';
import 'direct_meeting_screen.dart';
import 'payment_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SwapService _swapService = SwapService();
  final String myId = supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cleanupExpiredSwaps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ 만료된 데이터 자동 정리 (백그라운드)
  Future<void> _cleanupExpiredSwaps() async {
    try {
      final now = DateTime.now();
      final expiredTime = now.subtract(const Duration(hours: 48));

      await supabase
          .from('swaps')
          .delete()
          .not('status', 'in', '("payment_completed","completed")')
          .lt('created_at', expiredTime.toIso8601String());
    } catch (e) {
      debugPrint("❌ 만료 정리 실패: $e");
    }
  }

  // ✅ 실시간 필터링 중 만료 항목 삭제
  Future<void> _deleteExpiredSwap(String swapId) async {
    try {
      await supabase.from('swaps').delete().eq('id', swapId);
    } catch (e) {
      debugPrint("❌ 삭제 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "ACTIVITY",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black26,
          labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
          tabs: const [
            Tab(text: "스왑 요청"),
            Tab(text: "진행 현황"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSwapRequestsTab(),
          _buildProgressTab(),
        ],
      ),
    );
  }

  // --- 탭 1: 스왑 요청 ---
  Widget _buildSwapRequestsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('swaps').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        final all = snapshot.data ?? [];
        final now = DateTime.now();

        final requests = all.where((c) {
          if ((c['from_user_id'] != myId && c['to_user_id'] != myId) || c['status'] != 'pending') {
            return false;
          }
          final createdAt = DateTime.parse(c['created_at']);
          return now.difference(createdAt).inHours < 48;
        }).toList();

        if (requests.isEmpty) return _buildEmptyState("대기 중인 요청이 없습니다.", Icons.inbox_outlined);

        return ListView.builder(
          padding: EdgeInsets.all(20.w),
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildRequestCard(context, requests[index]),
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> req) {
    final bool isReceived = req['to_user_id'] == myId;
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: isReceived ? Colors.black : Colors.black12, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTag(isReceived ? "받은 제안" : "보낸 제안", isReceived),
              _buildTimer(req['created_at']),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniImg(req['my_item_id'], isReceived ? "상대의 옷" : "나의 옷"),
              Icon(Icons.swap_horiz_rounded, color: Colors.black, size: 32.sp),
              _miniImg(req['target_item_id'], isReceived ? "나의 옷" : "상대의 옷"),
            ],
          ),
          SizedBox(height: 24.h),
          if (isReceived)
            Row(
              children: [
                Expanded(child: _buildActionButton("거절", () => _swapService.rejectRequest(req['id']), isBlack: false)),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton("수락", () async {
                    await _swapService.acceptRequest(req['id']);
                    if (mounted) {
                      final myItemData = await supabase.from('clothes').select().eq('id', req['target_item_id']).single();
                      final targetItemData = await supabase.from('clothes').select().eq('id', req['my_item_id']).single();

                      // ✅ 성공 페이지로 이동하고 버튼 클릭(Start Trading) 결과 대기
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchSuccessScreen(
                            swapId: req['id'],
                            myItem: myItemData,
                            targetItem: targetItemData,
                          ),
                        ),
                      );

                      // ✅ result가 true(Start Trading 클릭)이면 즉시 진행 현황 탭으로 이동
                      if (result == true) {
                        _tabController.animateTo(1);
                      }
                    }
                  }),
                ),
              ],
            )
          else
            _buildWaitingLabel(),
        ],
      ),
    );
  }

  // --- 탭 2: 진행 현황 ---
  Widget _buildProgressTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('swaps').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }
        final all = snapshot.data ?? [];
        final now = DateTime.now();

        final inProgress = all.where((c) {
          if (c['from_user_id'] != myId && c['to_user_id'] != myId) return false;
          final validStatuses = ['accepted', 'trade_selected', 'shipping', 'shipping_confirmed', 'payment_completed', 'completed'];
          if (!validStatuses.contains(c['status'])) return false;

          if (c['status'] != 'payment_completed' && c['status'] != 'completed') {
            final createdAt = DateTime.parse(c['created_at']);
            if (now.difference(createdAt).inHours >= 48) {
              _deleteExpiredSwap(c['id']);
              return false;
            }
          }
          return true;
        }).toList();

        return Column(
          children: [
            if (inProgress.isNotEmpty) _buildProgressHeader(inProgress.length),
            Expanded(
              child: inProgress.isEmpty
                  ? _buildEmptyState("진행 중인 스왑이 없습니다.", Icons.check_circle_outline)
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: inProgress.length,
                itemBuilder: (context, index) => _buildProgressCard(inProgress[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> swap) {
    final status = swap['status'] ?? 'accepted';
    final tradeMethod = swap['trade_method'];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_getStatusLabel(status), style: TextStyle(color: _getStatusColor(status), fontSize: 14.sp, fontWeight: FontWeight.w900)),
              _buildTimer(swap['created_at']),
            ],
          ),
          SizedBox(height: 12.h),
          _buildNextStepInfo(_getNextAction(status, tradeMethod)),
          if (_shouldShowActionButton(status)) ...[
            SizedBox(height: 16.h),
            _buildActionButton(_getActionButtonText(status), () => _handleAction(status, swap)),
          ],
        ],
      ),
    );
  }

  // --- 핵심: 사진 로직 유지 ---
  Widget _miniImg(String? id, String label) {
    if (id == null) return const SizedBox();
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase.from('clothes').select().eq('id', id).maybeSingle(),
      builder: (context, snap) {
        final url = snap.data?['image_url'];
        return Column(
          children: [
            Container(
              width: 85.w, height: 85.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: Colors.black12),
                image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
              ),
              child: url == null ? const Icon(Icons.image_not_supported, color: Colors.black12) : null,
            ),
            SizedBox(height: 10.h),
            Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.black54, fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }

  // --- 공통 컴포넌트 ---
  Widget _buildActionButton(String text, VoidCallback onPressed, {bool isBlack = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isBlack ? Colors.black : const Color(0xFFF5F5F5),
          foregroundColor: isBlack ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildNextStepInfo(String actionText) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, color: Colors.black54, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(child: Text("다음 단계: $actionText", style: TextStyle(color: Colors.black87, fontSize: 13.sp, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTag(String text, bool isBlack) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(color: isBlack ? Colors.black : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10.r)),
      child: Text(text, style: TextStyle(color: isBlack ? Colors.white : Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildTimer(String? createdAt) {
    if (createdAt == null) return const SizedBox();
    final remaining = const Duration(hours: 48) - DateTime.now().difference(DateTime.parse(createdAt));
    if (remaining.isNegative) return const SizedBox();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text("⏰ ${remaining.inHours}h ${remaining.inMinutes % 60}m 남음", style: TextStyle(color: Colors.orange, fontSize: 11.sp, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildWaitingLabel() => Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 12.h), decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12.r)), child: const Text("상대방의 응답을 기다리고 있습니다", textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w600)));

  Widget _buildProgressHeader(int count) => Container(margin: EdgeInsets.all(20.w), padding: EdgeInsets.all(20.w), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)]), borderRadius: BorderRadius.circular(16.r)), child: Row(children: [Icon(Icons.notifications_active, color: Colors.white, size: 24.sp), SizedBox(width: 12.w), Text("🔔 진행 중인 스왑 $count건", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900))]));

  Widget _buildEmptyState(String msg, IconData icon) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 60.sp, color: Colors.black12), SizedBox(height: 16.h), Text(msg, style: TextStyle(color: Colors.black26, fontSize: 14.sp, fontWeight: FontWeight.bold))]));

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted': return '✅ 매치 성공';
      case 'trade_selected': return '📦 거래 방식 확정';
      case 'shipping_confirmed': return '🚚 배송지 확정';
      case 'payment_completed': return '💳 결제 완료';
      case 'completed': return '✨ 거래 완료';
      default: return '⏳ 진행 중';
    }
  }

  Color _getStatusColor(String status) => (status == 'completed' || status == 'payment_completed') ? Colors.teal : Colors.blue;

  String _getNextAction(String status, String? method) {
    if (status == 'accepted') return '거래 방식 선택';
    if (status == 'trade_selected') return (method == 'direct_trade') ? '직접 만나서 교환' : '배송지 입력';
    if (status == 'shipping_confirmed') return '결제하기';
    return '상품 도착 대기';
  }

  bool _shouldShowActionButton(String status) => ['accepted', 'trade_selected', 'shipping_confirmed'].contains(status);

  String _getActionButtonText(String status) => (status == 'accepted') ? '거래 방식 선택하기 →' : (status == 'trade_selected' ? '배송지 입력하기 →' : '결제하기 →');

  void _handleAction(String status, Map<String, dynamic> swap) async {
    if (status == 'accepted') {
      final myItem = await supabase.from('clothes').select().eq('id', swap['my_item_id']).single();
      final targetItem = await supabase.from('clothes').select().eq('id', swap['target_item_id']).single();
      Navigator.push(context, MaterialPageRoute(builder: (_) => TradeMethodSelectionScreen(swapId: swap['id'], myItem: myItem, targetItem: targetItem)));
    } else if (status == 'trade_selected') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => swap['trade_method'] == 'direct_trade' ? DirectMeetingScreen(swapId: swap['id']) : OfficeShippingScreen(swapId: swap['id'])));
    } else if (status == 'shipping_confirmed') {
      int fee = (swap['trade_method'] == 'premium_trade') ? 15000 : 8000;
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(swapId: swap['id'], totalAmount: fee)));
    }
  }
}