import 'package:flutter/material.dart';
import '../services/swap_service.dart';
// 만약 SwapRequest 모델을 더 이상 사용하지 않고 Map을 쓰기로 했다면
// 아래 import와 매개변수 타입을 수정해야 할 수 있습니다.
import '../models/swap_request.dart';

class MatchModel extends ChangeNotifier {
  final SwapService _swapService = SwapService();

  // 요청 승인 처리
  Future<void> handleAccept(SwapRequest request) async {
    try {
      // 🔥 에러 해결: 인자를 requestId 하나만 전달합니다.
      // 'accepted'라는 글자는 SwapService 내부에서 처리하도록 이미 수정되었습니다.
      await _swapService.acceptRequest(request.id!);
      notifyListeners();
    } catch (e) {
      debugPrint("승인 처리 중 에러: $e");
    }
  }

  // 요청 거절 처리
  Future<void> handleReject(SwapRequest request) async {
    try {
      await _swapService.rejectRequest(request.id!);
      notifyListeners();
    } catch (e) {
      debugPrint("거절 처리 중 에러: $e");
    }
  }
}