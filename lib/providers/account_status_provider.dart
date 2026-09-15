// lib/providers/account_status_provider.dart
//
// Trạng thái tài khoản (khoá/nhắc) — gọi GET /auth/account-status.
// Dùng ở MainShell: khoá -> chặn app + hướng liên hệ hỗ trợ; có "notice" ->
// hiện nhắc nhẹ MỘT lần (server tự xoá notice sau khi trả về).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';

class AccountStatus {
  final bool locked;
  final String? lockReason;
  final String? notice;
  const AccountStatus({this.locked = false, this.lockReason, this.notice});

  factory AccountStatus.fromMap(Map m) => AccountStatus(
        locked: m['locked'] == true,
        lockReason: m['lockReason'] as String?,
        notice: m['notice'] as String?,
      );

  static const empty = AccountStatus();
}

class AccountStatusNotifier extends AsyncNotifier<AccountStatus> {
  @override
  Future<AccountStatus> build() => _fetch();

  Future<AccountStatus> _fetch() async {
    try {
      final raw = await ApiClient.I.get('/auth/account-status');
      final m = (raw is Map && raw['data'] is Map)
          ? raw['data'] as Map
          : (raw as Map);
      return AccountStatus.fromMap(m);
    } catch (_) {
      // Lỗi mạng -> KHÔNG khoá nhầm (fail-open); backend vẫn chặn khi đặt đơn.
      return AccountStatus.empty;
    }
  }

  /// Kiểm tra lại (gọi khi mở lại app / bấm "Thử lại" ở màn khoá).
  Future<void> refresh() async {
    state = AsyncData(await _fetch());
  }
}

final accountStatusProvider =
    AsyncNotifierProvider<AccountStatusNotifier, AccountStatus>(
        AccountStatusNotifier.new);
