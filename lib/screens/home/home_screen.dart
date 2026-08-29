// ============================================================
//  FLUTTER — lib/screens/home/home_screen.dart
//  >> CHEP DE — giao diện "kính mờ" (glassmorphism).
//     GIỮ NGUYÊN toàn bộ chức năng: header banner (tin mới / đăng nhập),
//     thông báo đóng cửa, 2 lựa chọn Giao/Tự lấy, Món hot, Tin tức,
//     pull-to-refresh, mọi điều hướng.
// ============================================================

import 'package:flutter/material.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../orders/order_detail_screen.dart';
import '../../widgets/delivery_timeline_card.dart';
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
import '../../providers/loyalty_provider.dart';
import '../../models/membership_rank.dart';
import '../membership/membership_rank_screen.dart';
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

    // Đơn đang xử lý (mới nhất) -> hiện timeline giao hàng ở đầu Home.
    OrderModel? activeOrder;
    final ordersAsync = ref.watch(ordersProvider);
    if (ordersAsync.hasValue) {
      for (final o in ordersAsync.value!) {
        if (o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.inProgress ||
            o.status == OrderStatus.ready ||
            o.status == OrderStatus.delivering) {
          activeOrder = o;
          break;
        }
      }
    }

    return Scaffold(
      // Nền gradient kính mờ (tự đổi theo Sáng/Tối) đặt sau toàn bộ nội dung.
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productsProvider);
            ref.invalidate(ordersProvider);
            ref.invalidate(membershipRankProvider);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _topBar(context, ref, user),
              _header(context, ref, user),
              const SizedBox(height: 16),
              if (activeOrder != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DeliveryTimelineCard(
                    order: activeOrder,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: activeOrder!.id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _closedNotice(ref),
              const SizedBox(height: 16),
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng ☀️';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối 🌙';
  }

  Widget _topBar(BuildContext context, WidgetRef ref, UserModel? user) {
    final topPad = MediaQuery.of(context).padding.top;
    final loggedIn = user != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, topPad + 14, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(loggedIn ? user!.displayName : 'Mọng Fruits',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          if (loggedIn) _rankBadge(context, ref),
        ],
      ),
    );
  }

  Widget _rankBadge(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipRankProvider);
    return async.maybeWhen(
      data: (r) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MembershipRankScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: r.tier.tint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: r.tier.color.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(r.tier.icon, color: r.tier.color, size: 16),
              const SizedBox(width: 6),
              Text('Hạng ${r.rankName}',
                  style: TextStyle(
                      color: r.tier.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ],
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, UserModel? user) {
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
        height: 178,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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