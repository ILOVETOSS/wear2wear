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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("가입 성공", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
        content: const Text("가입이 완료되었습니다!\n확인을 누르면 로그인 화면으로 이동합니다."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("확인", style: TextStyle(color: Color(0xFFE2FF00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Text("SIGN UP", style: TextStyle(color: Color(0xFFE2FF00), fontSize: 35, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildInput(_emailController, "Email"),
            _buildInput(_pwController, "Password", obscure: true),
            _buildInput(_nameController, "Name"),
            _buildInput(_nicknameController, "Nickname"),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _genderRadio("남성"),
                const SizedBox(width: 30),
                _genderRadio("여성"),
              ],
            ),
            const SizedBox(height: 40),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("가입 실패: 정보를 확인해주세요.")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2FF00), minimumSize: const Size(double.infinity, 50)),
              child: const Text("가입 완료", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
        ),
      ),
    );
  }

  Widget _genderRadio(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          activeColor: const Color(0xFFE2FF00),
          onChanged: (val) => setState(() => _gender = val!),
        ),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}