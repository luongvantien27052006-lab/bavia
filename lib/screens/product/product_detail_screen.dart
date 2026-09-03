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
import '../../providers/group_order_provider.dart';
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
  final _noteCtrl = TextEditingController();
  final Set<String> _selectedIds = {}; // topping (ngoai size)
  String? _selectedSizeId; // size dang chon (chi danh muc trai cay)

  bool get _isFruit => isFruitCategory(widget.product.category);
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

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final selected = <ProductOption>[];
    // Trai cay: kem size da chon vao gio (de tinh gia + validate backend).
    if (_isFruit && _selectedSizeId != null) {
      final size = _sizeOpts.where((o) => o.id == _selectedSizeId);
      if (size.isNotEmpty) selected.add(size.first);
    }
    selected.addAll(_nonSizeOpts.where((o) => _selectedIds.contains(o.id)));

    // Chế độ ĐẶT CHUNG: thêm vào phòng thay vì giỏ cá nhân.
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
              note: _noteCtrl.text,
            );
        if (!mounted) return;
        ref.invalidate(groupRoomProvider(groupId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm $_qty ${widget.product.name} vào phòng'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Thêm vào phòng thất bại'),
              backgroundColor: AppColors.delivery),
        );
      }
      return;
    }

    ref.read(cartProvider.notifier).add(
          widget.product,
          quantity: _qty,
          options: selected,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_qty ${widget.product.name} vào giỏ'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _seasonalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍑', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('Trái cây theo mùa',
              style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _nutritionSection(Product p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Dinh dưỡng',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textDark)),
            ],
          ),
          if (p.calories != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 16, color: AppColors.hot),
                const SizedBox(width: 6),
                Text('${p.calories} kcal',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ],
            ),
          ],
          if (p.healthTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.healthTags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
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
                  if (p.isSeasonal) ...[
                    const SizedBox(height: 14),
                    _seasonalBadge(),
                  ],
                  if (p.hasNutrition) ...[
                    const SizedBox(height: 16),
                    _nutritionSection(p),
                  ],
                  // Chon size (chi danh muc trai cay)
                  if (_isFruit && _sizeOpts.isNotEmpty) ..._sizeSection(),
                  // Topping (ngoai size) — cho moi danh muc
                  if (_nonSizeOpts.isNotEmpty) ..._optionSection(_nonSizeOpts),
                  if (ref.watch(activeGroupProvider) != null) ...[
                    const SizedBox(height: 20),
                    Text('Ghi chú (ít đá, ít đường...)',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLength: 80,
                      decoration: InputDecoration(
                        hintText: 'VD: ít đá, ít ngọt',
                        filled: true,
                        fillColor: AppColors.surface,
                        counterText: '',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ],
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
                Icon(
                    ref.watch(activeGroupProvider) != null
                        ? Icons.group_add_rounded
                        : Icons.shopping_cart_rounded,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                    '${ref.watch(activeGroupProvider) != null ? 'Thêm vào phòng' : 'Thêm vào giỏ'} • ${Formatters.money(lineTotal)}'),
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