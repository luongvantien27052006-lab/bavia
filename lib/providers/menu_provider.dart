// ================================================================
//  FLUTTER APP (package bavia)
//  lib/providers/menu_provider.dart
//  >> CHEP DE (thay file co san)
// ================================================================

// lib/providers/menu_provider.dart
//
// Cung cấp danh sách sản phẩm + lọc theo category (tên danh mục từ POS).
// Vì menu nhỏ (vài chục món), load 1 lần rồi lọc phía client cho mượt.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'repository_providers.dart';

/// Tải toàn bộ sản phẩm (1 lần, cache qua FutureProvider).
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final page = await repo.fetchProducts(limit: 100);
  final items = [...page.items]
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return items;
});

/// Category đang chọn ở màn Menu (null = Tất cả). Là TÊN danh mục.
final selectedCategoryProvider = StateProvider<String?>((_) => null);

/// Danh sách đã lọc theo category đang chọn.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final async = ref.watch(productsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  return async.whenData((list) {
    if (selected == null) return list;
    return list.where((p) => p.category == selected).toList();
  });
});

/// Món hot cho Trang chủ.
final hotProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (list) => list.where((p) => p.isHot).toList(),
      );
});

/// Các danh mục thực sự có sản phẩm (dựng tab động, theo thứ tự display_order).
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final async = ref.watch(productsProvider);
  return async.maybeWhen(
    data: (list) {
      final seen = <String>{};
      final result = <String>[];
      for (final p in list) {
        if (p.category.isNotEmpty && seen.add(p.category)) {
          result.add(p.category);
        }
      }
      return result;
    },
    orElse: () => const [],
  );
});