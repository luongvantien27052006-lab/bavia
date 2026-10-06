// ============================================================
//  FLUTTER — lib/screens/cart/cart_screen.dart
//  >> GIAO DIỆN "SÂN KHẤU TỐI" (đồng bộ Trang chủ)
//  Giỏ hàng: sửa số lượng từng món, gợi ý món ăn kèm, tạm tính - giảm - tổng.
//  GIỮ NGUYÊN: chặn thanh toán khi quán đóng cửa, chưa đăng nhập -> mở login.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/menu_image.dart';
import '../../widgets/stage.dart';
import '../auth/login_screen.dart';
import '../checkout/checkout_screen.dart';
import '../product/product_detail_screen.dart';

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
    final tint =
        cart.isNotEmpty ? DrinkTint.of(cart.first.product) : DrinkTint.fallback;
    final count = cart.fold<int>(0, (s, c) => s + c.quantity);

    return StageScaffold(
      title: 'Giỏ hàng',
      subtitle: cart.isEmpty ? null : '$count món',
      tint: tint,
      body: cart.isEmpty ? _emptyView() : _content(cart),
      bottomBar: cart.isEmpty ? null : _bottomBar(subtotal, discount, total, tint),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: St.fill(0.08),
                border: Border.all(color: St.line(0.12)),
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 44, color: St.fg(0.8)),
            ),
            const SizedBox(height: 18),
             Text('Giỏ hàng đang trống',
                style: TextStyle(
                    color: St.fg(),
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Thêm vài món ngon để bắt đầu đơn hàng nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(color: St.fg(0.65))),
            const SizedBox(height: 22),
            StageButton(
              label: 'Xem thực đơn',
              icon: Icons.local_cafe_rounded,
              expand: false,
              white: true,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<CartItem> cart) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final item in cart)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _cartTile(item),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 16, color: St.fg(0.55)),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Mã giảm giá & điểm thưởng áp ở bước Thanh toán',
                  style: TextStyle(
                      color: St.fg(0.6),
                      fontSize: 12.5)),
            ),
          ],
        ),
        _suggestions(cart),
      ],
    );
  }

  /// Gợi ý món ăn kèm (tăng giá trị đơn) — món chưa có trong giỏ.
  Widget _suggestions(List<CartItem> cart) {
    final inCart = cart.map((c) => c.product.id).toSet();
    return ref.watch(productsProvider).maybeWhen(
          data: (all) {
            // Ưu tiên gợi ý BÁNH + TRÁI CÂY chấm muối (hợp với đồ uống).
            final avail = all.where((p) => !inCart.contains(p.id)).toList();
            final foods =
                avail.where((p) => isFoodCategory(p.category)).toList();
            final others =
                avail.where((p) => !isFoodCategory(p.category)).toList();
            final sugg = [...foods, ...others].take(8).toList();
            if (sugg.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const StageSectionTitle(title: 'Ăn kèm cho trọn vị'),
                Text('Gợi ý món ngon đi cùng đồ uống',
                    style: TextStyle(
                        color: St.fg(0.6),
                        fontSize: 12.5)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: sugg.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _suggCard(sugg[i]),
                  ),
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }

  Widget _suggCard(Product p) {
    final tint = DrinkTint.of(p);
    return SizedBox(
      width: 136,
      child: StageGlass(
        radius: 20,
        padding: const EdgeInsets.all(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: 100,
                child: MenuImage(
                  url: p.hasImage ? p.imageUrl : null,
                  size: 120,
                  fallback: Container(color: tint.withValues(alpha: 0.2)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                    color: St.fg(),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(Formatters.money(p.price),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: St.fg(0.85),
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                Semantics(
                  button: true,
                  label: 'Thêm ${p.name}',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(cartProvider.notifier).add(p);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Đã thêm ${p.name}'),
                        duration: const Duration(milliseconds: 900),
                      ));
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tint,
                        boxShadow: [
                          BoxShadow(
                              color: tint.withValues(alpha: 0.5),
                              blurRadius: 10)
                        ],
                      ),
                      child: Icon(Icons.add_rounded,
                          color: stageOn(tint), size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartTile(CartItem item) {
    final p = item.product;
    final tint = DrinkTint.of(p);
    return StageGlass(
      radius: 20,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: tint.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MenuImage(
                url: p.hasImage ? p.imageUrl : null,
                size: 68,
                fallback: Container(color: tint.withValues(alpha: 0.2)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                        color: St.fg(),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (item.options.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.optionsLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: St.tint(tint, 0.5),
                          fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(Formatters.money(item.unitPrice * item.quantity),
                    style:  TextStyle(
                        color: St.fg(),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _qtyControls(item),
        ],
      ),
    );
  }

  Widget _qtyControls(CartItem item) {
    final notifier = ref.read(cartProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: St.fill(0.08),
        border: Border.all(color: St.line(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleBtn(
            item.quantity > 1 ? Icons.remove_rounded : Icons.delete_outline_rounded,
            item.quantity > 1 ? 'Giảm' : 'Xoá món',
            () => notifier.decrementLine(item.lineId),
          ),
          SizedBox(
            width: 26,
            child: Text('${item.quantity}',
                textAlign: TextAlign.center,
                style:  TextStyle(
                    color: St.fg(), fontWeight: FontWeight.w800)),
          ),
          _circleBtn(Icons.add_rounded, 'Tăng',
              () => notifier.incrementLine(item.lineId)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: St.fill(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 18, color: St.fg()),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(int subtotal, int discount, int total, Color tint) {
    final open = _storeOpen(ref);
    return Container(
      decoration: BoxDecoration(
        color: St.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
            top: BorderSide(color: St.line(0.10))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryRow('Tạm tính', subtotal),
              if (discount > 0) _summaryRow('Giảm giá', -discount),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                    height: 1, color: St.line(0.10)),
              ),
              _summaryRow('Tổng cộng', total, bold: true),
              const SizedBox(height: 12),
              StageButton(
                tint: tint,
                icon: open ? Icons.arrow_forward_rounded : Icons.storefront_rounded,
                label: open ? 'Thanh toán' : 'Quán đang đóng cửa',
                onTap: !open
                    ? null
                    : () async {
                        // Chưa đăng nhập -> mở màn đăng nhập trước khi thanh toán.
                        if (ref.read(authProvider).user == null) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                          if (!mounted) return;
                          if (ref.read(authProvider).user == null) return;
                        }
                        if (!mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CheckoutScreen()),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _storeOpen(WidgetRef ref) => ref
      .watch(storeStatusProvider)
      .maybeWhen(data: (s) => s.isOpen, orElse: () => true);

  Widget _summaryRow(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 18 : 14,
      color: bold
          ? St.fg()
          : (amount < 0
              ? const Color(0xFF4ADE80)
              : St.fg(0.75)),
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
