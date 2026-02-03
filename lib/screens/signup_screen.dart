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
  bool _showPassword = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // ===== 유효성 검사 =====
    if (_emailController.text.isEmpty ||
        _pwController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _nicknameController.text.isEmpty) {
      _showSnackBar("모든 필드를 입력해주세요");
      return;
    }

    if (!_agreeToTerms) {
      _showSnackBar("약관에 동의해야 가입할 수 있습니다");
      return;
    }

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
        _showSnackBar("가입 실패: 정보를 확인해주세요. ($result)");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildKreamInput(
      TextEditingController controller,
      String label,
      String hintText, {
        bool obscure = false,
        TextInputType keyboardType = TextInputType.text,
        Widget? suffixIcon,
      }) {
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
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          showCursor: true,
          cursorColor: Colors.black,
          cursorWidth: 2.0,
          cursorHeight: 20.h,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15.sp,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: const Color(0xFFCCCCCC),
              fontSize: 15.sp,
            ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
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
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _genderTabButton(String value) {
    bool isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
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
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text(
          "가입 성공",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            const Text(
              "가입이 완료되었습니다!",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            const Text(
              "확인을 누르면 로그인 화면으로 이동합니다.",
              style: TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 회원가입 화면 닫기
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                "확인",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
              // ===== 제목 =====
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

              // ===== 이메일 입력 =====
              _buildKreamInput(
                _emailController,
                "이메일 주소 *",
                "예) swapfit@example.com",
                keyboardType: TextInputType.emailAddress,
              ),

              // ===== 비밀번호 입력 =====
              _buildKreamInput(
                _pwController,
                "비밀번호 *",
                "영문, 숫자, 특수문자 조합 8자 이상",
                obscure: !_showPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                ),
              ),

              // ===== 이름 입력 =====
              _buildKreamInput(
                _nameController,
                "이름 *",
                "본명을 입력해주세요",
              ),

              // ===== 닉네임 입력 =====
              _buildKreamInput(
                _nicknameController,
                "닉네임",
                "앱에서 사용하실 이름을 정해주세요",
              ),

              // ===== 성별 선택 =====
              Text(
                "성별",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _genderTabButton("남성"),
                  SizedBox(width: 10.w),
                  _genderTabButton("여성"),
                ],
              ),

              SizedBox(height: 30.h),

              // ===== 약관 동의 =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.black12),
                      onChanged: (val) {
                        setState(() => _agreeToTerms = val!);
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _agreeToTerms = !_agreeToTerms);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          "개인정보 처리방침 및 이용약관에 동의합니다",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12.sp,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30.h),

              // ===== 가입하기 버튼 =====
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFEBEBEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
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
                    "가입 완료",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // ===== 소셜 가입 섹션 =====
              Center(
                child: Text(
                  "또는 소셜 계정으로 가입",
                  style: TextStyle(
                    color: Colors.black26,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // ===== 소셜 가입 버튼들 =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오 가입
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "카카오 가입 준비 중입니다.",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.black,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE812),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFFFFE812).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble, color: Colors.black, size: 18.sp),
                            SizedBox(width: 6.w),
                            Text(
                              "카카오",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Apple 가입
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Apple 가입 준비 중입니다.",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.black,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: Colors.white, size: 18.sp),
                            SizedBox(width: 6.w),
                            Text(
                              "Apple",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40.h),

              // ===== 로그인 링크 =====
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "이미 계정이 있으신가요? ",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13.sp,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "로그인",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}