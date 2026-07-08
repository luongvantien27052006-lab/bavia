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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/realtime_order_provider.dart';
import '../utils/formatters.dart';
import 'account/account_screen.dart';
import 'cart/cart_screen.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'voucher/voucher_wallet_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  void _goToMenu() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    final cartSubtotal = ref.watch(cartSubtotalProvider);

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

    final tabs = [
      HomeScreen(onBrowseMenu: _goToMenu),
      const MenuScreen(),
      const VoucherWalletScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
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
                backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
      indicatorColor: AppColors.coffee.withOpacity(0.12),
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
    return Badge(
      label: Text('$count'),
      backgroundColor: AppColors.delivery,
      child: icon,
    );
  }
}