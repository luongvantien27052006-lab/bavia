// ==================================================================
//  FLUTTER APP  (package bavia)
//  Dat tai:  lib/providers/order_provider.dart
//  >> CHEP DE (thay file co san)
// ==================================================================

// lib/providers/order_provider.dart
//
// Đặt đơn + tải lịch sử/chi tiết đơn. Place order là controller có state
// loading/success/error để màn Checkout phản hồi.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import 'cart_provider.dart';
import 'checkout_provider.dart';
import 'repository_providers.dart';

// Key chống trùng đơn — lưu ở provider KHÔNG auto-dispose để SỐNG SÓT khi
// khách rời màn checkout giữa lúc gửi (tránh tạo đơn TRÙNG khi quay lại đặt).
// Cùng nội dung giỏ + tuỳ chọn -> cùng key -> backend nhận diện & không tạo lại.
final _orderIdemProvider =
    StateProvider<({String key, String sig})?>((ref) => null);

String _orderSig(List<CartItem> cart, CheckoutState c) {
  final items = cart
      .map((i) =>
          '${i.product.id}:${i.quantity}:${i.options.map((o) => o.id).join(",")}')
      .join('|');
  return '$items#${c.paymentMethod}#${c.appliedCode ?? ""}'
      '#${c.shippingCode ?? ""}#${c.pointsToRedeem}';
}

class PlaceOrderController
    extends AutoDisposeNotifier<AsyncValue<PlaceOrderResult?>> {
  @override
  AsyncValue<PlaceOrderResult?> build() => const AsyncData(null);

  // Key chống trùng: giữ nguyên qua các lần thử lại của CÙNG lần đặt;
  // chỉ đổi khi đặt thành công (đơn mới -> key mới).
  String? _idempotencyKey;

  Future<PlaceOrderResult?> placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = AsyncError('Giỏ hàng đang trống', StackTrace.current);
      return null;
    }
    final checkout = ref.read(checkoutProvider);

    state = const AsyncLoading();
    // Sinh/tái dùng key theo nội dung giỏ (cùng giỏ -> cùng key -> chống trùng).
    final sig = _orderSig(cart, checkout);
    final stored = ref.read(_orderIdemProvider);
    if (stored != null && stored.sig == sig) {
      _idempotencyKey = stored.key;
    } else {
      _idempotencyKey =
          'ord-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';
      ref.read(_orderIdemProvider.notifier).state =
          (key: _idempotencyKey!, sig: sig);
    }
    try {
      final result = await ref.read(orderRepositoryProvider).placeOrder(
            items: cart
                .map((i) => (
                      productId: i.product.id,
                      quantity: i.quantity,
                      options: i.options,
                    ))
                .toList(),
            paymentMethod: checkout.paymentMethod,
            voucherCode: checkout.hasVoucher ? checkout.appliedCode : null,
            validationToken: checkout.voucher?.validationToken,
            shippingVoucherCode:
                checkout.hasShippingVoucher ? checkout.shippingCode : null,
            shippingValidationToken:
                checkout.shippingVoucher?.validationToken,
            scheduledFor: checkout.scheduledFor,
            pointsToRedeem:
                checkout.pointsToRedeem > 0 ? checkout.pointsToRedeem : null,
            deliveryAddress:
                checkout.isDelivery && checkout.deliveryAddress != null
                    ? checkout.deliveryAddress!.toDeliveryJson()
                    : null,
            idempotencyKey: _idempotencyKey,
          );
      // Đặt thành công → đổi key (đơn sau dùng key mới) + dọn giỏ + reset voucher.
      _idempotencyKey = null;
      ref.read(_orderIdemProvider.notifier).state = null;
      ref.read(cartProvider.notifier).clear();
      ref.read(checkoutProvider.notifier).reset();
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final placeOrderControllerProvider = AutoDisposeNotifierProvider<
    PlaceOrderController,
    AsyncValue<PlaceOrderResult?>>(PlaceOrderController.new);

/// Lịch sử đơn của khách (Phase 6 dùng).
final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final page = await ref.watch(orderRepositoryProvider).fetchOrders();
  return page.items;
});

/// Chi tiết 1 đơn theo id.
final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderModel, String>((ref, id) async {
  return ref.watch(orderRepositoryProvider).fetchOrderById(id);
});