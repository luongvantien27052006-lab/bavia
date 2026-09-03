// ================================================================
//  FLUTTER APP (package bavia)
//  lib/models/product.dart
//  >> CHEP DE (thay file co san)
// ================================================================

// lib/models/product.dart
//
// Map khớp shape thật của GET /api/products:
//   { id, name, description, category (TÊN danh mục tự do, vd "Cafe","Matcha"),
//     price (int VND), image_url (String?), display_order (int),
//     options: [{ id, name, price (int VND), groupName }] }

import 'json_x.dart';

/// Topping / tùy chọn của 1 món (đồng bộ từ POS).
class ProductOption {
  final String id; // id topping bên POS (chuỗi)
  final String name;
  final int price; // VND, số nguyên (0 = miễn phí)
  final String? groupName;

  const ProductOption({
    required this.id,
    required this.name,
    required this.price,
    this.groupName,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      id: JsonX.str(json, ['id']),
      name: JsonX.str(json, ['name']),
      price: JsonX.intVal(json, ['price']),
      groupName: JsonX.strOrNull(json, ['groupName', 'group_name']),
    );
  }

  /// Gửi lên khi đặt đơn (App tự đối chiếu + lấy giá thật theo id).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        if (groupName != null) 'groupName': groupName,
      };
}

class Product {
  final String id;
  final String name;
  final String description;

  /// Tên danh mục lấy thẳng từ POS (vd "Cafe", "Matcha", "Trà trái cây").
  /// Không ép vào enum cố định nữa — POS thêm danh mục nào, app có danh mục đó.
  final String category;

  final int price; // VND, số nguyên
  final String? imageUrl;
  final int displayOrder;
  final List<ProductOption> options;
  final int? calories; // kcal (null = chưa nhập)
  final List<String> healthTags; // nhãn sức khỏe: Detox, Ít đường...
  final bool isSeasonal; // trái cây theo mùa

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.displayOrder,
    this.options = const [],
    this.calories,
    this.healthTags = const [],
    this.isSeasonal = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: JsonX.str(json, ['id']),
      name: JsonX.str(json, ['name']),
      description: JsonX.str(json, ['description']),
      category: JsonX.str(json, ['category', 'categoryName']),
      price: JsonX.intVal(json, ['price']),
      imageUrl: JsonX.strOrNull(json, ['image_url', 'imageUrl']),
      displayOrder: JsonX.intVal(json, ['display_order', 'displayOrder']),
      options: JsonX.list(json, ['options'])
          .whereType<Map>()
          .map((e) => ProductOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      calories: JsonX.pick(json, ['calories']) is num
          ? JsonX.intVal(json, ['calories'])
          : null,
      healthTags: JsonX.list(json, ['health_tags', 'healthTags'])
          .whereType<String>()
          .toList(),
      isSeasonal: JsonX.boolVal(json, ['is_seasonal', 'isSeasonal']),
    );
  }

  /// Tạm coi các món display_order nhỏ là "hot" cho mục "Món hot hôm nay".
  bool get isHot => displayOrder > 0 && displayOrder <= 5;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasOptions => options.isNotEmpty;

  bool get hasNutrition => calories != null || healthTags.isNotEmpty;
}