// ============================================================
//  FLUTTER
//  lib/widgets/news_image.dart
//  >> FILE MOI
// ============================================================

// lib/widgets/news_image.dart
//
// Ảnh tin tức theo URL (cache); không có ảnh thì hiện placeholder nhẹ.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class NewsImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  const NewsImage({super.key, required this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.coffee.withOpacity(0.08),
      child: Center(
        child: Icon(Icons.newspaper_rounded,
            size: 34, color: AppColors.coffee.withOpacity(0.5)),
      ),
    );
  }
}