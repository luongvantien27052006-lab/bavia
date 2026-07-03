// lib/providers/address_provider.dart
//
// Danh sách địa chỉ + thao tác CRUD. Sau mỗi thay đổi, invalidate
// addressesProvider để UI tự tải lại.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import 'repository_providers.dart';

final addressesProvider =
    FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  return ref.watch(addressRepositoryProvider).fetchAddresses();
});

class AddressController extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> create(AddressModel address) async {
    state = const AsyncLoading();
    try {
      await ref.read(addressRepositoryProvider).createAddress(address);
      ref.invalidate(addressesProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> changes) async {
    state = const AsyncLoading();
    try {
      await ref.read(addressRepositoryProvider).updateAddress(id, changes);
      ref.invalidate(addressesProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> setDefault(String id) async {
    try {
      await ref.read(addressRepositoryProvider).setDefault(id);
      ref.invalidate(addressesProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await ref.read(addressRepositoryProvider).deleteAddress(id);
      ref.invalidate(addressesProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final addressControllerProvider =
    AutoDisposeNotifierProvider<AddressController, AsyncValue<void>>(
        AddressController.new);
