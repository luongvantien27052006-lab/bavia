// ============================================================
//  FLUTTER — lib/providers/display_settings_provider.dart
//  Cài đặt giao diện: hiệu ứng kính, ảnh hiện dần, màu nền, hiện dần khi lướt.
//  Lưu bằng SharedPreferences (bền qua kill app), đọc ĐỒNG BỘ trong build()
//  nhờ prefs được nạp sẵn ở main().
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

const _kGlass = 'ui_glass_effect';
const _kImgFade = 'ui_image_fade';
const _kColorBg = 'ui_color_bg_light';
const _kItemAnim = 'ui_item_anim';

class DisplaySettings {
  final bool glass; // hiệu ứng kính (mờ nền)
  final bool imageFade; // ảnh món hiện dần
  final bool colorBg; // màu nền gradient ở chế độ SÁNG
  final bool itemAnim; // món trượt/hiện dần khi lướt menu

  // Mặc định TẮT hết hiệu ứng (kính, ảnh hiện dần, màu nền) cho nhẹ máy.
  const DisplaySettings({
    this.glass = false,
    this.imageFade = false,
    this.colorBg = false,
    this.itemAnim = false,
  });

  DisplaySettings copyWith(
          {bool? glass, bool? imageFade, bool? colorBg, bool? itemAnim}) =>
      DisplaySettings(
        glass: glass ?? this.glass,
        imageFade: imageFade ?? this.imageFade,
        colorBg: colorBg ?? this.colorBg,
        itemAnim: itemAnim ?? this.itemAnim,
      );
}

class DisplaySettingsNotifier extends Notifier<DisplaySettings> {
  @override
  DisplaySettings build() {
    final p = ref.read(sharedPrefsProvider);
    return DisplaySettings(
      glass: p.getBool(_kGlass) ?? false,
      imageFade: p.getBool(_kImgFade) ?? false,
      colorBg: p.getBool(_kColorBg) ?? false,
      itemAnim: p.getBool(_kItemAnim) ?? false,
    );
  }

  Future<void> _save(String key, bool v) async {
    try {
      await ref.read(sharedPrefsProvider).setBool(key, v);
    } catch (_) {}
  }

  Future<void> setGlass(bool v) async {
    state = state.copyWith(glass: v);
    await _save(_kGlass, v);
  }

  Future<void> setImageFade(bool v) async {
    state = state.copyWith(imageFade: v);
    await _save(_kImgFade, v);
  }

  Future<void> setColorBg(bool v) async {
    state = state.copyWith(colorBg: v);
    await _save(_kColorBg, v);
  }

  Future<void> setItemAnim(bool v) async {
    state = state.copyWith(itemAnim: v);
    await _save(_kItemAnim, v);
  }
}

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsNotifier, DisplaySettings>(
        DisplaySettingsNotifier.new);
