// ============================================================
//  FLUTTER — lib/widgets/product_photo.dart  (MỚI)
//  Ảnh món cỡ lớn cho "sân khấu" (kệ xoay Trang chủ, đầu trang chi tiết).
//  Dùng cache đĩa sẵn có + giải mã đúng cỡ hiển thị (nhẹ RAM, không giật).
//  Ảnh PNG tách nền sẽ "nổi" trên nền; ảnh có nền thì hiện như 1 tấm thẻ.
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_image.dart';

class ProductPhoto extends StatelessWidget {
  final Product product;

  /// Bề rộng giải mã (px). 600 đủ nét cho ảnh ~200dp trên màn 3x.
  final int cacheWidth;
  final BoxFit fit;

  const ProductPhoto({
    super.key,
    required this.product,
    this.cacheWidth = 600,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.hasImage) return ProductImage(product: product);
    return Image(
      image: ResizeImage.resizeIfNeeded(
        cacheWidth,
        null,
        CachedNetworkImageProvider(product.imageUrl!),
      ),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSync) {
        if (wasSync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.white.withValues(alpha: 0.08),
        child: Center(
          child: Icon(Icons.local_drink_rounded,
              size: 44, color: Colors.white.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
