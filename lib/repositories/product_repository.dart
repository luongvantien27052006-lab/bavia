// ================================================================
//  FLUTTER APP (package bavia)
//  lib/repositories/product_repository.dart
//  >> CHEP DE (thay file co san)
// ================================================================

// lib/repositories/product_repository.dart
//
// Gọi GET /api/products (công khai, phân trang) + GET /api/products/:id.
// Hỗ trợ lọc theo category qua query ?category=<tên danh mục>.

import '../core/network/api_client.dart';
import '../models/paginated.dart';
import '../models/product.dart';

class ProductRepository {
  final ApiClient _api = ApiClient.I;

  /// Danh sách sản phẩm. [category] null = lấy tất cả.
  Future<Paginated<Product>> fetchProducts({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/products',
      query: {
        'limit': limit,
        'offset': offset,
        if (category != null && category.isNotEmpty) 'category': category,
      },
      skipAuth: true, // endpoint công khai, không cần token
    );
    return Paginated<Product>.fromJson(
      Map<String, dynamic>.from(data as Map),
      Product.fromJson,
    );
  }

  Future<Product> fetchProductById(String id) async {
    final data = await _api.get('/products/$id', skipAuth: true);
    // Backend có thể trả thẳng product hoặc bọc trong { product }.
    final map = Map<String, dynamic>.from(data as Map);
    final inner = map['product'] is Map
        ? Map<String, dynamic>.from(map['product'] as Map)
        : map;
    return Product.fromJson(inner);
  }
}