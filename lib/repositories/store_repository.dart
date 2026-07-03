// ==================================================================
//  FLUTTER — app khach (package bavia)
//  Dat tai:  lib/repositories/store_repository.dart
//  >> FILE MOI (tao moi)
// ==================================================================

// lib/repositories/store_repository.dart
//
// Trạng thái mở/đóng cửa. Route: GET /api/store/status (công khai).

import '../core/network/api_client.dart';
import '../models/store_status.dart';

class StoreRepository {
  final ApiClient _api = ApiClient.I;

  Future<StoreStatus> getStatus() async {
    final data = await _api.get('/store/status', skipAuth: true);
    return StoreStatus.fromJson((data as Map).cast<String, dynamic>());
  }
}