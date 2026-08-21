// ============================================================
//  FLUTTER — lib/widgets/star_rating.dart  (MỚI)
//  Hàng 5 sao đánh giá — chạm để chọn. Lưu qua ratingsProvider.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/ratings_provider.dart';
import 'anim.dart';

class StarRating extends ConsumerWidget {
  final String ratingKey;
  final double size;
  const StarRating({super.key, required this.ratingKey, this.size = 28});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(ratingsProvider)[ratingKey] ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(ratingsProvider.notifier).setRating(ratingKey, i);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: PopOnChange(
                value: i <= r,
                child: Icon(
                  i <= r ? Icons.star_rounded : Icons.star_border_rounded,
                  color: i <= r
                      ? const Color(0xFFF5A623)
                      : AppColors.textMuted.withOpacity(0.6),
                  size: size,
                ),
              ),
            ),
          ),
      ],
    );
  }
}