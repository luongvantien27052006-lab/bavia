// ============================================================
//  FLUTTER — lib/widgets/anim.dart
//  Bộ hiệu ứng động dùng chung cho toàn app.
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// #4 Nhấn co nhẹ — bọc bất kỳ widget bấm được.
class PressEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const PressEffect({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// #3 Hiện dần + trượt lên, trễ theo [index] (staggered) khi list xuất hiện.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double offsetY;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offsetY = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration(milliseconds: 45 * widget.index.clamp(0, 12)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// #6 Ô shimmer (khung xương lúc tải).
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 10,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    final base =
        dark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);
    final hi =
        dark ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.75);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final dx = (_c.value * 2) - 1; // -1 .. 1
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(dx - 0.3, 0),
              end: Alignment(dx + 0.3, 0),
              colors: [base, hi, base],
            ),
          ),
        );
      },
    );
  }
}

/// #7 Chữ số đếm tăng dần tới [value].
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String Function(int)? format;
  final Duration duration;
  const CountUpText(
    this.value, {
    super.key,
    this.style,
    this.format,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.round();
        return Text(format != null ? format!(n) : '$n', style: style);
      },
    );
  }
}

/// #2 Bọc badge/con số: nảy "pop" mỗi khi giá trị đổi.
class PopOnChange extends StatefulWidget {
  final Object value;
  final Widget child;
  const PopOnChange({super.key, required this.value, required this.child});

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void didUpdateWidget(covariant PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // 1 -> 1.35 -> 1 (nảy)
        final s = 1 + 0.35 * (1 - (2 * _c.value - 1).abs());
        return Transform.scale(scale: s, child: child);
      },
      child: widget.child,
    );
  }
}

/// #5 Dấu tích thành công: nảy vào + vòng tròn lan toả (burst).
class SuccessCheck extends StatefulWidget {
  final double size;
  const SuccessCheck({super.key, this.size = 110});

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(double t, int i) {
    final start = 0.15 + i * 0.12;
    final rt = ((t - start) / (1 - start)).clamp(0.0, 1.0);
    final scale = 0.6 + rt * 1.15;
    final op = (1 - rt) * 0.5;
    return Opacity(
      opacity: op,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.success.withOpacity(0.6), width: 3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final popT = Curves.elasticOut.transform((t / 0.6).clamp(0.0, 1.0));
        return SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(t, 0),
              _ring(t, 1),
              Transform.scale(
                scale: popT,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: widget.size * 0.66),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/// Danh sách khung xương (shimmer) khi tải list.
class ShimmerList extends StatelessWidget {
  final int count;
  final double height;
  final EdgeInsetsGeometry padding;
  const ShimmerList({
    super.key,
    this.count = 5,
    this.height = 92,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => ShimmerBox(
          width: double.infinity, height: height, radius: 16),
    );
  }
}