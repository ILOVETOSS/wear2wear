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
    _cleanupExpiredSwaps(); // ✅ 앱 시작 시 만료된 항목 자동 삭제
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ 만료된 스왑 자동 삭제 (48시간 경과)
  Future<void> _cleanupExpiredSwaps() async {
    try {
      final now = DateTime.now();
      final expiredTime = now.subtract(const Duration(hours: 48));

      // 48시간이 지난 항목 삭제 (결제 완료/최종 완료된 거래는 제외하고 삭제하고 싶다면 status 조건을 조절하세요)
      await supabase
          .from('swaps')
          .delete()
          .not('status', 'in', '("payment_completed","completed")') // 결제 전 단계들만 삭제
          .lt('created_at', expiredTime.toIso8601String());

      debugPrint("✅ 만료된 스왑 정리 완료");
    } catch (e) {
      debugPrint("❌ 만료된 스왑 정리 실패: $e");
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

        // ✅ 만료되지 않은 pending 상태만 필터링
        final requests = all.where((c) {
          if ((c['from_user_id'] != myId && c['to_user_id'] != myId) || c['status'] != 'pending') {
            return false;
          }
          final createdAt = DateTime.parse(c['created_at']);
          return now.difference(createdAt).inHours < 48;
        }).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 60.sp, color: Colors.black12),
                SizedBox(height: 16.h),
                Text(
                  "대기 중인 요청이 없습니다.",
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(
          color: isReceived ? Colors.black : Colors.black12,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isReceived ? Colors.black : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  isReceived ? "받은 제안" : "보낸 제안",
                  style: TextStyle(
                    color: isReceived ? Colors.white : Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _swapService.rejectRequest(req['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      "거절",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _swapService.acceptRequest(req['id']);
                      if (mounted) {
                        final myItemData = await supabase
                            .from('clothes')
                            .select()
                            .eq('id', req['target_item_id'])
                            .single();
                        final targetItemData = await supabase
                            .from('clothes')
                            .select()
                            .eq('id', req['my_item_id'])
                            .single();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchSuccessScreen(
                              swapId: req['id'],
                              myItem: myItemData,
                              targetItem: targetItemData,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      "수락",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                "상대방의 응답을 기다리고 있습니다",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

        // ✅ 진행 중인 거래 필터링 + 만료(48시간) 체크 적용
        final inProgress = all.where((c) {
          if (c['from_user_id'] != myId && c['to_user_id'] != myId) {
            return false;
          }

          final validStatuses = [
            'accepted',
            'trade_selected',
            'shipping',
            'shipping_confirmed',
            'payment_completed',
            'completed'
          ];

          if (!validStatuses.contains(c['status'])) {
            return false;
          }

          // ✅ [수정 부분] 매칭 성공(accepted) 이후 단계여도 48시간이 지나면 자동으로 사라지게 함
          // 단, 결제가 완료되었거나 최종 완료된 거래는 사라지면 안 되므로 제외
          if (c['status'] != 'payment_completed' && c['status'] != 'completed') {
            final createdAt = DateTime.parse(c['created_at']);
            if (now.difference(createdAt).inHours >= 48) {
              _deleteExpiredSwap(c['id']); // 실제 DB 삭제 시도
              return false; // 리스트에서 즉시 제외
            }
          }

          return true;
        }).toList();

        return Column(
          children: [
            if (inProgress.isNotEmpty)
              Container(
                margin: EdgeInsets.all(20.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "🔔 진행 중인 스왑 ${inProgress.length}건",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: inProgress.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60.sp,
                      color: Colors.black12,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "진행 중인 스왑이 없습니다.",
                      style: TextStyle(
                        color: Colors.black26,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
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

  // ✅ 만료된 스왑 삭제 함수
  Future<void> _deleteExpiredSwap(String swapId) async {
    try {
      await supabase.from('swaps').delete().eq('id', swapId);
      debugPrint("✅ 만료된 스왑 삭제: $swapId");
    } catch (e) {
      debugPrint("❌ 만료된 스왑 삭제 실패: $e");
    }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusLabel(status),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _buildTimer(swap['created_at']),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_forward, color: Colors.black54, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "다음 단계: ${_getNextAction(status, tradeMethod)}",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_shouldShowActionButton(status)) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleAction(status, swap),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _getActionButtonText(status),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 헬퍼 함수들 ---
  Widget _buildTimer(String? createdAt) {
    if (createdAt == null) return const SizedBox();
    final created = DateTime.parse(createdAt);
    final remaining = const Duration(hours: 48) - DateTime.now().difference(created);

    if (remaining.isNegative) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          "⏰ 만료됨",
          style: TextStyle(
            color: Colors.red,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        "⏰ ${remaining.inHours}시간 ${remaining.inMinutes % 60}분 남음",
        style: TextStyle(
          color: Colors.orange,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _miniImg(String? id, String label) {
    if (id == null) return const SizedBox();
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase.from('clothes').select().eq('id', id).maybeSingle(),
      builder: (context, snap) {
        final url = snap.data?['image_url'];
        return Column(
          children: [
            Container(
              width: 85.w,
              height: 85.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: Colors.black12),
                image: url != null
                    ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                    : null,
              ),
              child: url == null
                  ? const Icon(Icons.image_not_supported, color: Colors.black12)
                  : null,
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return '상태: ✅ 매치 성공';
      case 'trade_selected':
        return '상태: 📦 거래 방식 확정';
      case 'shipping':
        return '상태: 📍 배송지 입력 중';
      case 'shipping_confirmed':
        return '상태: 🚚 배송지 확정';
      case 'payment_completed':
        return '상태: 💳 결제 완료';
      case 'completed':
        return '상태: ✨ 거래 완료';
      default:
        return '상태: ⏳ 대기중';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'trade_selected':
        return Colors.blue;
      case 'shipping':
        return Colors.orange;
      case 'shipping_confirmed':
        return Colors.deepOrange;
      case 'payment_completed':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getNextAction(String status, String? tradeMethod) {
    switch (status) {
      case 'accepted':
        return '거래 방식 선택';
      case 'trade_selected':
        return (tradeMethod == 'direct_trade') ? '직접 만나서 교환' : '배송지 입력';
      case 'shipping':
        return '배송지 입력 중';
      case 'shipping_confirmed':
        return '결제하기';
      case 'payment_completed':
        return '상품 도착 대기';
      case 'completed':
        return '거래 완료';
      default:
        return '상대방 수락 대기';
    }
  }

  bool _shouldShowActionButton(String status) {
    return ['accepted', 'trade_selected', 'shipping_confirmed'].contains(status);
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case 'accepted':
        return '거래 방식 선택하기 →';
      case 'trade_selected':
        return '배송지 입력하기 →';
      case 'shipping_confirmed':
        return '결제하기 →';
      default:
        return '다음 단계 →';
    }
  }

  void _handleAction(String status, Map<String, dynamic> swap) async {
    if (status == 'accepted') {
      try {
        final myItemData = await supabase
            .from('clothes')
            .select()
            .eq('id', swap['my_item_id'])
            .single();
        final targetItemData = await supabase
            .from('clothes')
            .select()
            .eq('id', swap['target_item_id'])
            .single();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TradeMethodSelectionScreen(
                swapId: swap['id'],
                myItem: myItemData,
                targetItem: targetItemData,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint("❌ 에러: $e");
      }
    } else if (status == 'trade_selected') {
      final tradeMethod = swap['trade_method'];
      if (tradeMethod == 'safe_trade' || tradeMethod == 'premium_trade') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfficeShippingScreen(swapId: swap['id']),
          ),
        );
      } else if (tradeMethod == 'direct_trade') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectMeetingScreen(swapId: swap['id']),
          ),
        );
      }
    } else if (status == 'shipping_confirmed') {
      final tradeMethod = swap['trade_method'];
      int amount = 8000;
      if (tradeMethod == 'premium_trade') {
        amount = 15000;
      } else if (tradeMethod == 'direct_trade') {
        amount = 0;
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              swapId: swap['id'],
              totalAmount: amount,
            ),
          ),
        );
      }
    }
  }
}