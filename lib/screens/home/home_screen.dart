// ============================================================
//  FLUTTER — lib/screens/home/home_screen.dart
//  >> CHEP DE — giao diện "kính mờ" (glassmorphism).
//     GIỮ NGUYÊN toàn bộ chức năng: header banner (tin mới / đăng nhập),
//     thông báo đóng cửa, 2 lựa chọn Giao/Tự lấy, Món hot, Tin tức,
//     pull-to-refresh, mọi điều hướng.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/anim.dart';
import '../product/product_detail_screen.dart';
import '../auth/login_screen.dart';
import '../../models/user_model.dart';
import '../../models/news.dart';
import '../../providers/news_provider.dart';
import '../../providers/store_provider.dart';
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
      // Nền gradient kính mờ (tự đổi theo Sáng/Tối) đặt sau toàn bộ nội dung.
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(productsProvider),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(context, ref, user),
              const SizedBox(height: 16),
              _closedNotice(ref),
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
                    Text('🔥 Món hot hôm nay',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
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
      ),
    );
  }

  /// Báo quán đang đóng cửa ngay ở Trang chủ, trước khi khách chọn món.
  Widget _closedNotice(WidgetRef ref) {
    return ref.watch(storeStatusProvider).maybeWhen(
          data: (store) {
            if (store.isOpen) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassCard(
                radius: 16,
                blur: 12,
                padding: const EdgeInsets.all(14),
                tint: AppColors.delivery.withOpacity(0.12),
                borderColor: AppColors.delivery.withOpacity(0.4),
                child: Row(
                  children: [
                    const Icon(Icons.do_not_disturb_on_rounded,
                        color: AppColors.delivery),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quán đang đóng cửa',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.delivery)),
                          const SizedBox(height: 2),
                          Text(store.closedReason,
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text('Giờ mở cửa: ${store.hoursLabel}',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
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
                    // Dải tin mới nhất dạng kính mờ (nối tới Tin tức).
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
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
                          ),
                        ),
                      ),
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
          Expanded(
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
    return GlassCard(
      onTap: onTap,
      radius: 18,
      blur: 14,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.16),
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
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _hotList(BuildContext context, AsyncValue<List<Product>> hot) {
    return hot.when(
      loading: () => SizedBox(
        height: 224,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 138, width: 180, radius: 18),
                SizedBox(height: 8),
                ShimmerBox(height: 14, width: 120),
                SizedBox(height: 6),
                ShimmerBox(height: 14, width: 70),
              ],
            ),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Không tải được món: $e',
            style: TextStyle(color: AppColors.textMuted)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            itemBuilder: (_, i) =>
                FadeSlideIn(index: i, child: _hotCard(context, list[i])),
          ),
        );
      },
    );
  }

  Widget _hotCard(BuildContext context, Product p) {
    // Trong list cuộn dùng blur=0 (nhẹ) — vẫn giữ vẻ kính mờ bằng nền + viền.
    return SizedBox(
      width: 180,
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p)),
        ),
        radius: 18,
        blur: 0,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                  aspectRatio: 1.3, child: ProductImage(product: p)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark)),
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
                  Text('Tin tức',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
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
                itemBuilder: (_, i) =>
                  FadeSlideIn(index: i, child: _newsCard(context, list[i])),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _newsCard(BuildContext context, NewsModel n) {
    return SizedBox(
      width: 260,
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: n)),
        ),
        radius: 18,
        blur: 0,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                  aspectRatio: 16 / 9, child: NewsImage(imageUrl: n.imageUrl)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.25,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(Formatters.date(n.publishedAt),
                      style: TextStyle(
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