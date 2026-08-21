// ================================================================
//  FLUTTER APP (package bavia)
//  lib/screens/menu/menu_screen.dart
//  >> CHEP DE (thay file co san)
// ================================================================

// lib/screens/menu/menu_screen.dart
//
// Menu: thanh lọc category + lưới sản phẩm. Lấy data từ menu_provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/anim.dart';
import '../product/product_detail_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(availableCategoriesProvider);
    final filtered = ref.watch(filteredProductsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Menu',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
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
          const _MenuSearchField(),
          _categoryBar(ref, selected, categories),
          Expanded(
            child: filtered.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.66,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                        child: ShimmerBox(
                            width: double.infinity,
                            height: double.infinity,
                            radius: 18)),
                    SizedBox(height: 8),
                    ShimmerBox(height: 13, width: 110),
                    SizedBox(height: 6),
                    ShimmerBox(height: 13, width: 70),
                  ],
                ),
              ),
              error: (e, _) => _errorView(ref, e.toString()),
              data: (list) => _grid(context, ref, list),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBar(
    WidgetRef ref,
    String? selected,
    List<String> categories,
  ) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip(ref, label: 'Tất cả', value: null, selected: selected == null),
          ...categories.map((c) => _chip(ref,
              label: c, value: c, selected: selected == c)),
        ],
      ),
    );
  }

  Widget _chip(
    WidgetRef ref, {
    required String label,
    required String? value,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            ref.read(selectedCategoryProvider.notifier).state = value,
        showCheckmark: false,
        selectedColor: AppColors.coffee,
        backgroundColor: (AppColors.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.55)),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: selected ? AppColors.coffee : const Color(0xFFE5DDD7)),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, WidgetRef ref, List<Product> list) {
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
      child: GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => FadeSlideIn(
        index: i,
        child: ProductCard(
        product: list[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: list[i])),
        ),
      )),
    ));
  }

  Widget _errorView(WidgetRef ref, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _c,
        onChanged: (v) =>
            ref.read(searchQueryProvider.notifier).state = v,
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