// lib/repositories/loyalty_repository.dart
//
// Điểm thưởng. Routes:
//   GET /api/loyalty/balance  → số dư điểm
//   GET /api/loyalty/history  → lịch sử giao dịch điểm
// (App cũ gọi nhầm /loyalty/transactions — route đúng là /history.)

import '../core/network/api_client.dart';
import '../models/loyalty_model.dart';

class LoyaltyRepository {
  final ApiClient _api = ApiClient.I;

  Future<LoyaltyBalance> fetchBalance() async {
    final data = await _api.get('/loyalty/balance');
    final map = Map<String, dynamic>.from(data as Map);
    final inner = map['balance'] is Map
        ? Map<String, dynamic>.from(map['balance'] as Map)
        : map;
    return LoyaltyBalance.fromJson(inner);
  }

  Future<List<LoyaltyTransaction>> fetchHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/loyalty/history',
      query: {'limit': limit, 'offset': offset},
    );

    final List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map &&
        (data['items'] is List || data['transactions'] is List)) {
      rawList = (data['items'] ?? data['transactions']) as List;
    } else {
      rawList = const [];
    }

    return rawList
        .whereType<Map>()
        .map((e) => LoyaltyTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
