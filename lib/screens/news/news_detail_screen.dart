// ============================================================
//  FLUTTER
//  lib/screens/news/news_detail_screen.dart
//  >> FILE MOI
// ============================================================

// lib/screens/news/news_detail_screen.dart
//
// Màn chi tiết 1 tin: ảnh bìa + tiêu đề + ngày + nội dung.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/news.dart';
import '../../utils/formatters.dart';
import '../../widgets/news_image.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;
  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin tức')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (news.hasImage)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: NewsImage(imageUrl: news.imageUrl),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(news.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
                const SizedBox(height: 8),
                Text(Formatters.date(news.publishedAt),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 16),
                if (news.content.isNotEmpty)
                  Text(news.content,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.textDark))
                else if (news.summary != null)
                  Text(news.summary!,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}