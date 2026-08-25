// ============================================================
//  FLUTTER — lib/widgets/product_review_tile.dart  (MỚI)
//  Đánh giá 1 món: số sao + viết nhận xét + gửi backend.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/ratings_provider.dart';
import 'star_rating.dart';

class ProductReviewTile extends ConsumerStatefulWidget {
  final String productId;
  final String productName;
  final String? orderId;
  const ProductReviewTile({
    super.key,
    required this.productId,
    required this.productName,
    this.orderId,
  });

  @override
  ConsumerState<ProductReviewTile> createState() => _ProductReviewTileState();
}

class _ProductReviewTileState extends ConsumerState<ProductReviewTile> {
  final _c = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  bool _expanded = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final stars = ref.read(ratingsProvider.notifier).ratingOf(widget.productId);
    if (stars <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn số sao trước nhé')),
      );
      return;
    }
    setState(() => _sending = true);
    final ok = await ref.read(ratingsProvider.notifier).submitReview(
          widget.productId,
          productName: widget.productName,
          orderId: widget.orderId,
          comment: _c.text,
        );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã gửi đánh giá. Cảm ơn bạn! 🎉'),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.productName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ),
              const SizedBox(width: 8),
              StarRating(ratingKey: widget.productId, size: 24),
            ],
          ),
          if (!_sent) ...[
            const SizedBox(height: 6),
            if (!_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Row(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 15, color: AppColors.coffee),
                    const SizedBox(width: 4),
                    Text('Viết nhận xét',
                        style: TextStyle(
                            color: AppColors.coffee,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else ...[
              const SizedBox(height: 6),
              TextField(
                controller: _c,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(color: AppColors.textDark, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ cảm nhận về món này...',
                  hintStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  counterStyle:
                      TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Gửi đánh giá'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coffee,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('Đã gửi đánh giá',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ),
            ),
          Divider(color: AppColors.textMuted.withOpacity(0.15), height: 20),
        ],
      ),
    );
  }
}