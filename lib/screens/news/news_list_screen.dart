// ============================================================
//  FLUTTER
//  lib/screens/news/news_list_screen.dart
//  >> FILE MOI
// ============================================================

// lib/screens/news/news_list_screen.dart
//
// Màn danh sách tất cả tin đã đăng (mở từ "Xem thêm" ở Trang chủ).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/news.dart';
import '../../providers/news_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/news_image.dart';
import 'news_detail_screen.dart';

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tin tức')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(newsListProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text('Không tải được tin: $e',
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Chưa có tin nào.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _card(context, list[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _card(BuildContext context, NewsModel n) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: n)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
                aspectRatio: 16 / 9, child: NewsImage(imageUrl: n.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.25)),
                  if (n.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(n.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            height: 1.35)),
                  ],
                  const SizedBox(height: 8),
                  Text(Formatters.date(n.publishedAt),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}