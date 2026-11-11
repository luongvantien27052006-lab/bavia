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
/// KHÔNG autoDispose: tải 1 lần khi vào app rồi giữ lại — nếu không, mục đánh
/// giá cuộn ra khỏi màn hình sẽ bị huỷ và tải lại mỗi lần vuốt lên/xuống.
/// Vuốt kéo-làm-mới ở Trang chủ vẫn tải lại (ref.invalidate).
final homeReviewsProvider =
    FutureProvider<PublicReviewPage>((ref) => _fetch(limit: 12));

/// Trang chi tiết món: mỗi món tải 1 lần trong phiên, mở lại món không tải lại.
final productReviewsProvider = FutureProvider.family<PublicReviewPage, String>(
    (ref, productId) => _fetch(productId: productId, limit: 20));
