// ==================================================================
//  FLUTTER APP  (package bavia)
//  Dat tai:  lib/providers/cart_provider.dart
//  >> CHEP DE (thay file co san)
// ==================================================================

// lib/providers/cart_provider.dart
//
// Giỏ hàng. Mỗi DÒNG = 1 sản phẩm + tập topping đã chọn + số lượng.
// Cùng món nhưng khác topping => 2 dòng riêng (gộp theo lineId).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  final List<ProductOption> options;

  const CartItem({
    required this.product,
    required this.quantity,
    this.options = const [],
  });

  /// Giá 1 đơn vị = giá món + tổng giá topping.
  int get unitPrice =>
      product.price + options.fold(0, (s, o) => s + o.price);

  int get lineTotal => unitPrice * quantity;

  /// Khoá gộp dòng: cùng món + cùng tập topping = 1 dòng.
  String get lineId {
    final ids = options.map((o) => o.id).toList()..sort();
    return '${product.id}#${ids.join(",")}';
  }

  /// Mô tả topping ngắn để hiển thị (vd: "Trân châu đen, Kem cheese").
  String get optionsLabel => options.map((o) => o.name).join(', ');

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        options: options,
      );
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  int _indexOfLine(String lineId) =>
      state.indexWhere((i) => i.lineId == lineId);

  /// Thêm sản phẩm + topping (gộp nếu trùng cả món lẫn topping).
  void add(
    Product product, {
    int quantity = 1,
    List<ProductOption> options = const [],
  }) {
    final item =
        CartItem(product: product, quantity: quantity, options: options);
    final idx = _indexOfLine(item.lineId);
    if (idx == -1) {
      state = [...state, item];
    } else {
      final updated = [...state];
      updated[idx] =
          updated[idx].copyWith(quantity: updated[idx].quantity + quantity);
      state = updated;
    }
  }

  void incrementLine(String lineId) {
    final idx = _indexOfLine(lineId);
    if (idx == -1) return;
    final updated = [...state];
    updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
    state = updated;
  }

  void decrementLine(String lineId) {
    final idx = _indexOfLine(lineId);
    if (idx == -1) return;
    final current = state[idx].quantity;
    if (current <= 1) {
      removeLine(lineId);
    } else {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(quantity: current - 1);
      state = updated;
    }
  }

  void setQuantityLine(String lineId, int quantity) {
    if (quantity <= 0) {
      removeLine(lineId);
      return;
    }
    final idx = _indexOfLine(lineId);
    if (idx == -1) return;
    final updated = [...state];
    updated[idx] = updated[idx].copyWith(quantity: quantity);
    state = updated;
  }

  void removeLine(String lineId) {
    state = state.where((i) => i.lineId != lineId).toList();
  }

  void clear() => state = const [];

  /// Tổng số lượng của 1 món (cộng dồn mọi dòng topping) — cho badge thẻ món.
  int quantityOf(String productId) => state
      .where((i) => i.product.id == productId)
      .fold(0, (s, i) => s + i.quantity);
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

/// Tổng số món (cho badge giỏ hàng).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity);
});

/// Tạm tính (chưa trừ voucher) — đã gồm giá topping.
final cartSubtotalProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.lineTotal);
});