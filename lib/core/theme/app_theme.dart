// ============================================================
//  FLUTTER — lib/core/theme/app_theme.dart
//  >> THEM CHE DO TOI + getter mau doi theo che do.
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool dark = false;

  static const coffee = Color(0xFFE85D3C);
  static const coffeeDark = Color(0xFFC44A2C);
  static const delivery = Color(0xFFE23E57);
  static const pickup = Color(0xFF12A594);
  static const hot = Color(0xFFF77F18);
  static const success = Color(0xFF1EAB57);

  static const _textDarkL = Color(0xFF2D2521);
  static const _textMutedL = Color(0xFF857A70);
  static const _creamL = Color(0xFFFFF8F1);
  static const _surfaceL = Colors.white;
  static const _borderL = Color(0xFFEFE4D9);

  static const _textDarkD = Color(0xFFF2ECE6);
  static const _textMutedD = Color(0xFFA79A90);
  static const _creamD = Color(0xFF141210);
  static const _surfaceD = Color(0xFF211C19);
  static const _borderD = Color(0xFF37302B);

  static Color get textDark => dark ? _textDarkD : _textDarkL;
  static Color get textMuted => dark ? _textMutedD : _textMutedL;
  static Color get cream => dark ? _creamD : _creamL;
  static Color get surface => dark ? _surfaceD : _surfaceL;
  static Color get border => dark ? _borderD : _borderL;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coffee,
      primary: AppColors.coffee,
      brightness: Brightness.light,
    ).copyWith(surface: Colors.white);
    return _base(
      scheme: scheme,
      scaffold: Colors.white,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF2D2521),
      border: const Color(0xFFEFE4D9),
      fill: Colors.white,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coffee,
      primary: AppColors.coffee,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF211C19),
      onSurface: const Color(0xFFF2ECE6),
    );
    return _base(
      scheme: scheme,
      scaffold: const Color(0xFF141210),
      surface: const Color(0xFF211C19),
      onSurface: const Color(0xFFF2ECE6),
      border: const Color(0xFF37302B),
      fill: const Color(0xFF211C19),
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color border,
    required Color fill,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        centerTitle: true,
      ),
      cardColor: surface,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      canvasColor: surface,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.coffee,
        unselectedItemColor: onSurface.withOpacity(0.55),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coffee,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.coffee, width: 2),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}