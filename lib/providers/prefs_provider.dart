// lib/providers/prefs_provider.dart
//
// SharedPreferences được nạp SẴN trong main() (trước runApp) rồi override
// vào provider này. Nhờ vậy các provider cài đặt (theme, giao diện) đọc được
// giá trị đã lưu NGAY trong build() (đồng bộ) — không nhấp nháy, không race,
// và bền vững qua việc OS kill app (khác flutter_secure_storage).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPrefsProvider phải được override trong main() bằng ProviderScope',
  ),
);
