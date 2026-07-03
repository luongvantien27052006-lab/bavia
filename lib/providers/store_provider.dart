// ==================================================================
//  FLUTTER — app khach (package bavia)
//  Dat tai:  lib/providers/store_provider.dart
//  >> FILE MOI (tao moi)
// ==================================================================

// lib/providers/store_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_status.dart';
import '../repositories/store_repository.dart';

final storeRepositoryProvider =
    Provider<StoreRepository>((ref) => StoreRepository());

/// Trạng thái mở/đóng cửa. Dùng ref.invalidate(storeStatusProvider) để tải lại.
final storeStatusProvider = FutureProvider<StoreStatus>((ref) async {
  return ref.read(storeRepositoryProvider).getStatus();
});