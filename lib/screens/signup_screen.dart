import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: Column(
          children: [
            const Text(
                "SIGN UP",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                )
            ),
            const SizedBox(height: 40),

            _buildInput(_emailController, "Email"),
            _buildInput(_pwController, "Password", obscure: true),
            _buildInput(_nameController, "Name"),
            _buildInput(_nicknameController, "Nickname"),

            const SizedBox(height: 30),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text("성별", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Row(
                  children: [
                    Expanded(child: _genderTabButton("남성")),
                    const SizedBox(width: 12),
                    Expanded(child: _genderTabButton("여성")),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 50),

            ElevatedButton(
              onPressed: () async {
                String result = await _auth.signUpWithEmail(
                  email: _emailController.text,
                  password: _pwController.text,
                  nickname: _nicknameController.text,
                  name: _nameController.text,
                  gender: _gender,
                );

                if (result == "success") {
                  if (mounted) _showSuccessDialog();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("가입 실패: 정보를 확인해주세요."))
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("가입 완료", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("가입 성공", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("가입이 완료되었습니다!\n확인을 누르면 로그인 화면으로 이동합니다.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("확인", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderTabButton(String value) {
    bool isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
