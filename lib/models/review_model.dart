// lib/models/review_model.dart
//
// Đánh giá CÔNG KHAI (GET /reviews/public): server chỉ trả đánh giá tốt
// (>= 4 sao, có lời nhận xét) và đã ẩn bớt tên / SĐT khách.

import 'json_x.dart';

class PublicReview {
  final String productId;
  final String productName;
  final int stars;
  final String comment;
  final String author; // đã ẩn bớt, vd "Lương V. T***" / "090****567"
  final DateTime? createdAt;

  const PublicReview({
    required this.productId,
    required this.productName,
    required this.stars,
    required this.comment,
    required this.author,
    this.createdAt,
  });

  factory PublicReview.fromJson(Map<String, dynamic> json) => PublicReview(
        productId: JsonX.str(json, ['productId', 'product_id']),
        productName: JsonX.str(json, ['productName', 'product_name']),
        stars: JsonX.intVal(json, ['stars'], fallback: 5).clamp(1, 5),
        comment: JsonX.str(json, ['comment']),
        author: JsonX.str(json, ['author'], fallback: 'Khách Mọng'),
        createdAt: JsonX.dateTime(json, ['createdAt', 'created_at']),
      );
}

class PublicReviewPage {
  /// Tổng lượt khen (>= 4 sao, kể cả chỉ chấm sao không viết).
  final int total;
  final List<PublicReview> items;
  const PublicReviewPage({required this.total, required this.items});

  static const empty = PublicReviewPage(total: 0, items: []);

  factory PublicReviewPage.fromJson(Map<String, dynamic> json) =>
      PublicReviewPage(
        total: JsonX.intVal(json, ['total']),
        items: JsonX.list(json, ['items'])
            .whereType<Map>()
            .map((e) => PublicReview.fromJson(Map<String, dynamic>.from(e)))
            .where((r) => r.comment.trim().isNotEmpty)
            .toList(),
      );
}
