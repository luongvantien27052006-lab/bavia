// ================================================================
//  FLUTTER APP (package bavia)
//  lib/screens/menu/menu_screen.dart
//  Menu dạng DỌC: sidebar danh mục bên trái + danh sách món 1 cột.
//  Đồ ăn (bánh ăn kèm, trái cây chấm muối) tự xếp CUỐI (isFoodCategory).
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/menu_provider.dart';
import '../../providers/group_order_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/anim.dart';
import '../../utils/formatters.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            const Text('Menu', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (ref.watch(activeGroupProvider) == null)
            IconButton(
              tooltip: 'Đặt chung',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GroupStartScreen()),
              ),
              icon: Icon(Icons.groups_rounded, color: AppColors.coffee),
            ),
          IconButton(
            tooltip: 'Món yêu thích',
            onPressed: () => ref
                .read(showFavoritesOnlyProvider.notifier)
                .state = !ref.read(showFavoritesOnlyProvider),
            icon: Icon(
              ref.watch(showFavoritesOnlyProvider)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: ref.watch(showFavoritesOnlyProvider)
                  ? AppColors.delivery
                  : AppColors.textDark,
            ),
          ),
        ],
      ),
      body: GlassBackground(
        child: Column(
          children: [
            if (ref.watch(activeGroupProvider) != null)
              _GroupBanner(groupId: ref.watch(activeGroupProvider)!),
            const _MenuSearchField(),
            Expanded(
              child: productsAsync.when(
                loading: _loading,
                error: (e, _) => _errorView(ref, e.toString()),
                data: (all) {
                  final searching = query.isNotEmpty;
                  final effective = selected ??
                      (categories.isNotEmpty ? categories.first : null);

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

                  // Danh sách món hiển thị.
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
                        _CategorySidebar(
                          categories: categories,
                          selected: effective,
                          images: catImg,
                          onSelect: (c) => ref
                              .read(selectedCategoryProvider.notifier)
                              .state = c,
                        ),
                      Expanded(
                        child: _productList(
                          context,
                          ref,
                          shown,
                          searching
                              ? 'Kết quả tìm kiếm'
                              : (effective ?? 'Tất cả món'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _productList(
    BuildContext context,
    WidgetRef ref,
    List<Product> list,
    String header,
  ) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.invalidate(productsProvider),
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Center(
              child: Text('Không tìm thấy món phù hợp.',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 28),
        itemCount: list.length + 1,
        separatorBuilder: (_, i) => i == 0
            ? const SizedBox(height: 4)
            : Divider(height: 1, color: AppColors.textMuted.withOpacity(0.12)),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 2),
              child: Text(
                header,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            );
          }
          final p = list[i - 1];
          return FadeSlideIn(
            index: i,
            child: _ProductRow(
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

  Widget _errorView(WidgetRef ref, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(productsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar danh mục dọc bên trái (ảnh tròn + tên, tô đậm mục đang chọn).
class _CategorySidebar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final Map<String, String?> images;
  final ValueChanged<String> onSelect;

  const _CategorySidebar({
    required this.categories,
    required this.selected,
    required this.images,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: AppColors.dark
          ? Colors.white.withOpacity(0.03)
          : Colors.white.withOpacity(0.35),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final c = categories[i];
          final active = c == selected;
          final img = images[c];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(c),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? AppColors.coffee : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: (img != null && img.isNotEmpty)
                            ? Image.network(img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallback())
                            : _fallback(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    c,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? AppColors.coffee : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.coffee.withOpacity(0.12),
        child: Icon(Icons.local_cafe_rounded,
            color: AppColors.coffee.withOpacity(0.6), size: 24),
      );
}

/// Hàng 1 món trong danh sách dọc: ảnh tròn trái + tên/mô tả/giá phải.
class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: 84,
                height: 84,
                child: p.hasImage
                    ? Image.network(p.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgFallback())
                    : _imgFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      p.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    Formatters.money(p.price),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.delivery,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.add_circle_rounded, color: AppColors.coffee, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
        color: AppColors.coffee.withOpacity(0.1),
        child: Icon(Icons.local_cafe_rounded,
            color: AppColors.coffee.withOpacity(0.55), size: 30),
      );
}

/// Ô tìm kiếm món — cập nhật searchQueryProvider (có nút xoá).
class _MenuSearchField extends ConsumerStatefulWidget {
  const _MenuSearchField();
  @override
  ConsumerState<_MenuSearchField> createState() => _MenuSearchFieldState();
}

class _MenuSearchFieldState extends ConsumerState<_MenuSearchField> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    final has = _c.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _c,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm món...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: has
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _c.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.55),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onEditingComplete: () => setState(() {}),
      ),
    );
  }
}

class _GroupBanner extends ConsumerWidget {
  final String groupId;
  const _GroupBanner({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coffee,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Đang thêm món cho phòng đặt chung',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          GestureDetector(
            onTap: () {
              ref.read(activeGroupProvider.notifier).state = null;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => GroupRoomScreen(groupId: groupId)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('Về phòng',
                  style: TextStyle(
                      color: AppColors.coffee,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
