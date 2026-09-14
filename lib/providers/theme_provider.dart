// ============================================================
//  FLUTTER — lib/providers/theme_provider.dart
//  Chế độ Sáng/Tối. Lưu bằng SharedPreferences (bền qua kill app),
//  đọc ĐỒNG BỘ ngay trong build() nhờ prefs được nạp sẵn ở main().
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

const _kThemeKey = 'app_theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Đọc đồng bộ giá trị đã lưu -> áp đúng chế độ ngay từ frame đầu.
    final v = ref.read(sharedPrefsProvider).getString(_kThemeKey);
    return v == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await ref.read(sharedPrefsProvider).setString(_kThemeKey, mode.name);
    } catch (_) {}
  }

  /// Bật/tắt nhanh: đang tối -> sáng, đang sáng -> tối.
  Future<void> toggle() => setMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
