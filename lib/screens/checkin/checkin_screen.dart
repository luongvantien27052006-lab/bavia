// ============================================================
//  FLUTTER — lib/screens/checkin/checkin_screen.dart  (MỚI)
//  Điểm danh hằng ngày nhận điểm/quà (chuỗi 7 ngày).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/checkin_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/anim.dart';

class CheckinScreen extends ConsumerWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(checkinProvider);
    final can = ref.read(checkinProvider.notifier).canCheckInToday;
    final todayIdx =
        st.streak <= 0 ? 0 : (can ? (st.streak % 7) : ((st.streak - 1) % 7));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: const Text('Điểm danh nhận quà',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: GlassBackground(
        child: st.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              blur: 14,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  CountUpText(
                    st.streak,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark),
                  ),
                  Text('ngày liên tiếp',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Phần thưởng 7 ngày',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                for (int i = 0; i < 7; i++) _dayTile(i, todayIdx, can, st),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: can
                  ? () async {
                      HapticFeedback.mediumImpact();
                      final pts =
                          await ref.read(checkinProvider.notifier).checkIn();
                      if (pts != null && context.mounted) {
                        _celebrate(context, pts);
                      }
                    }
                  : null,
              icon: Icon(can
                  ? Icons.check_circle_outline_rounded
                  : Icons.check_circle_rounded),
              label: Text(can ? 'Điểm danh hôm nay' : 'Đã điểm danh hôm nay'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: can ? AppColors.coffee : null,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('Điểm danh mỗi ngày để giữ chuỗi & nhận quà 🎁',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayTile(int i, int todayIdx, bool can, CheckinState st) {
    final doneCount = can
        ? (st.streak % 7)
        : (st.streak == 0 ? 0 : ((st.streak - 1) % 7) + 1);
    final done = i < doneCount;
    final isToday = i == todayIdx && can;
    final isVoucher = i == 6;
    final accent = isVoucher ? AppColors.delivery : AppColors.coffee;
    return Container(
      decoration: BoxDecoration(
        color: done
            ? accent.withOpacity(0.16)
            : (AppColors.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? accent
              : (done ? accent.withOpacity(0.4) : Colors.transparent),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Ngày ${i + 1}',
              style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Icon(
            done
                ? Icons.check_circle_rounded
                : (isVoucher
                    ? Icons.card_giftcard_rounded
                    : Icons.stars_rounded),
            color: done ? accent : accent.withOpacity(0.7),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text('+${kCheckinRewards[i]}đ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }

  void _celebrate(BuildContext context, int points) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          blur: 18,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessCheck(size: 90),
              const SizedBox(height: 8),
              Text('Điểm danh thành công!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text('Bạn nhận được +$points điểm 🎉',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tuyệt vời!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}