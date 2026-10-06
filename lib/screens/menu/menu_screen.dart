// ================================================================
//  FLUTTER APP (package bavia)
//  lib/screens/menu/menu_screen.dart
//  >> GIAO DIỆN "SÂN KHẤU TỐI" (đồng bộ Trang chủ):
//   - Đầu trang cực quang, màu đổi theo danh mục đang xem.
//   - Ô tìm kiếm kính, thanh danh mục dọc dạng kính bên trái.
//   - Mỗi món là 1 thẻ kính: ảnh có quầng sáng theo màu món, nút + phát sáng.
//  GIỮ NGUYÊN chức năng: tìm kiếm (không dấu), lọc yêu thích, danh mục,
//  đồ ăn xếp cuối khi tìm, chế độ thêm món cho phòng đặt chung, kéo làm mới.
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/group_order_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/anim.dart';
import '../../widgets/drink_tint.dart';
import '../../widgets/menu_image.dart';
import '../../widgets/stage.dart';
import '../group/group_room_screen.dart';
import '../group/group_start_screen.dart';
import '../product/product_detail_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categories = ref.watch(availableCategoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final query = ref.watch(searchQueryProvider).trim();
    final favOnly = ref.watch(showFavoritesOnlyProvider);
    final favs = ref.watch(favoritesProvider);
    final groupId = ref.watch(activeGroupProvider);

    final searching = query.isNotEmpty;
    final effective =
        selected ?? (categories.isNotEmpty ? categories.first : null);

    // Màu đầu trang = màu món đầu tiên của danh mục đang xem.
    Color tint = DrinkTint.fallback;
    final all = productsAsync.valueOrNull ?? const <Product>[];
    if (!searching && effective != null) {
      for (final p in all) {
        if (p.category == effective) {
          tint = DrinkTint.of(p);
          break;
        }
      }
    }

    return StageScaffold(
      title: 'Thực đơn',
      subtitle: groupId != null ? 'Đang thêm món cho phòng đặt chung' : null,
      tint: tint,
      showBack: false,
      actions: [
        if (groupId == null)
          StageIconButton(
            icon: Icons.groups_rounded,
            tooltip: 'Đặt chung',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroupStartScreen()),
            ),
          ),
        StageIconButton(
          icon: favOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          tooltip: favOnly ? 'Hiện tất cả món' : 'Chỉ món yêu thích',
          color: favOnly ? const Color(0xFFFF6B81) : null,
          onTap: () =>
              ref.read(showFavoritesOnlyProvider.notifier).state = !favOnly,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (groupId != null) _GroupBanner(groupId: groupId),
          _MenuSearchField(tint: tint),
          Expanded(
            child: productsAsync.when(
              loading: () =>  Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: St.fg(0.7)),
              ),
              error: (e, _) => _errorView(ref),
              data: (all) {
                // Ảnh đại diện mỗi danh mục = ảnh món đầu tiên có ảnh.
                final catImg = <String, String?>{};
                for (final c in categories) {
                  String? img;
                  for (final p in all) {
                    if (p.category == c && p.hasImage) {
                      img = p.imageUrl;
                      break;
                    }
                  }
                  catImg[c] = img;
                }

                final qn = vnNorm(query);
                List<Product> shown;
                if (searching) {
                  shown =
                      all.where((p) => vnNorm(p.name).contains(qn)).toList();
                  final drinks =
                      shown.where((p) => !isFoodCategory(p.category)).toList();
                  final foods =
                      shown.where((p) => isFoodCategory(p.category)).toList();
                  shown = [...drinks, ...foods];
                } else if (effective != null) {
                  shown = all.where((p) => p.category == effective).toList();
                } else {
                  shown = all;
                }
                if (favOnly) {
                  shown = shown.where((p) => favs.contains(p.id)).toList();
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!searching && categories.length > 1)
                      _CategoryRail(
                        categories: categories,
                        selected: effective,
                        images: catImg,
                        tint: tint,
                        onSelect: (c) =>
                            ref.read(selectedCategoryProvider.notifier).state = c,
                      ),
                    Expanded(
                      child: _productList(
                        context,
                        ref,
                        shown,
                        searching
                            ? 'Kết quả tìm kiếm'
                            : (favOnly
                                ? 'Món yêu thích'
                                : (effective ?? 'Tất cả món')),
                        favOnly,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productList(BuildContext context, WidgetRef ref, List<Product> list,
      String header, bool favOnly) {
    Future<void> refresh() async => ref.invalidate(productsProvider);

    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        color: St.fg(),
        backgroundColor: St.refreshBg,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(
                favOnly
                    ? Icons.favorite_border_rounded
                    : Icons.search_off_rounded,
                size: 48,
                color: St.fg(0.5)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                favOnly
                    ? 'Chưa có món yêu thích ở đây.\nBấm ♡ ở trang món để lưu.'
                    : 'Không tìm thấy món phù hợp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: St.fg(0.7)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      color: St.fg(),
      backgroundColor: St.refreshBg,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            10, 4, 14, 28 + MediaQuery.paddingOf(context).bottom),
        itemCount: list.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      header,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                        color: St.fg(),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('${list.length} món',
                        style: TextStyle(
                            color: St.fg(0.55),
                            fontSize: 12.5)),
                  ),
                ],
              ),
            );
          }
          final p = list[i - 1];
          return FadeSlideIn(
            index: i,
            child: _ProductCard(
              product: p,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: p)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: St.fg(0.5)),
            const SizedBox(height: 12),
            Text('Không tải được thực đơn.\nKiểm tra mạng rồi thử lại.',
                textAlign: TextAlign.center,
                style: TextStyle(color: St.fg(0.75))),
            const SizedBox(height: 16),
            StageButton(
              label: 'Thử lại',
              icon: Icons.refresh_rounded,
              expand: false,
              tint: AppColors.coffee,
              onTap: () => ref.invalidate(productsProvider),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh danh mục dọc (kính): ảnh tròn + tên; mục chọn có vạch sáng + quầng.
class _CategoryRail extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final Map<String, String?> images;
  final Color tint;
  final ValueChanged<String> onSelect;

  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.images,
    required this.tint,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      margin: EdgeInsets.fromLTRB(
          10, 4, 0, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: St.fill(0.05),
        border: Border.all(color: St.line(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final c = categories[i];
            final active = c == selected;
            return Semantics(
              button: true,
              selected: active,
              label: c,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: active
                        ? St.fill(0.12)
                        : Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active
                                ? Color.lerp(tint, Colors.white, 0.25)!
                                : St.line(0.12),
                            width: 2,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                      color: tint.withValues(alpha: 0.55),
                                      blurRadius: 14)
                                ]
                              : null,
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: MenuImage(
                              url: images[c],
                              size: 50,
                              fallback: _fallback(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                          color: active
                              ? St.fg()
                              : St.fg(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: St.fill(0.08),
        child: Icon(Icons.local_cafe_rounded,
            color: St.fg(0.6), size: 22),
      );
}

/// Thẻ kính 1 món: ảnh bo góc có quầng màu món + tên/mô tả/giá + nút thêm.
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final tint = DrinkTint.of(p);
    return Semantics(
      button: true,
      label: '${p.name}, ${Formatters.money(p.price)}',
      child: StageGlass(
        onTap: onTap,
        radius: 22,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: MenuImage(
                  url: p.hasImage ? p.imageUrl : null,
                  size: 84,
                  fallback: Container(
                    color: tint.withValues(alpha: 0.18),
                    child: Icon(Icons.local_drink_rounded,
                        color: St.fg(0.7), size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.isNew || p.isSeasonal)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (p.isNew)
                            const StageChip(
                                label: 'MỚI', color: Color(0xFF4ADE80)),
                          if (p.isSeasonal)
                            const StageChip(
                                label: 'Theo mùa', color: Color(0xFFFFB020)),
                        ],
                      ),
                    ),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                      color: St.fg(),
                      fontSize: 15.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      p.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: St.fg(0.6)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    Formatters.money(p.price),
                    style:  TextStyle(
                      color: St.fg(),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(tint, Colors.white, 0.10)!,
                    Color.lerp(tint, Colors.black, 0.22)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(color: tint.withValues(alpha: 0.45), blurRadius: 12),
                ],
              ),
              child: Icon(Icons.add_rounded, color: stageOn(tint), size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô tìm kiếm kính — cập nhật searchQueryProvider (có nút xoá).
class _MenuSearchField extends ConsumerStatefulWidget {
  final Color tint;
  const _MenuSearchField({required this.tint});

  @override
  ConsumerState<_MenuSearchField> createState() => _MenuSearchFieldState();
}

class _MenuSearchFieldState extends ConsumerState<_MenuSearchField> {
  final _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    final has = _c.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: TextField(
        controller: _c,
        onChanged: (v) {
          ref.read(searchQueryProvider.notifier).state = v;
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        cursorColor: St.fg(),
        style:  TextStyle(color: St.fg(), fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Tìm món: dâu, xoài, matcha...',
          hintStyle: TextStyle(color: St.fg(0.5)),
          prefixIcon: Icon(Icons.search_rounded,
              color: St.fg(0.75)),
          suffixIcon: has
              ? IconButton(
                  tooltip: 'Xoá',
                  icon: Icon(Icons.close_rounded,
                      color: St.fg(0.8)),
                  onPressed: () {
                    _c.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: St.fill(0.10),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: _border(St.line(0.14)),
          enabledBorder: _border(St.line(0.14)),
          focusedBorder:
              _border(Color.lerp(widget.tint, Colors.white, 0.3)!, 1.6),
        ),
      ),
    );
  }
}

class _GroupBanner extends ConsumerWidget {
  final String groupId;
  const _GroupBanner({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: StageGlass(
        highlight: const Color(0xFF4ADE80),
        radius: 18,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
             Icon(Icons.groups_rounded, color: St.fg(), size: 20),
            const SizedBox(width: 8),
             Expanded(
              child: Text('Món chọn sẽ vào phòng đặt chung',
                  style: TextStyle(
                      color: St.fg(),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            Material(
              color: St.solid,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  ref.read(activeGroupProvider.notifier).state = null;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => GroupRoomScreen(groupId: groupId)),
                  );
                },
                child:  Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text('Về phòng',
                      style: TextStyle(
                          color: St.onSolid,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
