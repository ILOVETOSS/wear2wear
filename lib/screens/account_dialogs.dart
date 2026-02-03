import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../services/account_service.dart';
import 'login_screen.dart';

// ============================================
// 로그아웃 다이얼로그
// ============================================
Future<bool?> showLogoutDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: const Text(
        "로그아웃",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: const Text(
        "정말 로그아웃하시겠습니까?",
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            "취소",
            style: TextStyle(color: Colors.black38),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: const Text(
            "로그아웃",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

// ============================================
// 계정 삭제 다이얼로그 (3단계)
// ============================================
void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DeleteAccountDialog(),
  );
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final AccountService _accountService = AccountService();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPasswordField = false;
  bool _agreeToDelete = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar("비밀번호를 입력해주세요");
      return;
    }

    setState(() => _isLoading = true);

    final success = await _accountService.deleteAccount(
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context); // 다이얼로그 닫기

        // 로그인 화면으로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "계정이 삭제되었습니다",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showSnackBar("계정 삭제에 실패했습니다. 비밀번호를 확인해주세요.");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: const Text(
        "계정 삭제",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: 경고 메시지
            if (!_showPasswordField)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "계정 삭제는 되돌릴 수 없습니다",
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "삭제되는 정보:",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  const Text(
                    "• 프로필 정보\n• 업로드한 상품\n• 거래 내역\n• 메시지\n• 위시리스트\n• 모든 사진",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              )
            // Step 2: 동의 체크박스
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeToDelete,
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Colors.black12),
                          onChanged: (val) {
                            setState(() => _agreeToDelete = val!);
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "계정 삭제로 인한 모든 결과를 이해하고 동의합니다",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "비밀번호 입력",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "비밀번호를 입력하세요",
                      hintStyle: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13.sp,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!_showPasswordField) {
              Navigator.pop(context);
            } else {
              setState(() {
                _showPasswordField = false;
                _agreeToDelete = false;
                _passwordController.clear();
              });
            }
          },
          child: Text(
            !_showPasswordField ? "취소" : "뒤로",
            style: const TextStyle(color: Colors.black38),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : !_showPasswordField
              ? () {
            setState(() => _showPasswordField = true);
          }
              : !_agreeToDelete
              ? null
              : _confirmDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _isLoading
              ? SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            !_showPasswordField ? "계속" : "삭제하기",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}