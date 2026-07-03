// ============================================================
//  FLUTTER
//  lib/screens/home/home_screen.dart
//  >> CHEP DE (header khach -> Mong Fruits)
// ============================================================

// ============================================================
//  FLUTTER
//  lib/screens/home/home_screen.dart
//  >> CHEP DE (header theo trang thai + Xem them + noi Tin tuc)
// ============================================================

// ============================================================
//  FLUTTER
//  lib/screens/home/home_screen.dart
//  >> CHEP DE (the 'Mon hot' to hon: rong 180, chu lon hon)
// ============================================================

// lib/screens/home/home_screen.dart
//
// Trang chủ: lời chào, 2 lựa chọn Giao hàng / Tự lấy, danh sách Món hot.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';
import '../product/product_detail_screen.dart';
import '../auth/login_screen.dart';
import '../../models/user_model.dart';
import '../../models/news.dart';
import '../../providers/news_provider.dart';
import '../../widgets/news_image.dart';
import '../news/news_list_screen.dart';
import '../news/news_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  /// Cho phép chuyển sang tab Menu từ Trang chủ.
  final VoidCallback onBrowseMenu;
  const HomeScreen({super.key, required this.onBrowseMenu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final hot = ref.watch(hotProductsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productsProvider),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(context, ref, user),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _modeCard(
                      title: 'GIAO HÀNG',
                      subtitle: 'Freeship 0đ',
                      icon: Icons.delivery_dining_rounded,
                      color: AppColors.delivery,
                      onTap: onBrowseMenu,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _modeCard(
                      title: 'TỰ LẤY',
                      subtitle: 'Không xếp hàng',
                      icon: Icons.storefront_rounded,
                      color: AppColors.pickup,
                      onTap: onBrowseMenu,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🔥 Món hot hôm nay',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: onBrowseMenu,
                    child: const Text('Xem thêm',
                        style: TextStyle(
                            color: AppColors.coffee,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _hotList(context, hot),
            const SizedBox(height: 28),
            _newsSection(context, ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, UserModel? user) {
    final topPad = MediaQuery.of(context).padding.top;
    final loggedIn = user != null;
    final latest = ref.watch(latestNewsProvider).maybeWhen(
      data: (l) => l.isNotEmpty ? l.first : null,
      orElse: () => null,
    );

    void openNews() {
      if (latest == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NewsListScreen()),
      );
    }

    return GestureDetector(
      onTap: loggedIn ? openNews : null,
      child: Container(
        height: topPad + 210,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.coffeeDark, AppColors.coffee],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh banner = tin mới nhất (nối tới Tin tức). Không có tin -> giữ nền cam.
            if (latest != null) NewsImage(imageUrl: latest.imageUrl),
            if (latest != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loggedIn
                        ? 'Xin chào, ${user!.displayName} 👋'
                        : 'Mọng Fruits',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600),
                  ),
                  if (loggedIn)
                    Row(
                      children: [
                        const Icon(Icons.campaign_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            latest?.title ?? 'Tin tức & ưu đãi mới',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white70),
                      ],
                    )
                  else
                    _loginPill(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              color: AppColors.coffee, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Đặt món & nhận ưu đãi ngay',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.coffee,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('Đăng nhập',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _hotList(BuildContext context, AsyncValue<List<Product>> hot) {
    return hot.when(
      loading: () => const SizedBox(
        height: 224,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Không tải được món: $e',
            style: const TextStyle(color: AppColors.textMuted)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Chưa có món nổi bật.',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _hotCard(context, list[i]),
          ),
        );
      },
    );
  }

  Widget _hotCard(BuildContext context, Product p) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
                aspectRatio: 1.3, child: ProductImage(product: p)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(Formatters.money(p.price),
                      style: const TextStyle(
                          color: AppColors.coffee,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newsSection(BuildContext context, WidgetRef ref) {
    final async = ref.watch(latestNewsProvider);
    return async.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tin tức',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NewsListScreen()),
                    ),
                    child: const Text('Xem thêm',
                        style: TextStyle(
                            color: AppColors.coffee,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _newsCard(context, list[i]),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _newsCard(BuildContext context, NewsModel n) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NewsDetailScreen(news: n)),
      ),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
                aspectRatio: 16 / 9, child: NewsImage(imageUrl: n.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.25)),
                  const SizedBox(height: 4),
                  Text(Formatters.date(n.publishedAt),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}