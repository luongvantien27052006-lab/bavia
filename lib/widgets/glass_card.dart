// ============================================================
//  FLUTTER — lib/widgets/glass_card.dart
//  Thẻ "kính mờ" (glassmorphism) dùng chung cho toàn app.
//   - blur > 0  : làm mờ nền phía sau (đẹp; dùng cho thẻ tĩnh, số lượng ít).
//   - blur == 0 : chỉ nền bán trong suốt + viền (nhẹ; dùng trong list cuộn).
//  Màu tự đổi theo chế độ Sáng/Tối qua AppColors.dark.
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/display_settings_provider.dart';
import 'anim.dart';

class GlassCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tint; // màu phủ tuỳ chọn (vd cảnh báo)
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.blur = 14,
    this.tint,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = AppColors.dark;
    final glassOn = ref.watch(displaySettingsProvider.select((x) => x.glass));
    final effBlur = glassOn ? blur : 0.0;
    // Tắt kính -> thẻ đặc hơn cho dễ đọc (không còn mờ nền).
    final fill = tint ??
        (dark
            ? Colors.white.withOpacity(glassOn ? 0.07 : 0.10)
            : Colors.white.withOpacity(glassOn ? 0.55 : 0.92));
    final border = borderColor ??
        (dark
            ? Colors.white.withOpacity(0.14)
            : Colors.white.withOpacity(0.65));
    final br = BorderRadius.circular(radius);

    Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: br,
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );

    // Lớp kính (mờ nền nếu blur>0)
    Widget glass = ClipRRect(
      borderRadius: br,
      child: effBlur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: effBlur, sigmaY: effBlur),
              child: inner,
            )
          : inner,
    );

    // Bóng đổ nằm NGOÀI lớp clip để không bị cắt
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.28 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: glass,
    );

    if (onTap != null) {
      card = PressEffect(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Nền gradient "kính mờ" cho cả màn (đặt sau nội dung).
/// Màu tự đổi theo Sáng/Tối.
class GlassBackground extends ConsumerWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = AppColors.dark;
    final colorBg =
        ref.watch(displaySettingsProvider.select((x) => x.colorBg));
    // Chế độ SÁNG + tắt màu nền -> nền phẳng nhạt; còn lại giữ gradient.
    if (!dark && !colorBg) {
      return ColoredBox(color: const Color(0xFFFDF6EF), child: child);
    }
    final colors = dark
        ? const [Color(0xFF1E1510), Color(0xFF241A1E), Color(0xFF14201D)]
        : const [Color(0xFFFFEEDD), Color(0xFFFFE1E9), Color(0xFFDFF3EE)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}