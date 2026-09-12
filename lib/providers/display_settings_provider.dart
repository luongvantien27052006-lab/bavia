// ============================================================
//  FLUTTER — lib/providers/display_settings_provider.dart (MỚI)
//  Cài đặt giao diện: hiệu ứng kính, ảnh hiện dần, màu nền (chế độ sáng).
//  Lưu lựa chọn vào thiết bị (như theme).
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
const _kGlass = 'ui_glass_effect';
const _kImgFade = 'ui_image_fade';
const _kColorBg = 'ui_color_bg_light';

class DisplaySettings {
  final bool glass; // hiệu ứng kính (mờ nền)
  final bool imageFade; // ảnh món hiện dần
  final bool colorBg; // màu nền gradient ở chế độ SÁNG

  // Mặc định TẮT hết hiệu ứng (kính, ảnh hiện dần, màu nền) cho nhẹ máy.
  const DisplaySettings({
    this.glass = false,
    this.imageFade = false,
    this.colorBg = false,
  });

  DisplaySettings copyWith({bool? glass, bool? imageFade, bool? colorBg}) =>
      DisplaySettings(
        glass: glass ?? this.glass,
        imageFade: imageFade ?? this.imageFade,
        colorBg: colorBg ?? this.colorBg,
      );
}

class DisplaySettingsNotifier extends Notifier<DisplaySettings> {
  @override
  DisplaySettings build() {
    _load();
    return const DisplaySettings();
  }

  Future<void> _load() async {
    try {
      final g = await _storage.read(key: _kGlass);
      final f = await _storage.read(key: _kImgFade);
      final c = await _storage.read(key: _kColorBg);
      state = DisplaySettings(
        glass: g == 'on',
        imageFade: f == 'on',
        colorBg: c == 'on',
      );
    } catch (_) {}
  }

  Future<void> _save(String key, bool v) async {
    try {
      await _storage.write(key: key, value: v ? 'on' : 'off');
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
}

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsNotifier, DisplaySettings>(
        DisplaySettingsNotifier.new);