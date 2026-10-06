// ============================================================
//  FLUTTER — lib/screens/home/home_screen.dart
//  >> GIAO DIỆN MỚI "SÂN KHẤU CỰC QUANG":
//   - Phần đầu (hero) nền cực quang chuyển động, màu ĐỔI THEO món hot đang xem.
//   - Thẻ kính: điểm + hạng (hoặc mời đăng nhập), 2 ô nhanh (Thực đơn / Đặt chung),
//     đơn đang xử lý dạng timeline.
//   - "Món hot hôm nay" = kệ trưng bày xoay 3D (HotCoverflow).
//   - Phía dưới giữ nguyên: thông báo đóng cửa, Sự kiện.
//  GIỮ NGUYÊN chức năng cũ: pull-to-refresh, đăng nhập, hạng thành viên,
//  phòng đặt chung (tạo / vào lại), đơn đang giao, sự kiện, mọi điều hướng.
// ============================================================

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/membership_rank.dart';
import '../../models/order_model.dart';
import '../../models/product.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_order_provider.dart';
import '../../providers/home_tint_provider.dart';
import '../../providers/loyalty_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/anim.dart';
import '../../widgets/aurora_background.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/event_carousel.dart';
import '../../widgets/hot_coverflow.dart';
import '../../widgets/stage.dart';
import '../auth/login_screen.dart';
import '../group/group_room_screen.dart';
import '../group/group_start_screen.dart';
import '../membership/membership_rank_screen.dart';
import '../news/news_detail_screen.dart';
import '../news/news_list_screen.dart';
import '../orders/order_detail_screen.dart';
import '../product/product_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  /// Cho phép chuyển sang tab Menu từ Trang chủ.
  final VoidCallback onBrowseMenu;
  const HomeScreen({super.key, required this.onBrowseMenu});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _heroKey = GlobalKey();

  /// Màu của món hot đang ở giữa kệ -> tô nền cực quang.
  Color _tint = DrinkTint.fallback;

  /// Hero còn trong màn hình (hết thấy thì dừng chuyển động cho nhẹ máy).
  bool _heroVisible = true;

  static final _pointsFmt = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final heroH = _heroKey.currentContext?.size?.height ?? 900;
    final visible = _scroll.offset < heroH;
    if (visible != _heroVisible) setState(() => _heroVisible = visible);
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final hot = ref.watch(hotProductsProvider);

    // Đơn đang xử lý (mới nhất) -> hiện timeline trong phần hero.
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

    // Icon thanh trạng thái theo nền (tối: icon sáng, sáng: icon tối).
    final overlay = stageOverlay;
    final base = DrinkTint.stageBase(_tint);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Nền đổi màu cùng nhịp với cực quang -> phần trên/dưới liền một khối.
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          color: base,
          child: RefreshIndicator(
            color: St.fg(),
            backgroundColor: Color.lerp(base, Colors.white, 0.12),
            edgeOffset: MediaQuery.paddingOf(context).top,
            onRefresh: () async {
              ref.invalidate(productsProvider);
              ref.invalidate(ordersProvider);
              ref.invalidate(membershipRankProvider);
              ref.invalidate(loyaltyBalanceProvider);
              ref.invalidate(activeGroupRoomProvider);
              ref.invalidate(latestNewsProvider);
            },
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              // Chừa chỗ cho thanh điều hướng nổi (Scaffold extendBody).
              padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom),
              children: [
                _hero(context, user, hot, activeOrder),
                const SizedBox(height: 8),
                _eventsSection(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── HERO ─────────────────────────

  Widget _hero(BuildContext context, UserModel? user,
      AsyncValue<List<Product>> hot, OrderModel? activeOrder) {
    final topPad = MediaQuery.paddingOf(context).top;
    return KeyedSubtree(
      key: _heroKey,
      child: AuroraBackground(
        tint: _tint,
        animate: _heroVisible,
        fadeToBase: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(user),
                  _closedNotice(),
                  const SizedBox(height: 16),
                  if (user != null) _pointsCard() else _loginCard(),
                  const SizedBox(height: 12),
                  _quickTiles(),
                  if (activeOrder != null) ...[
                    const SizedBox(height: 12),
                    _orderCard(activeOrder),
                  ],
                  const SizedBox(height: 26),
                  _heroSectionTitle('Món hot hôm nay', widget.onBrowseMenu),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _hotStage(hot),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 14) return 'Chào buổi trưa';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  Widget _topBar(UserModel? user) {
    final loggedIn = user != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                  style: TextStyle(
                      fontSize: 13,
                      color: St.fg(0.75))),
              const SizedBox(height: 2),
              Text(
                user?.displayName ?? 'Mọng Fruits',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: St.fg()),
              ),
            ],
          ),
        ),
        if (loggedIn) _rankChip(),
      ],
    );
  }

  Widget _rankChip() {
    final r = ref.watch(membershipRankProvider).valueOrNull;
    if (r == null) return const SizedBox.shrink();
    return PressEffect(
      onTap: () => _push(const MembershipRankScreen()),
      child: _HeroGlass(
        radius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(r.tier.icon, color: St.fg(), size: 16),
            const SizedBox(width: 6),
            Text('Hạng ${r.rankName}',
                style:  TextStyle(
                    color: St.fg(),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _pointsCard() {
    final rank = ref.watch(membershipRankProvider).valueOrNull;
    final points = ref.watch(loyaltyBalanceProvider).valueOrNull?.balance;
    final progress = (rank?.progress ?? 0.0).clamp(0.0, 1.0);

    return PressEffect(
      onTap: () => _push(const MembershipRankScreen()),
      child: _HeroGlass(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Điểm Mọng',
                    style: TextStyle(
                        color: St.fg(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Quyền lợi',
                    style: TextStyle(
                        color: St.fg(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: St.fg(0.75)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (points == null)
                   Text('—',
                      style: TextStyle(
                          color: St.fg(),
                          fontSize: 34,
                          fontWeight: FontWeight.w800))
                else
                  CountUpText(
                    points,
                    format: _pointsFmt.format,
                    style:  TextStyle(
                      color: St.fg(),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                const SizedBox(width: 6),
                Text('điểm',
                    style: TextStyle(
                        color: St.fg(0.8),
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 6,
                width: double.infinity,
                color: St.fill(0.2),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        color: St.solid,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _rankHint(rank),
              style: TextStyle(
                  color: St.fg(0.85), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  String _rankHint(MembershipRank? r) {
    if (r == null) return 'Tích điểm mỗi đơn để lên hạng & nhận ưu đãi';
    if (r.isMax) return 'Bạn đang ở hạng cao nhất';
    final parts = <String>[
      if (r.ordersToNext > 0) '${r.ordersToNext} đơn',
      if (r.spentToNext > 0) Formatters.money(r.spentToNext),
    ];
    final next = r.nextRankName ?? r.nextTier?.label ?? 'hạng kế tiếp';
    if (parts.isEmpty) return 'Sắp lên hạng $next';
    return 'Còn ${parts.join(' · ')} nữa để lên hạng $next';
  }

  Widget _loginCard() {
    return _HeroGlass(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: St.fill(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child:  Icon(Icons.card_giftcard_rounded, color: St.fg()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('Đăng nhập để tích điểm',
                    style: TextStyle(
                        color: St.fg(),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text('Nhận ưu đãi & theo dõi đơn hàng',
                    style: TextStyle(
                        color: St.fg(0.78),
                        fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _WhitePill(
            label: 'Đăng nhập',
            onTap: () => _push(const LoginScreen()),
          ),
        ],
      ),
    );
  }

  Widget _quickTiles() {
    final room = ref.watch(activeGroupRoomProvider).valueOrNull;
    final Widget groupTile = room != null
        ? _tile(
            icon: Icons.groups_rounded,
            title: 'Phòng đặt chung',
            sub: 'Mã ${room.code} · ${room.totalItems} món',
            badge: true,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GroupRoomScreen(groupId: room.id)));
              ref.invalidate(activeGroupRoomProvider);
            },
          )
        : _tile(
            icon: Icons.groups_rounded,
            title: 'Đặt chung',
            sub: 'Gộp đơn · chia phí ship',
            onTap: () => _push(const GroupStartScreen()),
          );

    return Row(
      children: [
        Expanded(
          child: _tile(
            icon: Icons.local_cafe_rounded,
            title: 'Thực đơn',
            sub: 'Xem tất cả món',
            onTap: widget.onBrowseMenu,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: groupTile),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return PressEffect(
      onTap: onTap,
      child: _HeroGlass(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: St.fill(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: St.fg(), size: 20),
                ),
                if (badge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        border: Border.all(color: St.line(1), width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                          color: St.fg(),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 1),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: St.fg(0.75),
                          fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(OrderModel o) {
    final stage = switch (o.status) {
      OrderStatus.confirmed => 0,
      OrderStatus.inProgress => 1,
      OrderStatus.ready => 2,
      OrderStatus.delivering => 3,
      _ => 0,
    };
    final title = switch (o.status) {
      OrderStatus.confirmed => 'Cửa hàng đã nhận đơn',
      OrderStatus.inProgress => 'Đang pha chế',
      OrderStatus.ready => 'Đơn đã sẵn sàng',
      OrderStatus.delivering => 'Đơn đang giao tới bạn',
      _ => 'Đơn của bạn',
    };
    const labels = ['Nhận đơn', 'Pha chế', 'Sẵn sàng', 'Đang giao'];
    final shortId =
        (o.id.length > 8 ? o.id.substring(0, 8) : o.id).toUpperCase();

    Widget dot(int i) {
      final done = i <= stage;
      final active = i == stage;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? St.solid : St.fill(0.3),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.28),
                      spreadRadius: 4)
                ]
              : null,
        ),
      );
    }

    return PressEffect(
      onTap: () => _push(OrderDetailScreen(orderId: o.id)),
      child: _HeroGlass(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style:  TextStyle(
                          color: St.fg(),
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5)),
                ),
                Text('#$shortId',
                    style: TextStyle(
                        color: St.fg(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: St.fg(0.75)),
              ],
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    dot(i),
                    if (i < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: i < stage
                              ? St.solid
                              : St.fill(0.3),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Text(
                      labels[i],
                      textAlign: i == 0
                          ? TextAlign.left
                          : (i == labels.length - 1
                              ? TextAlign.right
                              : TextAlign.center),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            i == stage ? FontWeight.w800 : FontWeight.w500,
                        color: i <= stage
                            ? St.fg()
                            : St.fg(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroSectionTitle(String title, VoidCallback onMore) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:  TextStyle(
                  color: St.fg(),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2)),
        ),
        GestureDetector(
          onTap: onMore,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text('Xem thêm',
                    style: TextStyle(
                        color: St.fg(0.85),
                        fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: St.fg(0.85)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hotStage(AsyncValue<List<Product>> hot) {
    Widget message(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: St.fg(0.8))),
        );

    return hot.when(
      loading: () =>  SizedBox(
        height: 300,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: St.fg(0.7)),
          ),
        ),
      ),
      error: (e, _) => message('Không tải được món. Kéo xuống để thử lại.'),
      data: (list) {
        if (list.isEmpty) return message('Chưa có món nổi bật.');
        return HotCoverflow(
          products: list.take(8).toList(),
          onFocus: (p) {
            final c = DrinkTint.of(p);
            if (c != _tint) setState(() => _tint = c);
            ref.read(homeTintProvider.notifier).state = c;
          },
          onOpen: (p, tag) =>
              _push(ProductDetailScreen(product: p, heroTag: tag)),
        );
      },
    );
  }

  // ───────────────────── PHẦN DƯỚI ─────────────────────

  /// Báo quán đang đóng cửa ngay đầu Trang chủ, trước khi khách chọn món.
  Widget _closedNotice() {
    return ref.watch(storeStatusProvider).maybeWhen(
          data: (store) {
            if (store.isOpen) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFE23E57).withValues(alpha: 0.22),
                  border: Border.all(
                      color: const Color(0xFFFF8A9B).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        color: Color(0xFFFFB3BE)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Quán đang đóng cửa',
                              style: TextStyle(
                                  color: St.fg(),
                                  fontWeight: FontWeight.w800)),
                          if (store.closedReason.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(store.closedReason,
                                style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        St.fg(0.85))),
                          ],
                          const SizedBox(height: 2),
                          Text('Giờ mở cửa: ${store.hoursLabel}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: St.fg(0.7))),
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

  Widget _eventsSection() {
    return ref.watch(latestNewsProvider).maybeWhen(
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _heroSectionTitle('Sự kiện & ưu đãi',
                      () => _push(const NewsListScreen())),
                ),
                const SizedBox(height: 8),
                EventCarousel(
                  items: list,
                  tint: _tint,
                  onOpen: (n) => _push(NewsDetailScreen(news: n)),
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

/// Thẻ "kính" trên nền cực quang: nền trắng trong + viền sáng + vệt bóng.
/// KHÔNG dùng BackdropFilter (nền phía sau đã mịn nên không cần làm mờ) -> nhẹ.
class _HeroGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _HeroGlass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: St.line(0.24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            St.fill(0.20),
            St.fill(0.08),
          ],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WhitePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: St.solid,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(label,
              style:  TextStyle(
                  color: St.onSolid,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
