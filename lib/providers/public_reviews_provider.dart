// lib/providers/public_reviews_provider.dart
//
// Đánh giá tốt hiển thị trong app (Trang chủ + trang chi tiết món).
// Đánh giá xấu KHÔNG bao giờ về app — server chỉ chuyển chúng sang POS.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/review_model.dart';

Future<PublicReviewPage> _fetch({String? productId, int limit = 10}) async {
  try {
    final data = await ApiClient.I.get('/reviews/public', query: {
      if (productId != null) 'productId': productId,
      'limit': limit,
    });
    if (data is Map) {
      return PublicReviewPage.fromJson(Map<String, dynamic>.from(data));
    }
  } catch (e) {
    debugPrint('Tải đánh giá lỗi: $e');
  }
  // Lỗi mạng -> ẩn khu đánh giá, không làm hỏng màn hình.
  return PublicReviewPage.empty;
}

/// Trang chủ: đánh giá tốt mới nhất của mọi món.
final homeReviewsProvider = FutureProvider.autoDispose<PublicReviewPage>(
    (ref) => _fetch(limit: 12));

/// Trang chi tiết món.
final productReviewsProvider = FutureProvider.autoDispose
    .family<PublicReviewPage, String>((ref, productId) =>
        _fetch(productId: productId, limit: 20));
