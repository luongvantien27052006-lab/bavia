// ============================================================
//  FLUTTER
//  lib/screens/main_shell.dart
//  >> CHEP DE (doi tab Scan -> Voucher)
// ============================================================

// lib/screens/main_shell.dart
//
// Khung chính sau đăng nhập: bottom navigation 4 tab + badge số món trong giỏ
// hiển thị trên tab Menu. Giữ trạng thái từng tab bằng IndexedStack.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/version_check.dart';
import '../widgets/new_product_popup.dart';
import '../widgets/menu_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../services/location_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/anim.dart';
import '../providers/realtime_order_provider.dart';
import '../utils/formatters.dart';
import '../providers/account_status_provider.dart';
import '../providers/order_provider.dart';
import '../services/order_live_activity.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'support/contact_screen.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'voucher/voucher_wallet_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Danh sách đơn tải lại (mở app / realtime / kéo làm mới) -> đồng bộ
    // timeline đơn trên Dynamic Island (iOS) / Live Update (Android).
    ref.listenManual(ordersProvider, (_, next) {
      final list = next.valueOrNull;
      if (list != null) OrderLiveActivity.instance.syncOrders(list);
    }, fireImmediately: true);
    // Mở app lần đầu -> xin quyền vị trí (để tính phí ship chính xác).
    // (Quyền thông báo đã được PushService xin sẵn.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.instance.requestPermissionIfNeeded();
      // Kiểm tra phiên bản mới -> gợi ý / bắt buộc cập nhật.
      if (mounted) checkForUpdate(context);
      // Tải trước ảnh menu (chạy nền) -> vào tab Menu là ảnh hiện ngay.
      if (mounted) precacheMenuImages(context, ref);
      // Sau đó: có món mới chưa xem -> popup (bỏ qua nếu đang có dialog khác).
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
          maybeShowNewProductPopup(context, ref);
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mở lại app -> kiểm tra lại trạng thái tài khoản (khoá/nhắc).
    if (state == AppLifecycleState.resumed) {
      ref.read(accountStatusProvider.notifier).refresh();
      // Đơn có thể đã đổi trạng thái khi app ở nền -> tải lại để timeline khớp.
      ref.invalidate(ordersProvider);
    }
  }

  void _showNotice(String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.info_outline_rounded, color: AppColors.delivery),
        title: const Text('Nhắc nhở'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _lockedView(String? reason) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 72, color: AppColors.delivery),
              const SizedBox(height: 20),
              Text('Tài khoản tạm khoá',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 12),
              Text(
                reason ??
                    'Tài khoản của bạn đang tạm khoá đặt đơn. Vui lòng liên hệ '
                        'bộ phận hỗ trợ để được giải quyết.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14.5, height: 1.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContactScreen()),
                  ),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Liên hệ hỗ trợ'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    ref.read(accountStatusProvider.notifier).refresh(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToMenu() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    final cartSubtotal = ref.watch(cartSubtotalProvider);
    // Theo dõi chế độ Sáng/Tối: đổi -> key IndexedStack đổi -> các tab rebuild
    // đồng loạt sang màu mới (không cần chạm từng thẻ).
    final themeMode = ref.watch(themeModeProvider);

    // Giữ provider realtime sống suốt phiên đăng nhập.
    ref.watch(realtimeOrderProvider);
    // Hiện thông báo khi có cập nhật đơn realtime.
    ref.listen(realtimeOrderProvider, (prev, next) {
      if (next == null || next == prev) return;
      final color = switch (next.kind) {
        'paid' => AppColors.success,
        'cancelled' || 'expired' => AppColors.delivery,
        _ => AppColors.coffee,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 4),
          ),
        );
    });

    // Trạng thái tài khoản: khoá -> chặn app; có nhắc -> hiện MỘT lần.
    final acct = ref.watch(accountStatusProvider).valueOrNull;
    ref.listen(accountStatusProvider, (prev, next) {
      final s = next.valueOrNull;
      if (s != null && !s.locked && (s.notice?.isNotEmpty ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNotice(s.notice!);
        });
      }
    });
    if (acct != null && acct.locked) {
      return _lockedView(acct.lockReason);
    }

    final tabs = [
      HomeScreen(onBrowseMenu: _goToMenu),
      const MenuScreen(),
      const VoucherWalletScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        key: ValueKey(themeMode),
        index: _index,
        // Tab đang ẩn thì dừng mọi chuyển động (nền cực quang, kệ xoay...) cho nhẹ máy.
        children: [
          for (var i = 0; i < tabs.length; i++)
            TickerMode(enabled: i == _index, child: tabs[i]),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cartCount > 0) _cartBar(context, cartCount, cartSubtotal),
          _navBar(cartCount),
        ],
      ),
    );
  }

  Widget _cartBar(BuildContext context, int count, int subtotal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Material(
      color: AppColors.coffee,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Badge(
                label: Text('$count'),
                backgroundColor: AppColors.surface,
                textColor: AppColors.coffee,
                child: const Icon(Icons.shopping_cart_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 14),
              Text('Xem giỏ hàng',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(Formatters.money(subtotal),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
      ),
    );
  }

  static const _navItems = <({IconData icon, IconData active, String label})>[
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Trang chủ'),
    (
      icon: Icons.local_cafe_outlined,
      active: Icons.local_cafe_rounded,
      label: 'Menu'
    ),
    (
      icon: Icons.confirmation_number_outlined,
      active: Icons.confirmation_number_rounded,
      label: 'Voucher'
    ),
    (
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
      label: 'Tài khoản'
    ),
  ];

  /// Thanh điều hướng nổi: bo tròn, nền kính mờ, mục đang chọn có nền gradient.
  Widget _navBar(int cartCount) {
    final dark = AppColors.dark;
    final radius = BorderRadius.circular(32);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.35 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: dark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.80),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white.withOpacity(0.9),
                  ),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < _navItems.length; i++)
                      Expanded(child: _navItem(i, cartCount)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, int cartCount) {
    final item = _navItems[i];
    final sel = _index == i;
    final color = sel ? AppColors.coffee : AppColors.textMuted;

    Widget icon = Icon(sel ? item.active : item.icon, size: 24, color: color);
    if (i == 1 && cartCount > 0) {
      icon = PopOnChange(
        value: cartCount,
        child: Badge(
          label: Text('$cartCount'),
          backgroundColor: AppColors.delivery,
          child: icon,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_index == i) return;
        HapticFeedback.selectionClick();
        setState(() => _index = i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: sel
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.coffee.withOpacity(0.20),
                    AppColors.coffee.withOpacity(0.07),
                  ],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}