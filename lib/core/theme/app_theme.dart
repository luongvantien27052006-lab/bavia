// ============================================================
//  FLUTTER
//  lib/core/theme/app_theme.dart
//  >> CHEP DE (nen trang tinh)
// ============================================================

// ============================================================
//  FLUTTER
//  lib/core/theme/app_theme.dart
//  >> CHEP DE — bang mau 'quan trai cay tuoi' (giu ten bien, doi gia tri)
// ============================================================

// lib/core/theme/app_theme.dart
//
// Theme Material 3 cho Bavia — bảng màu "quán trái cây tươi": nền kem sáng,
// hero màu CORAL, điểm nhấn mâm xôi / teal / xoài / lá. Tươi sáng, ngon mắt,
// vẫn đủ tương phản cho chữ trắng trên nút và chữ/icon trên nền sáng.
//
// LƯU Ý: tên biến giữ nguyên (coffee/delivery/pickup...) để toàn app dùng lại
// được; chỉ GIÁ TRỊ đổi. "coffee" giờ là màu coral chủ đạo.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const coffee = Color(0xFFE85D3C); // CORAL — màu hero chủ đạo
  static const coffeeDark = Color(0xFFC44A2C); // coral đậm (gradient/nhấn)
  static const cream = Color(0xFFFFF8F1); // nền kem sáng
  static const delivery = Color(0xFFE23E57); // GIAO HÀNG / cảnh báo (mâm xôi)
  static const pickup = Color(0xFF12A594); // TỰ LẤY (teal tươi)
  static const hot = Color(0xFFF77F18); // Món hot (xoài/cam)
  static const success = Color(0xFF1EAB57); // thành công (lá tươi)
  static const textDark = Color(0xFF2D2521); // chữ đậm
  static const textMuted = Color(0xFF857A70); // chữ phụ

  // Màu phụ trợ cho nền/viền sáng (dùng nội bộ theme)
  static const _border = Color(0xFFEFE4D9);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coffee,
      primary: AppColors.coffee,
      brightness: Brightness.light,
    ).copyWith(surface: Colors.white);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coffee,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.coffee, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}