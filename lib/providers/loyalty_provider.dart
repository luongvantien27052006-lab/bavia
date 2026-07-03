// lib/providers/loyalty_provider.dart
//
// Số dư điểm + lịch sử giao dịch điểm.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/loyalty_model.dart';
import 'repository_providers.dart';

final loyaltyBalanceProvider =
    FutureProvider.autoDispose<LoyaltyBalance>((ref) async {
  return ref.watch(loyaltyRepositoryProvider).fetchBalance();
});

final loyaltyHistoryProvider =
    FutureProvider.autoDispose<List<LoyaltyTransaction>>((ref) async {
  return ref.watch(loyaltyRepositoryProvider).fetchHistory();
});
