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
import '../product/product_detail_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(availableCategoriesProvider);
    final filtered = ref.watch(filteredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _categoryBar(ref, selected, categories),
          Expanded(
            child: filtered.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(ref, e.toString()),
              data: (list) => _grid(context, list),
            ),
          ),
        ],
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
        backgroundColor: Colors.white,
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

  Widget _grid(BuildContext context, List<Product> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('Chưa có sản phẩm trong nhóm này.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => ProductCard(
        product: list[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: list[i])),
        ),
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
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
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