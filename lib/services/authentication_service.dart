import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class AuthenticationService {
  final _supabase = supabase;

  // 정품 인증 신청
  Future<String?> requestAuthentication({
    required String clothesId,
    required List<XFile> proofImages, // 영수증, 택 등
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 이미지 업로드
      List<String> uploadedUrls = [];
      for (int i = 0; i < proofImages.length; i++) {
        final fileName = 'auth_proof/${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final bytes = await proofImages[i].readAsBytes();

        await _supabase.storage.from('clothing-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

        uploadedUrls.add(_supabase.storage.from('clothing-images').getPublicUrl(fileName));
      }

      // 인증 요청 생성
      final authData = await _supabase.from('authentications').insert({
        'clothes_id': clothesId,
        'user_id': userId,
        'proof_images': uploadedUrls,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      }).select().single();

      debugPrint("✅ 정품 인증 신청 성공: ${authData['id']}");
      return authData['id'];
    } catch (e) {
      debugPrint("❌ 정품 인증 신청 실패: $e");
      return null;
    }
  }

  // 인증 상태 조회
  Future<Map<String, dynamic>?> getAuthenticationStatus(String clothesId) async {
    try {
      final data = await _supabase
          .from('authentications')
          .select()
          .eq('clothes_id', clothesId)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint("❌ 인증 상태 조회 실패: $e");
      return null;
    }
  }

  // 내 인증 요청 목록
  Stream<List<Map<String, dynamic>>> getMyAuthRequests() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('authentications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
  }

  // 인증 필요 여부 확인 (20만원 이상)
  bool needsAuthentication(int? price) {
    if (price == null) return false;
    return price >= 200000;
  }

  // 인증 상태 한글 변환
  String getAuthStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '심사중';
      case 'approved':
        return '정품 인증';
      case 'rejected':
        return '인증 거부';
      default:
        return '미인증';
    }
  }

  // 인증 권장 다이얼로그 표시
  static void showAuthRecommendation(BuildContext context, VoidCallback onProceed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "정품 인증 권장",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "이 상품은 20만원 이상 고가 상품입니다.",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              "안전한 거래를 위해 정품 인증 서비스 이용을 권장드립니다.",
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            SizedBox(height: 16),
            Text(
              "• 영수증, 택, 정품 증명서 검수\n• 전문가의 진품 감정\n• 거래 분쟁 방지",
              style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onProceed();
            },
            child: const Text(
              "인증 없이 진행",
              style: TextStyle(color: Colors.black38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 인증 신청 화면으로 이동 (추후 구현)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("정품 인증 서비스는 준비 중입니다."),
                  backgroundColor: Colors.black,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "인증 신청하기",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}