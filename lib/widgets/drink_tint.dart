// ============================================================
//  FLUTTER — lib/widgets/drink_tint.dart  (MỚI)
//  Đoán "màu của món" từ tên + danh mục (không cần ảnh, không tốn CPU)
//  để tô ánh sáng nền / cực quang / vòng sáng dưới ly cho đúng vị món.
//  Muốn đổi màu 1 loại quả: sửa bảng _rules bên dưới.
// ============================================================

import 'package:flutter/material.dart';

import '../models/product.dart';

class DrinkTint {
  DrinkTint._();

  /// Màu mặc định (hồng mọng) khi không nhận ra món.
  static const fallback = Color(0xFFE0607A);

  /// Nền tối của "sân khấu" (ánh mận rất đậm).
  static const stageInk = Color(0xFF140B10);

  // Từ khoá viết KHÔNG DẤU, so theo nguyên từ. Thứ tự quan trọng:
  // cụm cụ thể đặt trước (vd "dua hau" trước "dua").
  static const List<(List<String>, Color)> _rules = [
    (['mong'], Color(0xFFC2335E)),
    (['dau tam', 'mulberry'], Color(0xFFC2335E)),
    (['viet quat', 'blueberry'], Color(0xFF7457E0)),
    (['mam xoi', 'raspberry'], Color(0xFFE0315B)),
    (['dua hau', 'watermelon'], Color(0xFFFF5A5F)),
    (['dua luoi', 'melon'], Color(0xFFF7A35C)),
    (['dau', 'strawberry'], Color(0xFFFF4F6E)),
    (['xoai', 'mango'], Color(0xFFFFB020)),
    (['chanh day', 'passion'], Color(0xFFF5A623)),
    (['cam', 'orange'], Color(0xFFFF8A1F)),
    (['thom', 'dua', 'pineapple'], Color(0xFFF2C230)),
    (['oi', 'guava'], Color(0xFFFF7A8A)),
    (['vai', 'lychee'], Color(0xFFFF8FA3)),
    (['dao', 'peach'], Color(0xFFFF9E7A)),
    (['kiwi'], Color(0xFF8BC34A)),
    (['bo', 'avocado'], Color(0xFF9CBF4A)),
    (['matcha', 'tra xanh'], Color(0xFF7CC35A)),
    (['khoai mon', 'taro'], Color(0xFFA77BD8)),
    (['tac', 'quat', 'chanh', 'lemon', 'lime'], Color(0xFFB5D33D)),
    (['socola', 'chocolate', 'cacao', 'ca cao'], Color(0xFFA0603E)),
    (['ca phe', 'cafe', 'coffee', 'bac xiu', 'espresso'], Color(0xFFC8814A)),
    (['sua chua', 'yogurt'], Color(0xFFF0A6C0)),
    (['tra sua', 'sua'], Color(0xFFD9A577)),
    (['tra', 'tea'], Color(0xFFE8A13A)),
    (['banh', 'cake'], Color(0xFFD99A5B)),
    (['trai cay', 'fruit'], Color(0xFFFF7A59)),
  ];

  static final Map<String, Color> _cache = {};

  /// Màu đặc trưng của món.
  static Color of(Product p) {
    final key = '${p.name}|${p.category}';
    return _cache[key] ??= _resolve(' ${_norm(p.name)} ', ' ${_norm(p.category)} ');
  }

  static Color _resolve(String name, String category) {
    // Ưu tiên tên món, sau đó mới tới danh mục.
    for (final text in [name, category]) {
      for (final (words, color) in _rules) {
        for (final w in words) {
          if (text.contains(' $w ')) return color;
        }
      }
    }
    return fallback;
  }

  // ── Bỏ dấu tiếng Việt + chữ thường + chỉ giữ chữ/số ──
  static const _accents =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static final String _plain = '${'a' * 17}${'e' * 11}${'i' * 5}'
      '${'o' * 17}${'u' * 11}${'y' * 5}d';

  static String _norm(String s) {
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final i = _accents.indexOf(ch);
      final c = i >= 0 ? _plain[i] : ch;
      final code = c.codeUnitAt(0);
      final isAlnum = (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
      b.write(isAlnum ? c : ' ');
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 3 màu cho nền cực quang, lấy từ màu món (cùng tông, lệch sắc nhẹ).
  static List<Color> aurora(Color tint) {
    final h = HSLColor.fromColor(tint);
    HSLColor tune(HSLColor c) => c
        .withSaturation(c.saturation.clamp(0.55, 0.9))
        .withLightness(c.lightness.clamp(0.42, 0.58));
    return [
      tune(h).toColor(),
      tune(h.withHue((h.hue + 38) % 360)).withLightness(0.40).toColor(),
      tune(h.withHue((h.hue + 322) % 360)).toColor(),
    ];
  }

  /// Nền tối pha chút màu món (dùng cho app bar khi thu gọn).
  static Color stageBase(Color tint) => Color.lerp(stageInk, tint, 0.12)!;
}
