import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/account_service.dart';
import 'account_dialogs.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AccountService _accountService = AccountService();
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "설정",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // ===== 계정 섹션 =====
            Text(
              "계정",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: 12.h),

            // 프로필 수정
            _buildSettingButton(
              icon: Icons.person,
              title: "프로필 수정",
              subtitle: "이름, 닉네임, 프로필 사진 변경",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("프로필 수정 화면으로 이동합니다."),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),

            // 비밀번호 변경
            _buildSettingButton(
              icon: Icons.lock,
              title: "비밀번호 변경",
              subtitle: "현재 비밀번호를 변경합니다",
              onTap: () {
                _showPasswordChangeDialog();
              },
            ),

            // 이메일 변경
            _buildSettingButton(
              icon: Icons.email,
              title: "이메일 변경",
              subtitle: "계정 이메일을 변경합니다",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("이메일 변경 화면으로 이동합니다."),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),

            SizedBox(height: 32.h),

            // ===== 알림 섹션 =====
            Text(
              "알림",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: 12.h),

            // 푸시 알림
            _buildSettingToggle(
              icon: Icons.notifications,
              title: "푸시 알림",
              subtitle: "거래 및 메시지 알림",
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),

            // 알림 설정 상세
            if (_notificationsEnabled)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _buildSettingButton(
                  icon: Icons.tune,
                  title: "알림 설정 상세",
                  subtitle: "거래, 메시지, 프로모션 알림 설정",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("알림 설정 상세 화면으로 이동합니다."),
                        backgroundColor: Colors.black,
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 32.h),

            // ===== 앱 설정 섹션 =====
            Text(
              "앱 설정",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: 12.h),

            // 다크모드
            _buildSettingToggle(
              icon: Icons.dark_mode,
              title: "다크모드",
              subtitle: "앱 화면을 다크모드로 표시합니다",
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
              },
            ),

            // 언어 설정
            _buildSettingButton(
              icon: Icons.language,
              title: "언어",
              subtitle: "한국어",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("언어 설정 화면으로 이동합니다."),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),

            SizedBox(height: 32.h),

            // ===== 기타 섹션 =====
            Text(
              "기타",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: 12.h),

            // 이용약관
            _buildSettingButton(
              icon: Icons.description,
              title: "이용약관",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("이용약관 페이지로 이동합니다."),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),

            // 개인정보처리방침
            _buildSettingButton(
              icon: Icons.privacy_tip,
              title: "개인정보처리방침",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("개인정보처리방침 페이지로 이동합니다."),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),

            // 버전 정보
            _buildSettingButton(
              icon: Icons.info,
              title: "버전 정보",
              subtitle: "v1.0.0",
              onTap: () {},
            ),

            // 고객지원
            _buildSettingButton(
              icon: Icons.help,
              title: "고객지원",
              subtitle: "문의 및 피드백",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("고객지원 페이지로 이동합니다."),
                    backgroundColor: Colors.black,
                  ),
                );
              },
            ),

            SizedBox(height: 32.h),

            // ===== 위험 작업 섹션 =====
            Text(
              "계정 관리",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: 12.h),

            // 로그아웃
            _buildSettingButton(
              icon: Icons.logout,
              title: "로그아웃",
              titleColor: Colors.orange,
              onTap: () async {
                final shouldLogout = await showLogoutDialog(context);
                if (shouldLogout == true && mounted) {
                  final success = await _accountService.logout();
                  if (success && mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "로그아웃되었습니다.",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),

            // 계정 삭제
            _buildSettingButton(
              icon: Icons.delete,
              title: "계정 삭제",
              titleColor: Colors.red,
              onTap: () {
                showDeleteAccountDialog(context);
              },
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // 일반 설정 버튼
  Widget _buildSettingButton({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Icon(icon, color: titleColor, size: 24.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 16.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 토글 설정 버튼
  Widget _buildSettingToggle({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.black,
                activeTrackColor: Colors.black12,
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 비밀번호 변경 다이얼로그
  void _showPasswordChangeDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool showCurrentPassword = false;
    bool showNewPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              "비밀번호 변경",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 18.sp,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 현재 비밀번호
                  TextField(
                    controller: currentPwController,
                    obscureText: !showCurrentPassword,
                    decoration: InputDecoration(
                      labelText: "현재 비밀번호",
                      labelStyle: TextStyle(fontSize: 13.sp),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() => showCurrentPassword = !showCurrentPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 새 비밀번호
                  TextField(
                    controller: newPwController,
                    obscureText: !showNewPassword,
                    decoration: InputDecoration(
                      labelText: "새 비밀번호",
                      labelStyle: TextStyle(fontSize: 13.sp),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNewPassword ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() => showNewPassword = !showNewPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 비밀번호 확인
                  TextField(
                    controller: confirmPwController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호 확인",
                      labelStyle: TextStyle(fontSize: 13.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "취소",
                  style: TextStyle(color: Colors.black38),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPwController.text != confirmPwController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("새 비밀번호가 일치하지 않습니다."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final success = await _accountService.updatePassword(newPwController.text);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "비밀번호가 변경되었습니다.",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("비밀번호 변경에 실패했습니다."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text(
                  "변경하기",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}