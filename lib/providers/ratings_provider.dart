// ============================================================
//  FLUTTER — lib/providers/ratings_provider.dart  (MỚI)
//  Đánh giá món (số sao), lưu máy. (Đồng bộ backend sau nếu cần.)
// ============================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final ratingsProvider =
    NotifierProvider<RatingsNotifier, Map<String, int>>(RatingsNotifier.new);

class RatingsNotifier extends Notifier<Map<String, int>> {
  static const _key = 'bavia_product_ratings';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Map<String, int> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        state = (jsonDecode(raw) as Map)
            .map((k, v) => MapEntry('$k', (v as num).toInt()));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _storage.write(key: _key, value: jsonEncode(state));
    } catch (_) {}
  }

  int ratingOf(String key) => state[key] ?? 0;

  void setRating(String key, int stars) {
    state = {...state, key: stars};
    _save();
  }
}