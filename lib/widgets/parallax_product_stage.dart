// ============================================================
//  FLUTTER — lib/widgets/parallax_product_stage.dart  (MỚI)
//  Đầu trang chi tiết món: "ly nổi chiều sâu".
//   - Nền cực quang theo màu món.
//   - 3 lớp chiều sâu: hạt sáng xa (mờ) — ảnh món — hạt sáng gần (to).
//   - NGHIÊNG ĐIỆN THOẠI (cảm biến gia tốc) -> các lớp trượt lệch nhau,
//     ảnh món xoay nhẹ theo phối cảnh => cảm giác 3D.
//   - Vuốt ngang trên ảnh cũng nghiêng được (máy không có cảm biến).
//   - Không có cảm biến: tự đung đưa rất nhẹ. Bật "Giảm chuyển động": đứng yên.
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/product.dart';
import 'aurora_background.dart';
import 'drink_tint.dart';
import 'product_photo.dart';

class ParallaxProductStage extends StatefulWidget {
  final Product product;
  final String heroTag;

  /// Khoảng trống phía trên dành cho thanh trạng thái + app bar.
  final double topInset;

  const ParallaxProductStage({
    super.key,
    required this.product,
    required this.heroTag,
    this.topInset = 0,
  });

  @override
  State<ParallaxProductStage> createState() => _ParallaxProductStageState();
}

