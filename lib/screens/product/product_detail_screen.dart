// ================================================================
//  FLUTTER APP (package bavia)
//  lib/screens/product/product_detail_screen.dart
//  >> CHEP DE (them chon KICH CO cho danh muc "Trái cây chấm muối":
//     size THAY gia thay vi cong; mac dinh S; kem dinh luong 400/600/800g)
// ================================================================

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../widgets/favorite_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/menu_pricing.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/group_order_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stage.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/product_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  final String? heroTag;
  const ProductDetailScreen({super.key, required this.product,
    this.heroTag,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  final Set<String> _selectedIds = {}; // topping (ngoai size)
  String? _selectedSizeId; // size dang chon (chi danh muc trai cay)

  // Món có cơ chế size (nhận theo nhóm 'Kích cỡ', không theo tên category).
  bool get _isFruit => hasSizeOptions(widget.product);
  List<ProductOption> get _sizeOpts => sizeOptionsOf(widget.product);
  List<ProductOption> get _nonSizeOpts => nonSizeOptionsOf(widget.product);

  @override
  void initState() {
    super.initState();
    // Danh muc trai cay: mac dinh chon size dau tien (S).
    if (_isFruit && _sizeOpts.isNotEmpty) {
      _selectedSizeId = _sizeOpts.first.id;
    }
  }

  int get _toppingTotal => _nonSizeOpts
      .where((o) => _selectedIds.contains(o.id))
      .fold(0, (s, o) => s + o.price);

  /// Gia 1 don vi hien tai (da tinh size THAY gia neu la trai cay).
  int get _unitPrice {
    if (_isFruit) {
      final size = _sizeOpts.where((o) => o.id == _selectedSizeId);
      final base = size.isNotEmpty ? size.first.price : widget.product.price;
      return base + _toppingTotal;
    }
    return widget.product.price + _toppingTotal;
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _addToCart() async {
    final selected = <ProductOption>[];
    // Trai cay: kem size da chon vao gio (de tinh gia + validate backend).
    if (_isFruit && _selectedSizeId != null) {
      final size = _sizeOpts.where((o) => o.id == _selectedSizeId);
      if (size.isNotEmpty) selected.add(size.first);
    }
    selected.addAll(_nonSizeOpts.where((o) => _selectedIds.contains(o.id)));

    // ─── Chế độ ĐẶT CHUNG: thêm vào PHÒNG, KHÔNG vào giỏ thường ───
    final groupId = ref.read(activeGroupProvider);
    if (groupId != null) {
      try {
        await ref.read(groupOrderRepositoryProvider).addItem(
              groupId,
              productId: widget.product.id,
              quantity: _qty,
              options: selected,
              unitPrice: _unitPrice,
              productName: widget.product.name,
            );
        ref.invalidate(groupRoomProvider(groupId));
        ref.invalidate(activeGroupRoomProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã thêm $_qty ${widget.product.name} vào phòng'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không thêm được món vào phòng'),
          backgroundColor: AppColors.delivery,
        ));
      }
      return;
    }


    ref.read(cartProvider.notifier).add(
          widget.product,
          quantity: _qty,
          options: selected,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_qty ${widget.product.name} vào giỏ'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final lineTotal = _unitPrice * _qty;
    // Trai cay: gia tren cung doi theo size dang chon; mon khac: giu gia goc.
    final headlinePrice = _isFruit ? _unitPrice : p.price;
    final tint = DrinkTint.of(p);
    final base = DrinkTint.stageBase(tint);
    final inGroup = ref.watch(activeGroupProvider) != null;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: base,
      extendBody: true,
      body: Stack(
        children: [
          // Nền cả màn: chính ảnh món phóng to + làm mờ mạnh -> màu luôn khớp món.
          Positioned.fill(child: _AmbientBackdrop(product: p, base: base)),
          CustomScrollView(
        slivers: [
          // Đầu trang: ảnh món tràn viền như bản cũ (không dùng hiệu ứng 3D).
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            stretch: true,
            backgroundColor: base.withValues(alpha: 0.78),
            foregroundColor: St.fg(),
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: stageOverlay,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: StageIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Quay lại',
                  size: 40,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                    child: FavoriteButton(productId: p.id, size: 22)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh gốc tràn viền, mép dưới tan dần vào nền mờ phía sau.
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.62, 1.0],
                      colors: [Colors.white, Colors.white, Colors.transparent],
                    ).createShader(rect),
                    child: ProductImage(
                      product: p,
                      fit: BoxFit.cover,
                      heroTag: widget.heroTag ?? 'product-${p.id}',
                    ),
                  ),
                  // Phủ nhẹ phía trên để nút quay lại / thanh trạng thái dễ nhìn.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.3],
                          colors: [
                            base.withValues(alpha: 0.5),
                            base.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 28 + 88 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StageChip(label: p.category, color: tint),
                      if (p.isNew)
                        const StageChip(
                            label: 'MỚI', color: Color(0xFF4ADE80)),
                      if (p.isSeasonal)
                        const StageChip(
                            label: 'Theo mùa', color: Color(0xFFFFB020)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.name,
                      style:  TextStyle(
                          color: St.fg(),
                          fontSize: 26,
                          height: 1.15,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      Formatters.money(headlinePrice),
                      key: ValueKey(headlinePrice),
                      style: TextStyle(
                          color: St.tint(tint, 0.45),
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(p.description,
                        style: TextStyle(
                            color: St.fg(0.72),
                            fontSize: 15,
                            height: 1.5)),
                  ],
                  if (p.hasNutrition) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (p.calories != null)
                          StageChip(
                              label: '${p.calories} kcal',
                              icon: Icons.local_fire_department_rounded),
                        for (final t in p.healthTags)
                          StageChip(label: t, icon: Icons.eco_rounded),
                      ],
                    ),
                  ],
                  // Chon size (chi danh muc trai cay)
                  if (_isFruit && _sizeOpts.isNotEmpty)
                    ..._sizeSection(tint),
                  // Topping (ngoai size) — cho moi danh muc
                  if (_nonSizeOpts.isNotEmpty)
                    ..._optionSection(_nonSizeOpts, tint),
                  const SizedBox(height: 22),
                  StageGlass(
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                    child: Row(
                      children: [
                         Text('Số lượng',
                            style: TextStyle(
                                color: St.fg(),
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        _qtyStepper(tint),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ],
      ),
      // Thanh dưới: kính mờ nổi trên nền ảnh, nút thêm phát sáng theo màu món.
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.55),
          border: Border(
              top: BorderSide(color: St.line(0.08))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: StageButton(
              tint: tint,
              icon: inGroup
                  ? Icons.groups_rounded
                  : Icons.add_shopping_cart_rounded,
              label:
                  '${inGroup ? 'Thêm vào phòng' : 'Thêm vào giỏ'} • ${Formatters.money(lineTotal)}',
              onTap: _addToCart,
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String? hint) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title,
                style:  TextStyle(
                    color: St.fg(),
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            if (hint != null) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(hint,
                    style: TextStyle(
                        color: St.fg(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );

  // ── Khu CHỌN SIZE (single-select, size thay giá) ──
  List<Widget> _sizeSection(Color tint) {
    return [
      _sectionTitle('Kích cỡ', 'chọn 1'),
      for (final o in _sizeOpts)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _sizeTile(o, tint),
        ),
    ];
  }

  Widget _sizeTile(ProductOption o, Color tint) {
    final selected = _selectedSizeId == o.id;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: StageGlass(
        onTap: () => setState(() => _selectedSizeId = o.id),
        highlight: selected ? tint : null,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _radioDot(selected, tint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(o.name,
                  style:  TextStyle(
                      color: St.fg(),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            Text(
              Formatters.money(o.price),
              style: TextStyle(
                color: selected
                    ? St.fg()
                    : St.fg(0.75),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioDot(bool on, Color tint) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: on ? St.line(1) : St.line(0.4),
              width: 2),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: on ? 10 : 0,
            height: on ? 10 : 0,
            decoration:  BoxDecoration(
                shape: BoxShape.circle, color: St.solid),
          ),
        ),
      );

  // ── Khu chọn TOPPING (multi-select, cộng dồn) ──
  List<Widget> _optionSection(List<ProductOption> opts, Color tint) {
    final groups = <String, List<ProductOption>>{};
    for (final o in opts) {
      final g = (o.groupName == null || o.groupName!.isEmpty)
          ? 'Tùy chọn thêm'
          : o.groupName!;
      groups.putIfAbsent(g, () => []).add(o);
    }

    final widgets = <Widget>[_sectionTitle('Topping', 'chọn nhiều')];
    var first = true;
    groups.forEach((g, os) {
      if (groups.length > 1 || g != 'Tùy chọn thêm') {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: first ? 0 : 10, bottom: 8, left: 2),
          child: Text(g,
              style: TextStyle(
                  color: St.fg(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ));
      }
      first = false;
      widgets.add(StageGlass(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < os.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 50,
                      color: St.line(0.08)),
                _optionTile(os[i], tint),
              ],
            ],
          ),
        ),
      ));
    });
    return widgets;
  }

  Widget _optionTile(ProductOption o, Color tint) {
    final selected = _selectedIds.contains(o.id);
    return Semantics(
      checked: selected,
      child: InkWell(
        onTap: () => _toggle(o.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: selected ? tint : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? Color.lerp(tint, Colors.white, 0.3)!
                        : St.line(0.4),
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: tint.withValues(alpha: 0.5),
                              blurRadius: 10)
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 16, color: stageOn(tint))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(o.name,
                    style: TextStyle(
                        color: St.fg()
                            .withValues(alpha: selected ? 1 : 0.88),
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
              ),
              Text(
                o.price > 0 ? '+${Formatters.money(o.price)}' : 'Miễn phí',
                style: TextStyle(
                  color: o.price > 0
                      ? St.fg(0.85)
                      : St.fg(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyStepper(Color tint) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(Icons.remove_rounded, 'Giảm số lượng',
            _qty > 1 ? () => setState(() => _qty--) : null, tint),
        SizedBox(
          width: 44,
          child: Text('$_qty',
              textAlign: TextAlign.center,
              style:  TextStyle(
                  color: St.fg(),
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ),
        _stepBtn(Icons.add_rounded, 'Tăng số lượng',
            () => setState(() => _qty++), tint),
      ],
    );
  }

  Widget _stepBtn(
      IconData icon, String label, VoidCallback? onTap, Color tint) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: enabled
            ? St.fill(0.14)
            : St.fill(0.05),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon,
                color: St.fg(enabled ? 1 : 0.35),
                size: 22),
          ),
        ),
      ),
    );
  }
}

/// Nền "ambient": ảnh món phóng to, làm mờ thật mạnh rồi phủ tối (hoặc sáng ở
/// chế độ sáng) để chữ luôn dễ đọc. Màu nền vì vậy luôn lấy từ chính ảnh món.
class _AmbientBackdrop extends StatelessWidget {
  final Product product;
  final Color base;
  const _AmbientBackdrop({required this.product, required this.base});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final dark = AppColors.dark;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: base),
          Transform.scale(
            scale: 1.4,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                  sigmaX: 46, sigmaY: 46, tileMode: TileMode.mirror),
              child: ProductImage(product: product, fit: BoxFit.cover),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        Colors.black.withValues(alpha: 0.38),
                        Colors.black.withValues(alpha: 0.64),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.42),
                        Colors.white.withValues(alpha: 0.72),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
