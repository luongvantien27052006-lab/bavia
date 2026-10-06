// ============================================================
//  FLUTTER — lib/providers/home_tint_provider.dart  (MỚI)
//  Màu của món hot đang ở giữa kệ Trang chủ. Trang chủ ghi, thanh điều hướng
//  đọc để mục đang chọn phát sáng cùng tông với nền cực quang.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/drink_tint.dart';

final homeTintProvider = StateProvider<Color>((_) => DrinkTint.fallback);
