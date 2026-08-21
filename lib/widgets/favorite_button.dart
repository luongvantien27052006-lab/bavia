// ============================================================
//  FLUTTER — lib/widgets/favorite_button.dart  (MỚI)
//  Nút tim yêu thích (bật/tắt), có nảy pop. Dùng chung.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/favorites_provider.dart';
import 'anim.dart';

class FavoriteButton extends ConsumerWidget {
  final String productId;
  final double size;
  final bool onImage; // true: nền tròn tối để nổi trên ảnh

  const FavoriteButton({
    super.key,
    required this.productId,
    this.size = 20,
    this.onImage = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider).contains(productId);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(favoritesProvider.notifier).toggle(productId);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(onImage ? 6 : 6),
        decoration: onImage
            ? BoxDecoration(
                color: Colors.black.withOpacity(0.28),
                shape: BoxShape.circle,
              )
            : null,
        child: PopOnChange(
          value: fav,
          child: Icon(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: fav
                ? AppColors.delivery
                : (onImage ? Colors.white : AppColors.textDark),
            size: size,
          ),
        ),
      ),
    );
  }
}