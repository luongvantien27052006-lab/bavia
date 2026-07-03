// lib/screens/address/address_list_screen.dart
//
// Sổ địa chỉ giao hàng: xem, đặt mặc định, sửa, xoá, thêm mới.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import 'address_form_screen.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ địa chỉ',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coffee,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddressFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm địa chỉ',
            style: TextStyle(color: Colors.white)),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error(ref, e.toString()),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined,
                      size: 72, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Chưa có địa chỉ nào',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (_, i) => _addressCard(context, ref, list[i]),
          );
        },
      ),
    );
  }

  Widget _addressCard(
      BuildContext context, WidgetRef ref, AddressModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: a.isDefault
            ? Border.all(color: AppColors.coffee, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(a.recipientName,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(a.phone,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
              const Spacer(),
              if (a.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.coffee.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Mặc định',
                      style: TextStyle(
                          color: AppColors.coffee,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.detailedAddress,
              style: const TextStyle(color: AppColors.textDark, height: 1.4)),
          const Divider(height: 20),
          Row(
            children: [
              if (!a.isDefault)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(addressControllerProvider.notifier).setDefault(a.id),
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('Đặt mặc định'),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => AddressFormScreen(existing: a)),
                ),
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.coffee, size: 20),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, ref, a),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.delivery, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AddressModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá địa chỉ?'),
        content: Text('Xoá địa chỉ của ${a.recipientName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá',
                style: TextStyle(color: AppColors.delivery)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(addressControllerProvider.notifier).delete(a.id);
    }
  }

  Widget _error(WidgetRef ref, String msg) {
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
              onPressed: () => ref.invalidate(addressesProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
