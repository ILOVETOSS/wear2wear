import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = true;
  bool _messageNotification = true;
  bool _swapNotification = true;
  bool _likeNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SETTINGS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 설정 섹션
            _buildSectionHeader("알림 설정"),
            _buildSettingTile(
              icon: Icons.notifications_outlined,
              title: "알림 전체 활성화",
              subtitle: "모든 알림을 받습니다",
              value: _notificationEnabled,
              onChanged: (value) {
                setState(() => _notificationEnabled = value);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20.w, top: 12.h, bottom: 12.h),
              child: Text(
                "세부 알림 설정",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_notificationEnabled) ...[
              _buildSettingTile(
                icon: Icons.message_outlined,
                title: "메시지 알림",
                subtitle: "새 메시지를 받습니다",
                value: _messageNotification,
                onChanged: (value) {
                  setState(() => _messageNotification = value);
                },
                indent: true,
              ),
              _buildSettingTile(
                icon: Icons.swap_horiz_rounded,
                title: "교환 요청 알림",
                subtitle: "교환 요청 및 응답 알림",
                value: _swapNotification,
                onChanged: (value) {
                  setState(() => _swapNotification = value);
                },
                indent: true,
              ),
              _buildSettingTile(
                icon: Icons.favorite_outline,
                title: "좋아요 알림",
                subtitle: "좋아요를 받으면 알림",
                value: _likeNotification,
                onChanged: (value) {
                  setState(() => _likeNotification = value);
                },
                indent: true,
              ),
            ],

            SizedBox(height: 24.h),

            // 계정 설정 섹션
            _buildSectionHeader("계정"),
            _buildSettingButton(
              icon: Icons.lock_outline,
              title: "비밀번호 변경",
              onTap: () {
                // 비밀번호 변경 로직
              },
            ),
            _buildSettingButton(
              icon: Icons.email_outlined,
              title: "이메일 변경",
              onTap: () {
                // 이메일 변경 로직
              },
            ),
            _buildSettingButton(
              icon: Icons.privacy_tip_outlined,
              title: "개인정보 정책",
              onTap: () {
                // 개인정보 정책 보기
              },
            ),
            _buildSettingButton(
              icon: Icons.description_outlined,
              title: "이용약관",
              onTap: () {
                // 이용약관 보기
              },
            ),

            SizedBox(height: 24.h),

            // 앱 정보 섹션
            _buildSectionHeader("앱 정보"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "앱 버전",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "1.0.0",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "마지막 업데이트",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "2026년 2월 1일",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 위험 섹션
            _buildSectionHeader("기타"),
            _buildSettingButton(
              icon: Icons.info_outline,
              title: "고객 지원",
              onTap: () {
                // 고객 지원
              },
            ),
            _buildSettingButton(
              icon: Icons.delete_outline,
              title: "계정 삭제",
              titleColor: Colors.red,
              onTap: () {
                _showDeleteAccountDialog();
              },
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool indent = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        indent ? 56.w : 20.w,
        12.h,
        20.w,
        12.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              inactiveThumbColor: Colors.grey[300],
              inactiveTrackColor: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingButton({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFEEEEEE),
              width: 1.h,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: titleColor ?? Colors.black,
                  size: 20.sp,
                ),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.black26,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text(
          "계정을 삭제하시겠습니까?",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "계정 삭제 후에는 다음이 삭제됩니다:",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "• 프로필 정보\n• 업로드한 상품\n• 거래 내역\n• 메시지\n• 위시리스트",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.sp,
                height: 1.6,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "이 작업은 되돌릴 수 없습니다.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              // 계정 삭제 로직
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    "계정이 삭제되었습니다",
                    style: TextStyle(
                      color: Colors.white,  // ✅ 흰색
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text(
              "삭제",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}