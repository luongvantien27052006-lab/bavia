// ============================================================
//  FLUTTER
//  lib/models/referral_summary.dart
//  >> FILE MOI
// ============================================================

// lib/models/referral_summary.dart
import 'json_x.dart';

class ReferralMilestone {
  final int count;
  final int points;
  final String voucherCode;
  final bool reached;
  final bool claimed;

  const ReferralMilestone({
    required this.count,
    required this.points,
    required this.voucherCode,
    required this.reached,
    required this.claimed,
  });

  factory ReferralMilestone.fromJson(Map<String, dynamic> j) =>
      ReferralMilestone(
        count: JsonX.intVal(j, ['count']),
        points: JsonX.intVal(j, ['points']),
        voucherCode: JsonX.str(j, ['voucherCode']),
        reached: JsonX.boolVal(j, ['reached']),
        claimed: JsonX.boolVal(j, ['claimed']),
      );
}

class ReferralSummary {
  final String code;
  final int totalReferrals;
  final List<ReferralMilestone> milestones;

  const ReferralSummary({
    required this.code,
    required this.totalReferrals,
    required this.milestones,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> j) => ReferralSummary(
        code: JsonX.str(j, ['code']),
        totalReferrals: JsonX.intVal(j, ['totalReferrals']),
        milestones: JsonX
            .list(j, ['milestones'])
            .map((e) =>
                ReferralMilestone.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}