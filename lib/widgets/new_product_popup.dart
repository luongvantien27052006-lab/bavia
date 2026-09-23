// lib/widgets/new_product_popup.dart
// Popup "món mới" khi mở app: ảnh + giá, bấm -> tới chi tiết món. Chỉ hiện 1 lần/món.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../models/product.dart';
import '../providers/menu_provider.dart';
import '../utils/formatters.dart';
import '../screens/product/product_detail_screen.dart';

const _kSeenKey = 'seen_new_product_ids';

/// Gọi khi mở app: nếu có món mới khách CHƯA xem -> hiện popup 1 lần.
Future<void> maybeShowNewProductPopup(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final all = await ref.read(productsProvider.future);
    final news = all.where((p) => p.isNew).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    if (news.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_kSeenKey)?.toSet() ?? <String>{};

    final fresh = news.where((p) => !seen.contains(p.id)).toList();
    if (fresh.isEmpty) return;

    final p = fresh.first;
    // Đánh dấu mọi món mới hiện tại là đã hiện (không lặp mỗi lần mở app).
    seen.addAll(news.map((e) => e.id));
    await prefs.setStringList(_kSeenKey, seen.toList());

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _NewProductDialog(product: p, more: fresh.length - 1),
    );
  } catch (_) {
    /* im lặng — không làm phiền khi lỗi */
  }
}

class _NewProductDialog extends StatelessWidget {
  final Product product;
  final int more;
  const _NewProductDialog({required this.product, required this.more});

  void _open(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.dark ? const Color(0xFF201C19) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: p.hasImage
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (_, __, ___) => _imgFallback(),
                            placeholder: (_, __) => _imgFallback(),
                          )
                        : _imgFallback(),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.delivery,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('MÓN MỚI 🎉',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    if (p.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13.5, color: AppColors.textMuted)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(Formatters.money(p.price),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.delivery)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.coffee,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Thử ngay',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    if (more > 0) ...[
                      const SizedBox(height: 10),
                      Text('+ $more món mới khác đang chờ bạn khám phá',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
        color: AppColors.coffee.withOpacity(0.12),
        child: Icon(Icons.local_cafe_rounded,
            size: 56, color: AppColors.coffee.withOpacity(0.5)),
      );
}
