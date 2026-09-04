// ================================================================
//  FLUTTER APP (package bavia)
//  lib/screens/product/product_detail_screen.dart
//  >> CHEP DE (them chon KICH CO cho danh muc "Trái cây chấm muối":
//     size THAY gia thay vi cong; mac dinh S; kem dinh luong 400/600/800g)
// ================================================================

import 'package:flutter/material.dart';
import '../../widgets/favorite_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/menu_pricing.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';
import '../../widgets/glass_card.dart';

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
  bool get _isFruit => hasSizePricing(widget.product);
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

  void _addToCart() {
    final selected = <ProductOption>[];
    // Trai cay: kem size da chon vao gio (de tinh gia + validate backend).
    if (_isFruit && _selectedSizeId != null) {
      final size = _sizeOpts.where((o) => o.id == _selectedSizeId);
      if (size.isNotEmpty) selected.add(size.first);
    }
    selected.addAll(_nonSizeOpts.where((o) => _selectedIds.contains(o.id)));

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

    return Scaffold(
      backgroundColor:
          AppColors.dark ? const Color(0xFF16110E) : const Color(0xFFDFF3EE),
      body: GlassBackground(
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textDark,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                    child: FavoriteButton(productId: p.id, size: 22)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${p.id}',
                child: ProductImage(product: p, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.coffee.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p.category,
                            style: const TextStyle(
                                color: AppColors.coffee,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(Formatters.money(headlinePrice),
                      style: const TextStyle(
                          color: AppColors.coffee,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(p.description,
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            height: 1.5)),
                  ],
                  // Chon size (chi danh muc trai cay)
                  if (_isFruit && _sizeOpts.isNotEmpty) ..._sizeSection(),
                  // Topping (ngoai size) — cho moi danh muc
                  if (_nonSizeOpts.isNotEmpty) ..._optionSection(_nonSizeOpts),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Số lượng',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      _qtyStepper(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: AppColors.dark
            ? const Color(0xFF16110E)
            : const Color(0xFFDFF3EE),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _addToCart,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_rounded, size: 20),
                const SizedBox(width: 8),
                Text('Thêm vào giỏ • ${Formatters.money(lineTotal)}'),
              ],
            ),
          ),
        ),
      )),
    );
  }

  // ── Khu CHỌN SIZE (single-select, size thay giá) ──
  List<Widget> _sizeSection() {
    return [
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Kích cỡ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('(chọn 1)',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
      for (final o in _sizeOpts) _sizeTile(o),
    ];
  }

  Widget _sizeTile(ProductOption o) {
    final selected = _selectedSizeId == o.id;
    return InkWell(
      onTap: () => setState(() => _selectedSizeId = o.id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected
              ? AppColors.coffee.withOpacity(0.12)
              : (AppColors.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.50)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.coffee : const Color(0xFFE5DDD7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.coffee : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(o.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Text(
              Formatters.money(o.price),
              style: TextStyle(
                color: selected ? AppColors.coffee : AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Khu chọn TOPPING (multi-select, cộng dồn) ──
  List<Widget> _optionSection(List<ProductOption> opts) {
    final groups = <String, List<ProductOption>>{};
    for (final o in opts) {
      final g = (o.groupName == null || o.groupName!.isEmpty)
          ? 'Tùy chọn thêm'
          : o.groupName!;
      groups.putIfAbsent(g, () => []).add(o);
    }

    final widgets = <Widget>[
      const SizedBox(height: 24),
      const Text('Topping',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    ];
    groups.forEach((g, os) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(g,
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ));
      for (final o in os) {
        widgets.add(_optionTile(o));
      }
    });
    return widgets;
  }

  Widget _optionTile(ProductOption o) {
    final selected = _selectedIds.contains(o.id);
    return InkWell(
      onTap: () => _toggle(o.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: selected ? AppColors.coffee : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(o.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Text(
              o.price > 0 ? '+${Formatters.money(o.price)}' : 'Miễn phí',
              style: TextStyle(
                color: o.price > 0 ? AppColors.coffee : AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.dark
                ? Colors.white.withOpacity(0.12)
                : const Color(0xFFE5DDD7)),
      ),
      child: Row(
        children: [
          _stepBtn(Icons.remove_rounded,
              () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1)),
          SizedBox(
            width: 40,
            child: Text('$_qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          _stepBtn(Icons.add_rounded, () => setState(() => _qty++)),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppColors.coffee, size: 22),
      ),
    );
  }
}