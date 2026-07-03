// ============================================================
//  FLUTTER
//  lib/repositories/news_repository.dart
//  >> FILE MOI
// ============================================================

// lib/repositories/news_repository.dart
//
// Gọi GET /api/news (công khai, phân trang) + GET /api/news/:id.

import '../core/network/api_client.dart';
import '../models/news.dart';
import '../models/paginated.dart';

class NewsRepository {
  final ApiClient _api = ApiClient.I;

  Future<Paginated<NewsModel>> fetchNews({int limit = 20, int offset = 0}) async {
    final data = await _api.get(
      '/news',
      query: {'limit': limit, 'offset': offset},
      skipAuth: true, // endpoint công khai
    );
    return Paginated<NewsModel>.fromJson(
      Map<String, dynamic>.from(data as Map),
      NewsModel.fromJson,
    );
  }

  Future<NewsModel> fetchNewsById(String id) async {
    final data = await _api.get('/news/$id', skipAuth: true);
    final map = Map<String, dynamic>.from(data as Map);
    final inner = map['news'] is Map
        ? Map<String, dynamic>.from(map['news'] as Map)
        : map;
    return NewsModel.fromJson(inner);
  }
}