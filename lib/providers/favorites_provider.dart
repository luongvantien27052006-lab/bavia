// ============================================================
//  FLUTTER — lib/providers/favorites_provider.dart  (MỚI)
//  Danh sách món yêu thích (lưu máy qua secure_storage).
// ============================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'bavia_favorite_products';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        state = (jsonDecode(raw) as List).map((e) => '$e').toSet();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _storage.write(key: _key, value: jsonEncode(state.toList()));
    } catch (_) {}
  }

  bool isFavorite(String id) => state.contains(id);

  void toggle(String id) {
    final next = {...state};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    _save();
  }
}