import 'package:flutter/material.dart';

class AppTheme {
  // 메인 테마 색상 정의 (검은색 & 흰색)
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF1A1A1A); // 어두운 회색 (카드 배경 등)
  static const Color lightGrey = Colors.white24;

  static ThemeData get blackWhiteTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      primaryColor: white,
      canvasColor: black,
      
      // 앱바 테마
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: white),
      ),

      // 텍스트 테마
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: white, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: white),
        bodyMedium: TextStyle(color: white),
        labelLarge: TextStyle(color: white),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // 바텀 네비게이션 테마
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: black,
        selectedItemColor: white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // 카드 테마 (CardThemeData 사용)
      cardTheme: CardThemeData(
        color: grey,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 입력창 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey,
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      
      colorScheme: const ColorScheme.dark(
        primary: white,
        onPrimary: black,
        secondary: white,
        onSecondary: black,
        surface: black,
        onSurface: white,
        error: Colors.redAccent,
      ),
    );
  }
}
