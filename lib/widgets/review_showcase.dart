// lib/widgets/review_showcase.dart
//
// Hiển thị ĐÁNH GIÁ TỐT của khách (server đã lọc >= 4 sao + ẩn bớt tên/SĐT):
//  - HomeReviewsSection: băng chuyền "Khách nói gì về Mọng" trên Trang chủ.
//  - ProductReviewsSection: khu "Khách khen món này" trong trang chi tiết món.
// Đánh giá xấu không về app — quán xem ở POS (Đánh giá món → Cần xử lý).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/review_model.dart';
import '../providers/menu_provider.dart';
import '../providers/public_reviews_provider.dart';
import 'product_image.dart';
import 'stage.dart';

const _star = Color(0xFFFFB020);

String _ago(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'vừa xong';
  if (d.inMinutes < 60) return '${d.inMinutes} phút trước';
  if (d.inHours < 24) return '${d.inHours} giờ trước';
  if (d.inDays < 7) return '${d.inDays} ngày trước';
  if (d.inDays < 30) return '${d.inDays ~/ 7} tuần trước';
  if (d.inDays < 365) return '${d.inDays ~/ 30} tháng trước';
  return '${d.inDays ~/ 365} năm trước';
}

class _Stars extends StatelessWidget {
  final int stars;
  final double size;
  const _Stars(this.stars, {this.size = 14});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(Icons.star_rounded,
                size: size, color: i < stars ? _star : St.fg(0.18)),
        ],
      );
}

/// Vòng tròn chữ cái đầu của người đánh giá (đã ẩn tên nên chỉ là ký tự đầu).
class _Avatar extends StatelessWidget {
  final String author;
  final Color tint;
  const _Avatar(this.author, this.tint);

  @override
  Widget build(BuildContext context) {
    final ch = author.isEmpty ? 'M' : String.fromCharCode(author.runes.first);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.95), tint.withValues(alpha: 0.6)],
        ),
      ),
      child: Text(ch.toUpperCase(),
          style: TextStyle(
              color: stageOn(tint),
              fontSize: 12,
              fontWeight: FontWeight.w800)),
    );
  }
}

/// Dòng "Tên ẩn · 2 ngày trước" + huy hiệu "Đã mua".
class _AuthorRow extends StatelessWidget {
  final PublicReview r;
  final Color tint;
  const _AuthorRow(this.r, this.tint);

  @override
  Widget build(BuildContext context) {
    final when = _ago(r.createdAt);
    return Row(
      children: [
        _Avatar(r.author, tint),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            when.isEmpty ? r.author : '${r.author} · $when',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: St.fg(0.7), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.verified_rounded, size: 14, color: St.tint(tint, 0.45)),
        const SizedBox(width: 2),
        Text('Đã mua',
            style: TextStyle(
                color: St.tint(tint, 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ───────────────────────── Trang chủ ─────────────────────────

class HomeReviewsSection extends ConsumerWidget {
  final Color tint;
  final void Function(Product product) onOpenProduct;
  const HomeReviewsSection({
    super.key,
    required this.tint,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(homeReviewsProvider).valueOrNull;
    if (page == null || page.items.isEmpty) return const SizedBox.shrink();
    final products = ref.watch(productsProvider).valueOrNull ?? const [];
    Product? find(String id) {
      for (final p in products) {
        if (p.id == id) return p;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khách nói gì về Mọng',
                        style: TextStyle(
                            color: St.fg(),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            size: 13, color: Color(0xFFFF5C7A)),
                        const SizedBox(width: 4),
                        Text('${page.total} lượt khen từ khách đã mua',
                            style: TextStyle(
                                color: St.fg(0.65),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              if (page.items.length > 2)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showReviewsSheet(context,
                      title: 'Khách nói gì về Mọng',
                      page: page,
                      tint: tint,
                      showProduct: true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text('Xem thêm',
                            style: TextStyle(
                                color: St.fg(0.85),
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: St.fg(0.85)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final cardW = (c.maxWidth * 0.8).clamp(240.0, 360.0).toDouble();
          return SizedBox(
            height: 192,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final r = page.items[i];
                final p = find(r.productId);
                return SizedBox(
                  width: cardW,
                  child: _HomeReviewCard(
                    review: r,
                    product: p,
                    tint: tint,
                    onTap: p == null ? null : () => onOpenProduct(p),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _HomeReviewCard extends StatelessWidget {
  final PublicReview review;
  final Product? product;
  final Color tint;
  final VoidCallback? onTap;
  const _HomeReviewCard({
    required this.review,
    required this.product,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = review;
    return StageGlass(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: product != null
                      ? ProductImage(product: product!, width: 40, height: 40)
                      : ColoredBox(
                          color: St.fill(0.15),
                          child: Icon(Icons.local_drink_rounded,
                              size: 20, color: St.fg(0.6)),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? r.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: St.fg(),
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    _Stars(r.stars, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -2,
                  top: -10,
                  child: Text('“',
                      style: TextStyle(
                          color: St.tint(tint, 0.45).withValues(alpha: 0.35),
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w900)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    r.comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: St.fg(0.88), fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _AuthorRow(r, tint),
        ],
      ),
    );
  }
}

// ───────────────────────── Trang chi tiết món ─────────────────────────

class ProductReviewsSection extends ConsumerWidget {
  final String productId;
  final Color tint;
  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.tint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(productReviewsProvider(productId)).valueOrNull;
    // Chưa có đánh giá tốt nào -> không hiện khu này.
    if (page == null || page.items.isEmpty) return const SizedBox.shrink();
    final shown = page.items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Khách khen món này',
                  style: TextStyle(
                      color: St.fg(),
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              StageChip(
                label: '${page.total} lượt khen',
                icon: Icons.favorite_rounded,
                color: tint,
              ),
            ],
          ),
        ),
        for (final r in shown) ...[
          _ReviewTile(review: r, tint: tint),
          const SizedBox(height: 10),
        ],
        if (page.items.length > shown.length)
          Center(
            child: TextButton.icon(
              onPressed: () => showReviewsSheet(context,
                  title: 'Khách khen món này', page: page, tint: tint),
              icon: Icon(Icons.forum_rounded, size: 18, color: St.fg(0.85)),
              label: Text('Xem tất cả ${page.items.length} nhận xét',
                  style: TextStyle(
                      color: St.fg(0.85), fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final PublicReview review;
  final Color tint;
  final bool showProduct;
  const _ReviewTile({
    required this.review,
    required this.tint,
    this.showProduct = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = review;
    return StageGlass(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stars(r.stars, size: 15),
              if (showProduct) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: St.fg(0.8),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(r.comment,
              style: TextStyle(color: St.fg(0.9), fontSize: 14, height: 1.45)),
          const SizedBox(height: 8),
          _AuthorRow(r, tint),
        ],
      ),
    );
  }
}

/// Bảng xem toàn bộ nhận xét tốt.
void showReviewsSheet(
  BuildContext context, {
  required String title,
  required PublicReviewPage page,
  required Color tint,
  bool showProduct = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: St.sheet,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: St.line(0.3), borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: St.fg(),
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                Text('${page.total} lượt khen',
                    style: TextStyle(
                        color: St.fg(0.6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ReviewTile(
                  review: page.items[i], tint: tint, showProduct: showProduct),
            ),
          ),
        ],
      ),
    ),
  );
}
