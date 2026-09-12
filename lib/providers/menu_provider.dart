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
import 'favorites_provider.dart';


/// Bỏ dấu tiếng Việt + thường hoá (khớp category dù lưu NFC hay NFD).
String vnNorm(String s) {
  var r = s.toLowerCase().trim();
  // Bỏ dấu tổ hợp (NFD): loại code point 0x300-0x36F.
  final buf = StringBuffer();
  for (final rune in r.runes) {
    if (rune >= 0x300 && rune <= 0x36f) continue;
    buf.writeCharCode(rune);
  }
  r = buf.toString();
  const m = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', 'ă': 'a', 'ằ': 'a',
    'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a', 'â': 'a', 'ầ': 'a', 'ấ': 'a',
    'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a', 'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e',
    'ẹ': 'e', 'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i', 'ò': 'o', 'ó': 'o',
    'ỏ': 'o', 'õ': 'o', 'ọ': 'o', 'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o',
    'ỗ': 'o', 'ộ': 'o', 'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o',
    'ợ': 'o', 'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u', 'ư': 'u',
    'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u', 'ỳ': 'y', 'ý': 'y',
    'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y', 'đ': 'd',
  };
  m.forEach((k, v) => r = r.replaceAll(k, v));
  return r;
}

/// Danh mục ĐỒ ĂN (bánh ăn kèm, trái cây chấm muối) -> xếp CUỐI menu.
bool isFoodCategory(String cat) {
  final n = vnNorm(cat);
  return n.contains('banh') ||
      n.contains('trai cay') ||
      n.contains('cham muoi');
}

/// Tải toàn bộ sản phẩm (1 lần, cache qua FutureProvider).
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final page = await repo.fetchProducts(limit: 500);
  final items = [...page.items]
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return items;
});

/// Category đang chọn ở màn Menu (null = Tất cả). Là TÊN danh mục.
final selectedCategoryProvider = StateProvider<String?>((_) => null);

/// Từ khoá tìm kiếm ở màn Menu.
final searchQueryProvider = StateProvider<String>((_) => '');

/// Chỉ hiện món yêu thích.
final showFavoritesOnlyProvider = StateProvider<bool>((_) => false);

/// Danh sách đã lọc theo category + từ khoá + yêu thích.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final async = ref.watch(productsProvider);
  final selected = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final favOnly = ref.watch(showFavoritesOnlyProvider);
  final favs = ref.watch(favoritesProvider);
  return async.whenData((list) {
    var out = list;
    if (selected != null) {
      out = out.where((p) => p.category == selected).toList();
    }
    if (query.isNotEmpty) {
      out = out
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    }
    if (favOnly) {
      out = out.where((p) => favs.contains(p.id)).toList();
    }
    return out;
  });
});

/// Món hot cho Trang chủ.
final hotProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (list) => list.where((p) => p.isHot).toList(),
      );
});

/// Trái cây theo mùa cho Trang chủ.
final seasonalProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (list) => list.where((p) => p.isSeasonal).toList(),
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
      // Đồ UỐNG lên trên; ĐỒ ĂN (bánh, trái cây chấm muối) xuống CUỐI.
      final drinks = result.where((c) => !isFoodCategory(c)).toList();
      final foods = result.where((c) => isFoodCategory(c)).toList();
      return [...drinks, ...foods];
    },
    orElse: () => const [],
  );
});