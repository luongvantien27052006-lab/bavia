// ============================================================
//  FLUTTER
//  lib/providers/voucher_wallet_provider.dart
//  >> FILE MOI
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voucher_wallet.dart';
import '../repositories/voucher_repository.dart';

final availableVouchersProvider =
    FutureProvider<List<VoucherWallet>>((ref) async {
  return VoucherRepository().fetchAvailable();
});