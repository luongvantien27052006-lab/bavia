// ============================================================
//  FLUTTER — lib/widgets/hot_coverflow.dart  (MỚI)
//  "Kệ trưng bày xoay" cho mục Món hot ở Trang chủ:
//   - Món giữa nổi lên, bập bềnh nhẹ, có vòng sáng + bệ phát sáng theo màu món.
//   - Hai bên nghiêng ra sau (phối cảnh 3D), nhỏ và mờ dần.
//   - Vuốt ngang để đổi món; chạm món giữa để mở chi tiết, chạm món bên để xoay tới.
//  Chỉ dùng Transform + gradient -> mượt trên máy tầm trung.
// ============================================================

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'stage.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../utils/formatters.dart';
import 'drink_tint.dart';
import 'product_photo.dart';

class HotCoverflow extends StatefulWidget {
  final List<Product> products;

  /// Gọi khi món ở giữa thay đổi (kể cả lần đầu) -> để đổi màu nền.
  final ValueChanged<Product>? onFocus;

  /// Mở chi tiết món. [heroTag] dùng cho hiệu ứng ảnh bay sang trang chi tiết.
  final void Function(Product product, String heroTag) onOpen;

  const HotCoverflow({
    super.key,
    required this.products,
    required this.onOpen,
    this.onFocus,
  });

  static String heroTagOf(Product p) => 'hot-${p.id}';

  @override
  State<HotCoverflow> createState() => _HotCoverflowState();
}

class _HotCoverflowState extends State<HotCoverflow>
    with SingleTickerProviderStateMixin {
  static const double _stageH = 292;
  static const double _cardW = 178;
  static const double _cardH = 232;

  late int _index = widget.products.length >= 3 ? 1 : 0;
  late final PageController _pc =
      PageController(viewportFraction: 0.56, initialPage: _index);
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyFocus());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      _bob
        ..stop()
        ..value = 0.5;
    } else if (!_bob.isAnimating) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HotCoverflow old) {
    super.didUpdateWidget(old);
    if (widget.products.isEmpty) return;
    if (_index >= widget.products.length) {
      _index = widget.products.length - 1;
      if (_pc.hasClients) _pc.jumpToPage(_index);
    }
    final oldId = _index < old.products.length ? old.products[_index].id : null;
    if (oldId != widget.products[_index].id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyFocus());
    }
  }

  void _notifyFocus() {
    if (!mounted || widget.products.isEmpty) return;
    widget.onFocus?.call(widget.products[_index]);
  }

  @override
  void dispose() {
    _pc.dispose();
    _bob.dispose();
    super.dispose();
  }

  double get _page {
    if (_pc.hasClients && _pc.position.haveDimensions) {
      return _pc.page ?? _index.toDouble();
    }
    return _index.toDouble();
  }

  void _goTo(int i) {
    _pc.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    final current = products[_index];
    final tint = DrinkTint.of(current);

    return Column(
      children: [
        SizedBox(
          height: _stageH,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Vòng sáng phía sau món giữa (đổi màu mượt theo món).
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.1),
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: tint),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, c, __) => Container(
                        width: 330,
                        height: 330,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            (c ?? tint).withValues(alpha: 0.55),
                            (c ?? tint).withValues(alpha: 0.0),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bệ phát sáng dưới chân món giữa.
              Positioned(
                top: _stageH - 40,
                child: IgnorePointer(child: _Podium(tint: tint)),
              ),
              PageView.builder(
                controller: _pc,
                clipBehavior: Clip.none,
                itemCount: products.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _index = i);
                  _notifyFocus();
                },
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: Listenable.merge([_pc, _bob]),
                  builder: (context, _) => _item(i),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Tên + giá món giữa (chuyển mờ khi đổi món).
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Column(
            key: ValueKey(current.id),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  current.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style:  TextStyle(
                    color: St.fg(),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.money(current.price),
                style: TextStyle(
                  color: St.fg(0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundButton(
              icon: Icons.chevron_left_rounded,
              label: 'Món trước',
              onTap: _index > 0 ? () => _goTo(_index - 1) : null,
            ),
            const SizedBox(width: 10),
            Material(
              color: St.solid,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    widget.onOpen(current, HotCoverflow.heroTagOf(current)),
                child:  Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded,
                          size: 18, color: St.onSolid),
                      SizedBox(width: 8),
                      Text('Chọn món này',
                          style: TextStyle(
                              color: St.onSolid,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _RoundButton(
              icon: Icons.chevron_right_rounded,
              label: 'Món sau',
              onTap: _index < products.length - 1
                  ? () => _goTo(_index + 1)
                  : null,
            ),
          ],
        ),
        if (products.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < products.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: St.solid
                        .withValues(alpha: i == _index ? 1 : 0.32),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _item(int i) {
    final p = widget.products[i];
    final d = (i - _page).clamp(-2.0, 2.0);
    final ad = d.abs();
    final near = (1 - ad).clamp(0.0, 1.0); // 1 = đang ở giữa
    final side = ad.clamp(0.0, 1.0);
    final scale = 1 - 0.24 * side;
    final bob = Curves.easeInOut.transform(_bob.value) * 10 * near;

    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0013) // phối cảnh
      ..multiply(Matrix4.translationValues(-d * 26, 16 * side - bob, 0))
      ..rotateY(-d * 0.62)
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1));

    final tag = HotCoverflow.heroTagOf(p);
    final tint = DrinkTint.of(p);

    return Align(
      alignment: const Alignment(0, -0.35),
      child: Transform(
        alignment: Alignment.center,
        transform: m,
        child: Opacity(
          opacity: (1 - 0.4 * ad).clamp(0.0, 1.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (ad < 0.5) {
                widget.onOpen(p, tag);
              } else {
                _goTo(i);
              }
            },
            child: Semantics(
              button: true,
              label: '${p.name}, ${Formatters.money(p.price)}',
              child: Container(
                width: _cardW,
                height: _cardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.5 * near),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Hero(
                  tag: tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductPhoto(product: p),
                        // Vệt bóng kính chéo cho cảm giác "khối".
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.10),
                                ],
                                stops: const [0, 0.42, 1],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final Color tint;
  const _Podium({required this.tint});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: tint),
      duration: const Duration(milliseconds: 600),
      builder: (_, c, __) {
        final color = c ?? tint;
        return SizedBox(
          width: 210,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.all(Radius.elliptical(105, 18)),
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.0),
                  ]),
                ),
              ),
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.all(Radius.elliptical(75, 7)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.9),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: St.fill(enabled ? 0.14 : 0.06),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon,
                color: St.fg(enabled ? 1 : 0.35)),
          ),
        ),
      ),
    );
  }
}
