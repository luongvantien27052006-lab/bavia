// ============================================================
//  FLUTTER
//  lib/providers/referral_provider.dart
//  >> FILE MOI
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/referral_summary.dart';

final referralSummaryProvider =
    FutureProvider<ReferralSummary>((ref) async {
  final data = await ApiClient.I.get('/referral/me');
  return ReferralSummary.fromJson(Map<String, dynamic>.from(data as Map));
});