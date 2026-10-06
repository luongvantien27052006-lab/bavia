// lib/screens/account/account_screen.dart
//
// >> GIAO DIỆN "SÂN KHẤU TỐI". Tab Tài khoản: thẻ thành viên (bấm mở Hồ sơ),
// số liệu nhanh (điểm, hạng, đơn), các nhóm mục kiểu bảng kính, Đăng xuất.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/membership_rank.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/stage.dart';
import '../../widgets/theme_switcher.dart';
import '../address/address_list_screen.dart';
import '../auth/login_screen.dart';
import '../legal/legal_screen.dart';
import '../loyalty/loyalty_screen.dart';
import '../membership/membership_rank_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';
import '../referral/referral_screen.dart';
import '../support/contact_screen.dart';
import 'checkin_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static final _fmt = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final rank = user != null ? ref.watch(membershipRankProvider).valueOrNull : null;
    final tint = rank?.tier.color ?? const Color(0xFFE0607A);
    final unread = user == null
        ? 0
        : ref.watch(unreadCountProvider).maybeWhen(data: (c) => c, orElse: () => 0);

    void go(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return StageScaffold(
      title: 'Tài khoản',
      tint: tint,
      showBack: false,
      actions: [
        if (user != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              StageIconButton(
                icon: Icons.notifications_rounded,
                tooltip: 'Thông báo',
                onTap: () => go(const NotificationsScreen()),
              ),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6A),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: St.base, width: 2),
                    ),
                    child: Text(unread > 99 ? '99+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: kOnColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
      ],
      body: user == null
          ? _guestView(context, ref)
          : ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
              children: [
                _memberCard(context, ref, user.displayName,
                    Formatters.prettyPhone(user.phone), rank, tint),
                const SizedBox(height: 12),
                _stats(ref, rank, go),
                _group('Ưu đãi & tích luỹ', [
                  _Item(Icons.workspace_premium_rounded, const Color(0xFFCF9B08),
                      'Hạng thành viên', 'Xem hạng & quyền lợi',
                      () => go(const MembershipRankScreen())),
                  _Item(Icons.card_giftcard_rounded, const Color(0xFFE0607A),
                      'Điểm thưởng', 'Số dư & lịch sử điểm',
                      () => go(const LoyaltyScreen())),
                  _Item(Icons.event_available_rounded, const Color(0xFF34C77B),
                      'Điểm danh nhận quà', 'Chuỗi ngày & phần thưởng',
                      () => go(const CheckinScreen())),
                  _Item(Icons.diversity_3_rounded, const Color(0xFF7457E0),
                      'Giới thiệu bạn bè', 'Nhận voucher & điểm khi mời bạn',
                      () => go(const ReferralScreen())),
                ]),
                _group('Đơn hàng & tài khoản', [
                  _Item(Icons.receipt_long_rounded, const Color(0xFFFF8A1F),
                      'Đơn hàng của tôi', 'Theo dõi & xem lại các đơn',
                      () => go(const OrderHistoryScreen())),
                  _Item(Icons.notifications_rounded, const Color(0xFFFF4D6A),
                      'Thông báo', 'Sự kiện, hoàn tiền, nhắc điểm danh',
                      () => go(const NotificationsScreen()),
                      badge: unread),
                  _Item(Icons.location_on_rounded, const Color(0xFF2FB4C9),
                      'Sổ địa chỉ', 'Quản lý địa chỉ giao hàng',
                      () => go(const AddressListScreen())),
                ]),
                _themeSwitch(context, ref),
                _group('Hỗ trợ & chính sách', [
                  _Item(Icons.support_agent_rounded, const Color(0xFF3B82F6),
                      'Liên hệ hỗ trợ', 'Hotline, Zalo, email, địa chỉ quán',
                      () => go(const ContactScreen())),
                  _Item(Icons.privacy_tip_rounded, const Color(0xFF9CA3AF),
                      'Chính sách & điều khoản', 'Điều khoản & quyền riêng tư',
                      () => go(const LegalScreen())),
                ]),
                const SizedBox(height: 22),
                StageGlass(
                  onTap: () => ref.read(authProvider.notifier).logout(),
                  radius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFFF8A9B)),
                      SizedBox(width: 8),
                      Text('Đăng xuất',
                          style: TextStyle(
                              color: Color(0xFFFF8A9B),
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _memberCard(BuildContext context, WidgetRef ref, String name,
      String phone, MembershipRank? rank, Color tint) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    return StageGlass(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
      highlight: tint,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(tint, Colors.white, 0.2)!,
                  Color.lerp(tint, Colors.black, 0.3)!,
                ],
              ),
              border: Border.all(color: St.line(0.5), width: 2),
            ),
            child: Text(initial,
                style: const TextStyle(
                    color: kOnColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                        color: St.fg(),
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(phone,
                    style: TextStyle(color: St.fg(0.7))),
                if (rank != null) ...[
                  const SizedBox(height: 8),
                  StageChip(
                      label: 'Hạng ${rank.tier.label}',
                      icon: rank.tier.icon,
                      color: rank.tier.color),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: St.fg(0.7)),
        ],
      ),
    );
  }

  Widget _stats(WidgetRef ref, MembershipRank? rank, void Function(Widget) go) {
    final points = ref.watch(loyaltyBalanceProvider).valueOrNull?.balance;
    Widget cell(String value, String label, VoidCallback onTap) => Expanded(
          child: StageGlass(
            onTap: onTap,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                        color: St.fg(),
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: St.fg(0.6),
                        fontSize: 12)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        cell(points == null ? '—' : _fmt.format(points), 'Điểm',
            () => go(const LoyaltyScreen())),
        const SizedBox(width: 10),
        cell(rank == null ? '—' : '${rank.completedOrders}', 'Đơn hoàn thành',
            () => go(const OrderHistoryScreen())),
        const SizedBox(width: 10),
        cell(
            rank == null
                ? '—'
                : (rank.isMax ? 'Tối đa' : '${(rank.progress * 100).round()}%'),
            rank == null || rank.isMax ? 'Hạng' : 'Tới hạng kế',
            () => go(const MembershipRankScreen())),
      ],
    );
  }

  Widget _group(String title, List<_Item> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 0, 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  color: St.fg(0.5),
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800)),
        ),
        StageGlass(
          radius: 20,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        indent: 62,
                        color: St.line(0.07)),
                  _row(items[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(_Item it) {
    return InkWell(
      onTap: it.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: it.color.withValues(alpha: 0.22),
              ),
              child: Icon(it.icon,
                  size: 20, color: St.tint(it.color, 0.35)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title,
                      style:  TextStyle(
                          color: St.fg(),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5)),
                  const SizedBox(height: 1),
                  Text(it.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: St.fg(0.55),
                          fontSize: 12)),
                ],
              ),
            ),
            if (it.badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(it.badge > 99 ? '99+' : '${it.badge}',
                    style: const TextStyle(
                        color: kOnColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            Icon(Icons.chevron_right_rounded,
                color: St.fg(0.45)),
          ],
        ),
      ),
    );
  }

  Widget _themeSwitch(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    const c = Color(0xFF7457E0);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: StageGlass(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: c.withValues(alpha: 0.22),
              ),
              child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 20,
                  color: St.tint(c, 0.35)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chế độ tối',
                      style: TextStyle(
                          color: St.fg(),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5)),
                  const SizedBox(height: 1),
                  Text(isDark ? 'Đang bật — nền mận đậm' : 'Đang tắt — nền kem sáng',
                      style: TextStyle(color: St.fg(0.55), fontSize: 12)),
                ],
              ),
            ),
            Switch.adaptive(
              value: isDark,
              activeColor: AppColors.coffee,
              onChanged: (v) => ThemeSwitcher.run(
                context,
                () => ref
                    .read(themeModeProvider.notifier)
                    .setMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: St.fill(0.08),
                border: Border.all(color: St.line(0.14)),
              ),
              child: Icon(Icons.person_outline_rounded,
                  color: St.fg(0.85), size: 42),
            ),
            const SizedBox(height: 18),
             Text('Bạn chưa đăng nhập',
                style: TextStyle(
                    color: St.fg(),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để tích điểm, lên hạng, nhận voucher và theo dõi đơn hàng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: St.fg(0.65), height: 1.45),
            ),
            const SizedBox(height: 24),
            StageButton(
              label: 'Đăng nhập ngay',
              icon: Icons.login_rounded,
              white: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContactScreen()),
              ),
              child: Text('Liên hệ hỗ trợ',
                  style: TextStyle(color: St.fg(0.75))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalScreen()),
              ),
              child: Text('Chính sách & Điều khoản',
                  style: TextStyle(color: St.fg(0.6))),
            ),
            _themeSwitch(context, ref),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  const _Item(this.icon, this.color, this.title, this.subtitle, this.onTap,
      {this.badge = 0});
}
