// ============================================================
//  FLUTTER — lib/providers/theme_provider.dart
//  Quan ly che do Sang/Toi bang Riverpod, luu lua chon vao thiet bi.
//  Chi 2 che do: ThemeMode.light / ThemeMode.dark.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kThemeKey = 'app_theme_mode';

const _storage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load(); // doc lua chon da luu (bat dong bo), mac dinh SANG
    return ThemeMode.light;
  }

  Future<void> _load() async {
    try {
      final v = await _storage.read(key: _kThemeKey);
      if (v == 'dark') state = ThemeMode.dark;
      if (v == 'light') state = ThemeMode.light;
    } catch (_) {
      // bo qua loi doc -> giu mac dinh
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _kThemeKey, value: mode.name);
    } catch (_) {}
  }

  /// Bat/tat nhanh: dang toi -> sang, dang sang -> toi.
  Future<void> toggle() => setMode(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);