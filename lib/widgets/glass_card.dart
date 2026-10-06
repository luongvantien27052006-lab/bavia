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
    // Cả 2 chế độ dùng nền "sân khấu" (tối: mận đậm, sáng: kem hồng).
    return _StageBackdrop(child: child);
  }
}

/// Nền "sân khấu" tĩnh cho các màn phụ: nền + 2 quầng sáng mờ (theo Sáng/Tối).
/// Vẽ bằng gradient (không blur, không chuyển động) -> rất nhẹ.
class _StageBackdrop extends StatelessWidget {
  final Widget child;
  const _StageBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: dark ? const Color(0xFF140B10) : const Color(0xFFFBF4F1)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.9, -1.0),
            radius: 1.1,
            colors: dark
                ? const [Color(0x55B8325C), Color(0x00B8325C)]
                : const [Color(0x33F2A1B8), Color(0x00F2A1B8)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.0, 0.9),
              radius: 1.0,
              colors: dark
                  ? const [Color(0x33E85D3C), Color(0x00E85D3C)]
                  : const [Color(0x2EFFC79A), Color(0x00FFC79A)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
