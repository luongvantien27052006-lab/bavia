// ============================================================
//  FLUTTER
//  lib/providers/news_provider.dart
//  >> FILE MOI
// ============================================================

// lib/providers/news_provider.dart
//
// Danh sách tin tức (đã đăng) + vài tin mới nhất cho Trang chủ.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news.dart';
import 'repository_providers.dart';

/// Tải danh sách tin (đã đăng), cache qua FutureProvider.
final newsListProvider = FutureProvider<List<NewsModel>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  final page = await repo.fetchNews(limit: 20);
  return page.items;
});

/// Vài tin mới nhất để hiện ở Trang chủ.
final latestNewsProvider = Provider<AsyncValue<List<NewsModel>>>((ref) {
  return ref.watch(newsListProvider).whenData((l) => l.take(6).toList());
});