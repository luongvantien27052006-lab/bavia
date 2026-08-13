// ================================================================
//  FLUTTER APP (package bavia)
//  lib/core/menu_pricing.dart
//  Hằng số + cách tính giá riêng cho danh mục "Trái cây chấm muối":
//  size (nhóm "Kích cỡ") THAY giá gốc thay vì cộng vào.
//  Các danh mục khác giữ nguyên cách cộng dồn như cũ.
//
//  LƯU Ý: 2 hằng số dưới phải KHỚP với backend (orders.service.ts):
//    FRUIT_CATEGORY = 'Trái cây chấm muối'  ·  SIZE_GROUP = 'Kích cỡ'
// ================================================================

import '../models/product.dart';

/// Tên danh mục dùng cơ chế "size thay giá".
const kFruitCategory = 'Trái cây chấm muối';

/// Tên nhóm option chứa các size (S/M/L) của danh mục trái cây.
const kSizeGroupName = 'Kích cỡ';

bool isFruitCategory(String category) => category.trim() == kFruitCategory;

/// Các option size (nhóm "Kích cỡ") của một món trái cây; rỗng nếu không phải.
List<ProductOption> sizeOptionsOf(Product p) => isFruitCategory(p.category)
    ? p.options.where((o) => o.groupName == kSizeGroupName).toList()
    : const [];

/// Các option KHÔNG phải size (topping thường).
/// Với danh mục khác → trả về toàn bộ options như cũ.
List<ProductOption> nonSizeOptionsOf(Product p) => isFruitCategory(p.category)
    ? p.options.where((o) => o.groupName != kSizeGroupName).toList()
    : p.options;

/// Giá 1 đơn vị cho danh mục trái cây:
///   = giá của size đã chọn (THAY giá gốc) + tổng topping ngoài size.
/// Nếu chưa chọn size → dùng giá gốc (chính là giá size S).
int fruitUnitPrice(Product p, List<ProductOption> selectedOptions) {
  final size = selectedOptions.where((o) => o.groupName == kSizeGroupName);
  final base = size.isNotEmpty ? size.first.price : p.price;
  final extras = selectedOptions
      .where((o) => o.groupName != kSizeGroupName)
      .fold(0, (s, o) => s + o.price);
  return base + extras;
}