// ============================================================
//  FLUTTER
//  lib/models/news.dart
//  >> FILE MOI
// ============================================================

// lib/models/news.dart
//
// Model tin tức, map theo GET /api/news:
//   { id, title, summary, content, image_url, is_published, published_at }

import 'json_x.dart';

class NewsModel {
  final String id;
  final String title;
  final String? summary;
  final String content;
  final String? imageUrl;
  final bool isPublished;
  final DateTime? publishedAt;

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.isPublished,
    required this.publishedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: JsonX.str(json, ['id']),
      title: JsonX.str(json, ['title']),
      summary: JsonX.strOrNull(json, ['summary']),
      content: JsonX.str(json, ['content']),
      imageUrl: JsonX.strOrNull(json, ['image_url', 'imageUrl']),
      isPublished:
          JsonX.boolVal(json, ['is_published', 'isPublished'], fallback: true),
      publishedAt: JsonX.dateTime(
          json, ['published_at', 'publishedAt', 'created_at', 'createdAt']),
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}