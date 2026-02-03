import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/account_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final AccountService _accountService = AccountService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("이메일을 입력해주세요");
      return;
    }

    setState(() => _isLoading = true);

    final success = await _accountService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        setState(() => _emailSent = true);
        _showSnackBar(
          "비밀번호 재설정 링크가 이메일로 전송되었습니다.",
          isSuccess: true,
        );
      } else {
        _showSnackBar("이메일 전송에 실패했습니다. 이메일을 확인해주세요.");
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 3),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60.h),

            // 제목
            Center(
              child: Text(
                "비밀번호 찾기",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // 설명
            Center(
              child: Text(
                _emailSent
                    ? "이메일 확인 후 비밀번호를 재설정하세요"
                    : "계정에 등록된 이메일을 입력하면\n비밀번호 재설정 링크를 보내드립니다",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 60.h),

            if (!_emailSent) ...[
              // 이메일 입력 필드
              Text(
                "이메일 주소",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                showCursor: true,
                cursorColor: Colors.black,
                cursorWidth: 2.0,
                cursorHeight: 20.h,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15.sp,
                ),
                decoration: InputDecoration(
                  hintText: "이메일을 입력하세요",
                  hintStyle: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 15.sp,
                  ),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                    onPressed: () {
                      _emailController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  filled: false,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFEBEBEB), width: 1.0),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),

              SizedBox(height: 60.h),

              // 재설정 버튼
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    "재설정 링크 받기",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // 이메일 전송 완료 상태
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 48.sp,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "이메일이 전송되었습니다",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "이메일을 확인하여 비밀번호를 재설정하세요.\n링크는 24시간 동안 유효합니다.",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // 다른 이메일로 시도 버튼
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _emailSent = false);
                    _emailController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "다른 이메일로 시도",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // 로그인 화면으로 돌아가기
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "로그인으로 돌아가기",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}