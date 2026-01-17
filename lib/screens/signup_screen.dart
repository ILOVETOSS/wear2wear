import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  String _gender = "남성";
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // ✅ 로그인 화면과 동일한 언더라인 스타일 + 커서 깜빡임 추가
  Widget _buildKreamInput(TextEditingController controller, String label, String hintText, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,

          // 🛠 커서 깜빡임 설정 (검은색으로 선명하게)
          showCursor: true,
          cursorColor: Colors.black,
          cursorWidth: 2.0,
          cursorHeight: 20.h,

          style: TextStyle(color: Colors.black, fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: const Color(0xFFCCCCCC), fontSize: 15.sp),
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            filled: false, // 배경색 제거
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFEBEBEB), width: 1.0),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀 (로그인 로고와 스타일 통일)
              Center(
                child: Column(
                  children: [
                    Text(
                      "SIGN UP",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -1.0,
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),

              _buildKreamInput(_emailController, "이메일 주소 *", "예) swapfit@example.com"),
              _buildKreamInput(_pwController, "비밀번호 *", "영문, 숫자, 특수문자 조합 8자 이상", obscure: true),
              _buildKreamInput(_nameController, "이름 *", "본명을 입력해주세요"),
              _buildKreamInput(_nicknameController, "닉네임", "앱에서 사용하실 이름을 정해주세요"),

              // 성별 선택 섹션
              Text(
                "성별",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _genderTabButton("남성")),
                  SizedBox(width: 10.w),
                  Expanded(child: _genderTabButton("여성")),
                ],
              ),

              SizedBox(height: 50.h),

              // 가입 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFEBEBEB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : Text("가입 완료", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // 기존 가입 로직 유지
  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || _pwController.text.isEmpty) return;

    setState(() => _isLoading = true);
    String result = await _auth.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _pwController.text.trim(),
      nickname: _nicknameController.text.trim(),
      name: _nameController.text.trim(),
      gender: _gender,
    );
    setState(() => _isLoading = false);

    if (result == "success") {
      if (mounted) _showSuccessDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("가입 실패: 정보를 확인해주세요."))
        );
      }
    }
  }

  Widget _genderTabButton(String value) {
    bool isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFEBEBEB),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFBCBCBC),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: const Text("가입 성공", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: const Text("가입이 완료되었습니다!\n확인을 누르면 로그인 화면으로 이동합니다.", style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫기
              Navigator.pop(context); // 로그인 화면으로 이동
            },
            child: const Text("확인", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}