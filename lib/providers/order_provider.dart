// ==================================================================
//  FLUTTER APP  (package bavia)
//  Dat tai:  lib/providers/order_provider.dart
//  >> CHEP DE (thay file co san)
// ==================================================================

// lib/providers/order_provider.dart
//
// Đặt đơn + tải lịch sử/chi tiết đơn. Place order là controller có state
// loading/success/error để màn Checkout phản hồi.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import 'cart_provider.dart';
import 'checkout_provider.dart';
import 'repository_providers.dart';

class PlaceOrderController
    extends AutoDisposeNotifier<AsyncValue<PlaceOrderResult?>> {
  @override
  AsyncValue<PlaceOrderResult?> build() => const AsyncData(null);

  Future<PlaceOrderResult?> placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = AsyncError('Giỏ hàng đang trống', StackTrace.current);
      return null;
    }
    final checkout = ref.read(checkoutProvider);

    state = const AsyncLoading();
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
            pointsToRedeem:
                checkout.pointsToRedeem > 0 ? checkout.pointsToRedeem : null,
            deliveryAddress:
                checkout.isDelivery && checkout.deliveryAddress != null
                    ? checkout.deliveryAddress!.toDeliveryJson()
                    : null,
          );
      // Đặt thành công → dọn giỏ + reset voucher.
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