// ================================================================
//  FLUTTER APP (package bavia)
//  lib/screens/product/product_detail_screen.dart
//  >> CHEP DE (thay file co san)
// ================================================================

// lib/screens/product/product_detail_screen.dart
//
// Chi tiết món: ảnh lớn, tên, giá, mô tả, CHỌN TOPPING, số lượng, thêm vào giỏ.
// Topping lấy từ product.options (đồng bộ từ POS). Giá đã cộng topping đã chọn.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  final Set<String> _selectedIds = {};

  int get _toppingTotal => widget.product.options
      .where((o) => _selectedIds.contains(o.id))
      .fold(0, (s, o) => s + o.price);

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
    final selected = widget.product.options
        .where((o) => _selectedIds.contains(o.id))
        .toList();
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
    final lineTotal = (p.price + _toppingTotal) * _qty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
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
                  Text(Formatters.money(p.price),
                      style: const TextStyle(
                          color: AppColors.coffee,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(p.description,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          height: 1.5)),
                  if (p.hasOptions) ..._optionSection(p),
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
      bottomNavigationBar: SafeArea(
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
      ),
    );
  }

  // ── Khu chọn topping (gom nhóm theo groupName) ──
  List<Widget> _optionSection(Product p) {
    final groups = <String, List<ProductOption>>{};
    for (final o in p.options) {
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
    groups.forEach((g, opts) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(g,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ));
      for (final o in opts) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD7)),
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