// ============================================================
//  FLUTTER — lib/widgets/product_photo.dart  (MỚI)
//  Ảnh món cỡ lớn cho "sân khấu" (kệ xoay Trang chủ, đầu trang chi tiết).
//  Dùng cache đĩa sẵn có + giải mã đúng cỡ hiển thị (nhẹ RAM, không giật).
//  Ảnh PNG tách nền sẽ "nổi" trên nền; ảnh có nền thì hiện như 1 tấm thẻ.
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'stage.dart';

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
      errorBuilder: (_, __, ___) => ColoredBox(
        color: St.fill(0.08),
        child: Center(
          child: Icon(Icons.local_drink_rounded,
              size: 44, color: St.fg(0.6)),
        ),
      ),
    );
  }
}
