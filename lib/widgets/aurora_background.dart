// ============================================================
//  FLUTTER — lib/widgets/aurora_background.dart  (MỚI)
//  Nền "cực quang": 3 vệt màu loang trôi chậm trên nền tối.
//  - Vẽ bằng gradient tròn (KHÔNG dùng BackdropFilter/blur) -> rất nhẹ.
//  - Đổi [tint] thì màu chuyển mượt sang màu mới.
//  - Tự đứng yên khi: [animate] = false, máy bật "Giảm chuyển động",
//    hoặc widget không hiển thị (TickerMode tắt).
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'drink_tint.dart';

class AuroraBackground extends StatefulWidget {
  final Color tint;
  final bool animate;

  /// Hoà dần phần đáy vào màu nền tối (để nối liền với nội dung bên dưới).
  final bool fadeToBase;

  /// Màu nền tối cố định (null = nền pha chút màu món).
  final Color? base;
  final Widget child;

  const AuroraBackground({
    super.key,
    required this.tint,
    required this.child,
    this.animate = true,
    this.fadeToBase = false,
    this.base,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );
  late Color _from = widget.tint;
  late Color _to = widget.tint;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncDrift();
  }

  @override
  void didUpdateWidget(covariant AuroraBackground old) {
    super.didUpdateWidget(old);
    if (old.tint != widget.tint) {
      // Bắt đầu từ màu đang hiển thị (kể cả khi đang chuyển dở).
      _from = Color.lerp(_from, _to, Curves.easeInOut.transform(_fade.value))!;
      _to = widget.tint;
      if (_reduceMotion) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    }
    if (old.animate != widget.animate) _syncDrift();
  }

  void _syncDrift() {
    final run = widget.animate && !_reduceMotion;
    if (run && !_drift.isAnimating) {
      _drift.repeat();
    } else if (!run && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // đổi Sáng/Tối -> vẽ lại
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AuroraPainter(
          drift: _drift,
          fade: _fade,
          from: _from,
          to: _to,
          fadeToBase: widget.fadeToBase,
          base: widget.base,
          dark: AppColors.dark,
        ),
        child: widget.child,
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> drift;
  final Animation<double> fade;
  final Color from;
  final Color to;
  final bool fadeToBase;
  final Color? base;
  final bool dark;

  _AuroraPainter({
    required this.drift,
    required this.fade,
    required this.from,
    required this.to,
    this.fadeToBase = false,
    this.base,
    this.dark = true,
  }) : super(repaint: Listenable.merge([drift, fade]));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    // Cắt gọn trong khung: vệt màu loang (bán kính lớn) không được tràn ra
    // ngoài -> tránh lộ 1 đường ngang ở mép dưới dải cực quang.
    canvas.clipRect(rect);
    final tint = Color.lerp(from, to, Curves.easeInOut.transform(fade.value))!;
    // Chế độ sáng: màu loang nhạt hơn (pha trắng) và trong hơn.
    final cols = DrinkTint.aurora(tint)
        .map((c) => dark ? c : Color.lerp(c, Colors.white, 0.25)!)
        .toList();
    final k = dark ? 1.0 : 0.6;

    final ground = base ?? DrinkTint.stageBase(tint);
    canvas.drawRect(rect, Paint()..color = ground);

    final w = size.width;
    final h = size.height;
    final a = drift.value * 2 * math.pi; // hệ số nguyên -> vòng lặp liền mạch
    final r = math.max(w, 320.0);

    _blob(canvas, Offset(w * (0.12 + 0.20 * math.sin(a)), h * (0.10 + 0.08 * math.cos(a))),
        r * 0.95, cols[0], 0.62 * k);
    _blob(canvas, Offset(w * (0.98 + 0.14 * math.cos(a + 1.3)), h * (0.42 + 0.10 * math.sin(a + 0.7))),
        r * 0.85, cols[1], 0.50 * k);
    _blob(canvas, Offset(w * (0.22 + 0.18 * math.cos(2 * a + 2.1)), h * (0.86 + 0.06 * math.sin(a + 2.6))),
        r * 0.95, cols[2], 0.42 * k);

    // Lớp phủ tối nhẹ trên/dưới để chữ trắng luôn dễ đọc (chỉ chế độ tối).
    if (dark) canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.04),
            Colors.black.withValues(alpha: 0.18),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );

    if (fadeToBase) {
      final fadeH = math.min(200.0, h * 0.3);
      final band = Rect.fromLTWH(0, h - fadeH, w, fadeH);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ground.withValues(alpha: 0), ground],
          ).createShader(band),
      );
    }
  }

  void _blob(Canvas canvas, Offset c, double radius, Color color, double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    canvas.drawCircle(c, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.from != from ||
      old.to != to ||
      old.fadeToBase != fadeToBase ||
      old.base != base ||
      old.dark != dark ||
      old.drift != drift ||
      old.fade != fade;
}
