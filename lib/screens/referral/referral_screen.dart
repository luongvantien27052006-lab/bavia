// ============================================================
//  FLUTTER
//  lib/screens/referral/referral_screen.dart
//  >> FILE MOI (man Gioi thieu ban be)
// ============================================================

// lib/screens/referral/referral_screen.dart
//
// Giới thiệu bạn bè: mã của tôi (sao chép), số người đã giới thiệu,
// và tiến độ 3 mốc thưởng.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/referral_summary.dart';
import '../../providers/referral_provider.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(referralSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu bạn bè')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          onRetry: () => ref.invalidate(referralSummaryProvider),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(referralSummaryProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _codeCard(context, s.code),
              const SizedBox(height: 18),
              _countCard(s.totalReferrals),
              const SizedBox(height: 18),
              const Text('Mốc thưởng',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Bạn bè nhập mã và đăng nhập trên thiết bị của họ mới được tính.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              ...s.milestones.map((m) => _milestoneCard(m, s.totalReferrals)),
              const SizedBox(height: 8),
              _howItWorks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.coffee, AppColors.coffeeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mã giới thiệu của bạn',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  code.isEmpty ? '—' : code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: code.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã')),
                        );
                      },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: code.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(
                          text:
                              'Tải app Mọng Fruits và nhập mã giới thiệu "$code" '
                              'khi đăng nhập nhé!'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Đã sao chép lời mời, gửi cho bạn bè!')),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Sao chép lời mời'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countCard(int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppColors.coffee, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    const TextStyle(color: AppColors.textDark, fontSize: 15),
                children: [
                  const TextSpan(text: 'Bạn đã giới thiệu thành công\n'),
                  TextSpan(
                    text: '$total người',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.coffee),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneCard(ReferralMilestone m, int total) {
    final progress = (total / m.count).clamp(0.0, 1.0);
    final done = m.claimed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppColors.coffee.withOpacity(0.5)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.coffee
                      : AppColors.coffee.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.emoji_events_rounded,
                  color: done ? Colors.white : AppColors.coffee,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giới thiệu ${m.count} người',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(
                      'Voucher ${m.voucherCode} + ${m.points} điểm',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (done)
                const Text('Đã nhận',
                    style: TextStyle(
                        color: AppColors.coffee,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.cream,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.coffee),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            done ? 'Hoàn thành 🎉' : '${total.clamp(0, m.count)}/${m.count} người',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Cách hoạt động',
              style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          _Step('1', 'Gửi mã của bạn cho bạn bè.'),
          _Step('2', 'Bạn bè nhập mã ở màn đăng nhập trên máy của họ.'),
          _Step('3', 'Đạt mốc 3 / 10 / 20 người để nhận voucher + điểm.'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step(this.n, this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.coffee,
            child: Text(n,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Không tải được thông tin giới thiệu',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}