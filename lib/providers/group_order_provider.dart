// lib/providers/group_order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_order.dart';
import '../repositories/group_order_repository.dart';

final groupOrderRepositoryProvider =
    Provider<GroupOrderRepository>((ref) => GroupOrderRepository());

/// Id phòng đang "thêm món" (khác null = màn Menu/chi tiết sẽ thêm vào phòng
/// thay vì giỏ hàng cá nhân).
final activeGroupProvider = StateProvider<String?>((_) => null);

/// Lấy dữ liệu 1 phòng theo id. Màn phòng sẽ tự invalidate mỗi vài giây để
/// đồng bộ món của các thành viên khác (polling).
final groupRoomProvider =
    FutureProvider.family<GroupOrder, String>((ref, id) async {
  return ref.watch(groupOrderRepositoryProvider).get(id);
});