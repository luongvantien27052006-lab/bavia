// ============================================================
//  FLUTTER
//  lib/screens/main_shell.dart
//  >> CHEP DE (doi tab Scan -> Voucher)
// ============================================================

// lib/screens/main_shell.dart
//
// Khung chính sau đăng nhập: bottom navigation 4 tab + badge số món trong giỏ
// hiển thị trên tab Menu. Giữ trạng thái từng tab bằng IndexedStack.

import 'package:flutter/material.dart';
import '../services/version_check.dart';
import '../widgets/new_product_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../services/location_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/anim.dart';
import '../providers/realtime_order_provider.dart';
import '../utils/formatters.dart';
import '../providers/account_status_provider.dart';
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
    // Mở app lần đầu -> xin quyền vị trí (để tính phí ship chính xác).
    // (Quyền thông báo đã được PushService xin sẵn.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService.instance.requestPermissionIfNeeded();
      // Kiểm tra phiên bản mới -> gợi ý / bắt buộc cập nhật.
      if (mounted) checkForUpdate(context);
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
        children: tabs,
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
    return Material(
      color: AppColors.coffee,
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
    );
  }

  Widget _navBar(int cartCount) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.coffee.withOpacity(0.18),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.coffee),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: _menuIcon(cartCount, false),
          selectedIcon: _menuIcon(cartCount, true),
          label: 'Menu',
        ),
        const NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number_rounded,
              color: AppColors.coffee),
          label: 'Voucher',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppColors.coffee),
          label: 'Tài khoản',
        ),
      ],
    );
  }

  Widget _menuIcon(int count, bool selected) {
    final icon = Icon(
      selected ? Icons.local_cafe_rounded : Icons.local_cafe_outlined,
      color: selected ? AppColors.coffee : null,
    );
    if (count == 0) return icon;
    return PopOnChange(
      value: count,
      child: Badge(
        label: Text('$count'),
        backgroundColor: AppColors.delivery,
        child: icon,
      ),
    );
  }
}