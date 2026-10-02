// lib/widgets/menu_image.dart
// Ảnh món cho menu: cache xuống máy (chỉ tải mạng lần đầu), giải mã ở kích
// thước nhỏ (nhanh + nhẹ RAM), hiện NGAY không hiệu ứng mờ dần.
// Dùng chung 1 "khoá cache" với precacheMenuImages() để ảnh tải trước được
// dùng lại ngay khi mở menu.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/menu_provider.dart';

/// Bề rộng giải mã (px). Đủ nét cho ảnh tròn ~84dp trên màn 3x.
const int kMenuImgCacheWidth = 300;

/// Provider ảnh dùng chung (cùng khoá cache giữa hiển thị và tải trước).
ImageProvider menuImageProvider(String url) => ResizeImage.resizeIfNeeded(
      kMenuImgCacheWidth,
      null,
      CachedNetworkImageProvider(url),
    );

class MenuImage extends StatelessWidget {
  final String? url;
  final double size;
  final Widget fallback;

  const MenuImage({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) {
      return SizedBox(width: size, height: size, child: fallback);
    }
    return Image(
      image: menuImageProvider(u),
      width: size,
      height: size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      // Chưa có khung hình -> hiện icon dự phòng (không để trống), có là hiện ngay.
      frameBuilder: (context, child, frame, wasSync) =>
          (frame == null && !wasSync)
              ? SizedBox(width: size, height: size, child: fallback)
              : child,
      errorBuilder: (_, __, ___) =>
          SizedBox(width: size, height: size, child: fallback),
    );
  }
}

/// Tải trước toàn bộ ảnh menu ngay khi mở app -> vào menu là ảnh có sẵn.
Future<void> precacheMenuImages(BuildContext context, WidgetRef ref) async {
  try {
    final all = await ref.read(productsProvider.future);
    if (!context.mounted) return;
    for (final p in all) {
      if (p.hasImage) {
        precacheImage(
          menuImageProvider(p.imageUrl!),
          context,
          onError: (_, __) {},
        );
      }
    }
  } catch (_) {
    /* im lặng — không ảnh hưởng app */
  }
}
