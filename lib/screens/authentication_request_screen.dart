import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../services/authentication_service.dart';
import '../services/payment_service.dart';
import 'dart:typed_data';

class AuthenticationRequestScreen extends StatefulWidget {
  final String clothesId;
  final int itemPrice;

  const AuthenticationRequestScreen({
    super.key,
    required this.clothesId,
    required this.itemPrice,
  });

  @override
  State<AuthenticationRequestScreen> createState() => _AuthenticationRequestScreenState();
}

class _AuthenticationRequestScreenState extends State<AuthenticationRequestScreen> {
  final AuthenticationService _authService = AuthenticationService();
  final PaymentService _paymentService = PaymentService();

  final List<XFile> _proofImages = [];
  bool _isLoading = false;
  bool _agreedToTerms = false;

  // 인증 수수료
  static const int AUTH_FEE = 15000; // 1만 5천원

  Future<void> _pickProofImages() async {
    if (_proofImages.length >= 5) {
      _showSnackBar("증빙 자료는 최대 5장까지 업로드 가능합니다.");
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          if (_proofImages.length < 5) {
            _proofImages.add(file);
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _proofImages.removeAt(index);
    });
  }

  Future<void> _submitAuthRequest() async {
    if (_proofImages.isEmpty) {
      _showSnackBar("증빙 자료를 최소 1장 이상 업로드해주세요.");
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar("이용 약관에 동의해주세요.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 인증 수수료 결제
      final paymentId = await _paymentService.createPayment(
        paymentType: 'authentication_fee',
        amount: AUTH_FEE,
        fee: 0,
        totalAmount: AUTH_FEE,
        clothesId: widget.clothesId,
      );

      if (paymentId == null) {
        throw Exception("결제 생성 실패");
      }

      final paymentSuccess = await _paymentService.processPayment(
        paymentId: paymentId,
        paymentMethod: 'card',
      );

      if (!paymentSuccess) {
        throw Exception("결제 처리 실패");
      }

      // 2. 인증 신청
      final authId = await _authService.requestAuthentication(
        clothesId: widget.clothesId,
        proofImages: _proofImages,
      );

      if (authId == null) {
        throw Exception("인증 신청 실패");
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("인증 신청 중 오류가 발생했습니다: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "인증 신청 완료",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "전문가 검수 후 1~2 영업일 내\n결과를 알려드립니다",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildInfoRow("인증 수수료", "${_formatPrice(AUTH_FEE)}원"),
                    SizedBox(height: 8.h),
                    _buildInfoRow("상품 가격", "${_formatPrice(widget.itemPrice)}원"),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "확인",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "정품 인증 신청",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.black),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 문구
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.black, size: 20),
                      SizedBox(width: 8.w),
                      Text(
                        "인증 절차 안내",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "• 전문가가 증빙 자료를 검수합니다\n• 1~2 영업일 내 결과를 알려드립니다\n• 인증 통과 시 정품 배지가 부여됩니다\n• 인증 수수료: ${_formatPrice(AUTH_FEE)}원",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12.sp,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // 증빙 자료 업로드
            Text(
              "증빙 자료 업로드",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "영수증, 택, 정품 증명서 등을 촬영하여 업로드해주세요",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 16.h),

            // 이미지 업로드 영역
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _proofImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: _pickProofImages,
                      child: Container(
                        width: 100.h,
                        margin: EdgeInsets.only(right: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: Colors.grey[400]),
                            SizedBox(height: 4.h),
                            Text(
                              "${_proofImages.length}/5",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final imageIndex = index - 1;
                  return FutureBuilder<Uint8List>(
                    future: _proofImages[imageIndex].readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          width: 100.h,
                          margin: EdgeInsets.only(right: 12.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        );
                      }

                      return Container(
                        width: 100.h,
                        margin: EdgeInsets.only(right: 12.w),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: 100.h,
                                height: 100.h,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(imageIndex),
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.black.withOpacity(0.5),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 32.h),

            // 이용 약관 동의
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    activeColor: Colors.black,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.black12),
                    onChanged: (val) => setState(() => _agreedToTerms = val!),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: const Text(
                      "인증 수수료는 환불되지 않으며, 제출된 자료는 검수 목적으로만 사용됩니다. 허위 자료 제출 시 법적 책임이 발생할 수 있습니다.",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // 결제 정보
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildInfoRow("인증 수수료", "${_formatPrice(AUTH_FEE)}원"),
                  SizedBox(height: 8.h),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "최종 결제금액",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "${_formatPrice(AUTH_FEE)}원",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 34.h),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitAuthRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 60.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: Text(
            "결제 및 인증 신청",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// Uint8List import 추가 필요