class _ParallaxProductStageState extends State<ParallaxProductStage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);
  late final Ticker _ticker = createTicker(_onTick);
  StreamSubscription<AccelerometerEvent>? _sub;

  Offset _target = Offset.zero; // độ nghiêng từ cảm biến (-1..1)
  Offset _current = Offset.zero; // giá trị đã làm mượt
  Offset? _drag; // vuốt tay (ưu tiên hơn cảm biến)
  double? _baseX, _baseY; // tư thế cầm máy "trung tính" (tự thích nghi)
  DateTime _lastSensor = DateTime.fromMillisecondsSinceEpoch(0);
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccel, onError: (_) {}, cancelOnError: true);
    } catch (_) {
      // Máy không có cảm biến -> dùng chế độ tự đung đưa.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
      _current = Offset.zero;
      _tilt.value = Offset.zero;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onAccel(AccelerometerEvent e) {
    // Lấy chênh lệch so với tư thế cầm máy hiện tại (tự trôi về chậm),
    // nên cầm thẳng hay nằm nghiêng đều bắt đầu ở giữa.
    final bx = _baseX ??= e.x;
    final by = _baseY ??= e.y;
    _baseX = bx + (e.x - bx) * 0.015;
    _baseY = by + (e.y - by) * 0.015;
    _target = Offset(
      (-(e.x - _baseX!) / 2.4).clamp(-1.0, 1.0),
      ((e.y - _baseY!) / 2.4).clamp(-1.0, 1.0),
    );
    _lastSensor = DateTime.now();
  }

  void _onTick(Duration elapsed) {
    Offset goal;
    if (_drag != null) {
      goal = _drag!;
    } else if (DateTime.now().difference(_lastSensor).inMilliseconds < 1500) {
      goal = _target;
    } else {
      final t = elapsed.inMilliseconds / 1000.0;
      goal = Offset(math.sin(t / 1.6) * 0.45, math.sin(t / 2.3) * 0.25);
    }
    _current = Offset.lerp(_current, goal, 0.085)!;
    if ((_current - _tilt.value).distanceSquared > 1e-6) {
      _tilt.value = _current;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = DrinkTint.of(widget.product);
    final seed = widget.product.id.hashCode;

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final top = widget.topInset;
      final avail = math.max(120.0, h - top - 56);
      final img = math.min(w * 0.62, avail);
      final cy = top + (h - top) / 2 - 8;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) {
          _drag = Offset(
            ((d.localPosition.dx / w) - 0.5).clamp(-0.5, 0.5) * 2,
            ((d.localPosition.dy / h) - 0.5).clamp(-0.5, 0.5) * 2,
          );
        },
        onHorizontalDragEnd: (_) => _drag = null,
        onHorizontalDragCancel: () => _drag = null,
        child: AuroraBackground(
          tint: tint,
          animate: !_reduceMotion,
          child: SizedBox(
            width: w,
            height: h,
            child: ValueListenableBuilder<Offset>(
              valueListenable: _tilt,
              builder: (context, t, _) {
                final photo = Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..multiply(Matrix4.translationValues(t.dx * 8, t.dy * 6, 0))
                    ..rotateY(t.dx * 0.30)
                    ..rotateX(-t.dy * 0.22),
                  child: Container(
                    width: img,
                    height: img,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: tint.withValues(alpha: 0.55),
                          blurRadius: 48,
                          offset: Offset(-t.dx * 14, 24 - t.dy * 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 22,
                          offset: Offset(-t.dx * 8, 14),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: widget.heroTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ProductPhoto(product: widget.product, cacheWidth: 800),
                            // Vệt sáng chạy theo hướng nghiêng.
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1 + t.dx * 0.6, -1),
                                    end: Alignment(1 + t.dx * 0.6, 1),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.26),
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.black.withValues(alpha: 0.10),
                                    ],
                                    stops: const [0, 0.45, 1],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Lớp XA: trượt ngược chiều, chậm.
                    Transform.translate(
                      offset: Offset(-t.dx * 12, -t.dy * 10),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(w, h),
                          painter: _BokehPainter(seed: seed, tint: tint, near: false),
                        ),
                      ),
                    ),
                    // Bệ sáng dưới ảnh.
                    Positioned(
                      left: (w - img * 1.05) / 2 + t.dx * 6,
                      top: cy + img / 2 + 2,
                      child: IgnorePointer(
                        child: Container(
                          width: img * 1.05,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                                Radius.elliptical(img * 0.525, 15)),
                            gradient: RadialGradient(colors: [
                              tint.withValues(alpha: 0.55),
                              tint.withValues(alpha: 0.0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    // Ảnh món.
                    Positioned(
                      left: (w - img) / 2,
                      top: cy - img / 2,
                      child: photo,
                    ),
                    // Lớp GẦN: trượt cùng chiều, nhanh hơn.
                    IgnorePointer(
                      child: Transform.translate(
                        offset: Offset(t.dx * 28, t.dy * 22),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(w, h),
                            painter: _BokehPainter(seed: seed, tint: tint, near: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

/// Hạt sáng (bokeh) ngẫu nhiên nhưng CỐ ĐỊNH theo món (seed) -> không nhấp nháy.
class _BokehPainter extends CustomPainter {
  final int seed;
  final Color tint;
  final bool near;

  _BokehPainter({required this.seed, required this.tint, required this.near});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed ^ (near ? 0x5f3759df : 0x1b873593));
    final count = near ? 6 : 12;
    for (var i = 0; i < count; i++) {
      // Lớp gần: ưu tiên mép trái/phải để không che ảnh món.
      final x = near
          ? (rnd.nextBool()
              ? rnd.nextDouble() * 0.24
              : 0.76 + rnd.nextDouble() * 0.24)
          : rnd.nextDouble();
      final y = 0.12 + rnd.nextDouble() * 0.82;
      final r = near ? 7 + rnd.nextDouble() * 15 : 2.5 + rnd.nextDouble() * 7;
      final useWhite = rnd.nextDouble() < 0.45;
      final base = useWhite ? Colors.white : Color.lerp(tint, Colors.white, 0.35)!;
      final alpha = near ? 0.22 + rnd.nextDouble() * 0.25 : 0.18 + rnd.nextDouble() * 0.32;
      final blur = near ? 3 + rnd.nextDouble() * 5 : 1.5 + rnd.nextDouble() * 2.5;
      final paint = Paint()
        ..color = base.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
    // Vài tia lấp lánh nhỏ ở lớp xa.
    if (!near) {
      final p = Paint()..color = Colors.white.withValues(alpha: 0.7);
      for (var i = 0; i < 4; i++) {
        final c = Offset(rnd.nextDouble() * size.width,
            (0.15 + rnd.nextDouble() * 0.7) * size.height);
        final s = 3 + rnd.nextDouble() * 3;
        final path = Path()
          ..moveTo(c.dx, c.dy - s)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
          ..close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter old) =>
      old.seed != seed || old.tint != tint || old.near != near;
}
