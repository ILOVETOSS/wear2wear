import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("이메일과 비밀번호를 입력해주세요");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.session != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("로그인 정보가 일치하지 않습니다.");
        debugPrint("❌ 로그인 에러: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      ),
    );
  }

  // ✅ 배경색 차이를 없앤 언더라인 스타일 + 커서 깜빡임 추가
  Widget _buildWhiteTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
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
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        filled: false,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEBEBEB), width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFEBEBEB), width: 1),
        ),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  // 🔥 소셜 로그인 버튼 빌더
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: backgroundColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 80.h),

                // 로고
                Center(
                  child: Text(
                    "SWAP-FIT",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                SizedBox(height: 60.h),

                // 이메일 주소 라벨
                Text(
                  "이메일 주소",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),

                // 이메일 입력창
                _buildWhiteTextField(
                  controller: _emailController,
                  hintText: "이메일을 입력하세요",
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  suffixIcon: _emailController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                    onPressed: () {
                      _emailController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                ),

                SizedBox(height: 24.h),

                // 비밀번호 라벨
                Text(
                  "비밀번호",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),

                // 비밀번호 입력창
                _buildWhiteTextField(
                  controller: _passwordController,
                  hintText: "비밀번호를 입력하세요",
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),

                SizedBox(height: 40.h),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                      "로그인",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // 🔥 비밀번호 찾기 & 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PasswordResetScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "비밀번호 찾기",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12.h,
                      color: const Color(0xFFEBEBEB),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "회원가입",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),

                // 🔥 소셜 로그인 섹션
                Center(
                  child: Text(
                    "다른 방법으로 로그인",
                    style: TextStyle(
                      color: Colors.black26,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // 🔥 소셜 로그인 버튼들
                Row(
                  children: [
                    // 카카오 로그인
                    _buildSocialButton(
                      icon: Icons.chat_bubble_outline,
                      label: "카카오",
                      backgroundColor: const Color(0xFFFFE812),
                      textColor: Colors.black,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "카카오 로그인 준비 중입니다.",
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
                    ),

                    SizedBox(width: 12.w),

                    // 애플 로그인
                    _buildSocialButton(
                      icon: Icons.apple,
                      label: "Apple",
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Apple 로그인 준비 중입니다.",
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
                    ),
                  ],
                ),

                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}