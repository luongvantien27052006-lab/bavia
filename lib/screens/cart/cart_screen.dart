// ============================================================
//  FLUTTER
//  lib/screens/cart/cart_screen.dart
//  >> CHEP DE (chan dat don: chua dang nhap -> mo login truoc)
// ============================================================

// ==================================================================
//  FLUTTER APP  (package bavia)
//  Dat tai:  lib/screens/cart/cart_screen.dart
//  >> CHEP DE (thay file co san)
// ==================================================================

// lib/screens/cart/cart_screen.dart
//
// Giỏ hàng: sửa số lượng từng món, nhập/áp mã voucher (gọi /vouchers/validate),
// xem tạm tính - giảm - tổng. Nút "Thanh toán" sang màn Checkout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';
import '../checkout/checkout_screen.dart';
import '../auth/login_screen.dart';
import '../../providers/auth_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(checkoutDiscountProvider);
    final total = ref.watch(checkoutTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: cart.isEmpty ? _emptyView() : _content(cart),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _bottomBar(subtotal, discount, total),
    );
  }

  Widget _emptyView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('Giỏ hàng đang trống',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _content(List<CartItem> cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cart.map(_cartTile),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('Mã giảm giá & điểm thưởng áp ở bước Thanh toán',
                style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.9),
                    fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _cartTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(product: item.product),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.options.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.optionsLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.coffee, fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(Formatters.money(item.unitPrice),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          _qtyControls(item),
        ],
      ),
    );
  }

  Widget _qtyControls(CartItem item) {
    final notifier = ref.read(cartProvider.notifier);
    return Row(
      children: [
        _circleBtn(Icons.remove_rounded,
            () => notifier.decrementLine(item.lineId)),
        SizedBox(
          width: 32,
          child: Text('${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        _circleBtn(
            Icons.add_rounded, () => notifier.incrementLine(item.lineId)),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.coffee.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.coffee),
      ),
    );
  }

  Widget _bottomBar(int subtotal, int discount, int total) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Tạm tính', subtotal),
            if (discount > 0) _summaryRow('Giảm giá', -discount),
            const Divider(height: 18),
            _summaryRow('Tổng cộng', total, bold: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Chưa đăng nhập -> mở màn đăng nhập trước khi thanh toán.
                if (ref.read(authProvider).user == null) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (!mounted) return;
                  if (ref.read(authProvider).user == null) return;
                }
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              child: const Text('Thanh toán'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 17 : 14,
      color: bold ? AppColors.coffee : AppColors.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${amount < 0 ? '−' : ''}${Formatters.money(amount.abs())}',
            style: style,
          ),
        ],
      ),
    );
  }
}