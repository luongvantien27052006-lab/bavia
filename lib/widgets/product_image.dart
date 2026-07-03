// ================================================================
//  FLUTTER APP (package bavia)
//  lib/widgets/product_image.dart
//  >> CHEP DE (thay file co san)
// ================================================================

// lib/widgets/product_image.dart
//
// Ảnh sản phẩm: nếu có image_url thì tải (cache); không thì hiện placeholder
// đẹp (icon đoán theo TÊN danh mục + nền nhạt).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (product.hasImage) {
      return CachedNetworkImage(
        imageUrl: product.imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  /// Đoán icon + màu theo tên danh mục (không cần enum cố định).
  (IconData, Color) _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('cà phê') ||
        c.contains('cafe') ||
        c.contains('phê') ||
        c.contains('cacao')) {
      return (Icons.coffee_rounded, AppColors.coffeeDark);
    }
    if (c.contains('matcha')) return (Icons.eco_rounded, AppColors.pickup);
    if (c.contains('trà')) {
      return (Icons.emoji_food_beverage_rounded, AppColors.pickup);
    }
    if (c.contains('sữa chua')) {
      return (Icons.icecream_rounded, AppColors.coffee);
    }
    if (c.contains('sinh tố') || c.contains('nước ép') || c.contains('ép')) {
      return (Icons.local_drink_rounded, AppColors.delivery);
    }
    if (c.contains('bánh')) {
      return (Icons.bakery_dining_rounded, AppColors.coffee);
    }
    if (c.contains('trái cây')) {
      return (Icons.local_florist_rounded, AppColors.success);
    }
    return (Icons.local_cafe_rounded, AppColors.coffee);
  }

  Widget _placeholder() {
    final (icon, tint) = _iconFor(product.category);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withOpacity(0.12),
            tint.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 40, color: tint.withOpacity(0.55)),
      ),
    );
  }
}