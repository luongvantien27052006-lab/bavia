// ============================================================
//  FLUTTER
//  lib/providers/repository_providers.dart
//  >> CHEP DE (them newsRepositoryProvider)
// ============================================================

// lib/providers/repository_providers.dart
//
// Khai báo các repository + service dưới dạng Riverpod provider để toàn app
// inject dùng chung. Tách riêng để dễ override khi viết test.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/address_repository.dart';
import '../repositories/voucher_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/loyalty_repository.dart';
import '../repositories/news_repository.dart';
import '../services/firebase_auth_service.dart';

final firebaseAuthServiceProvider =
    Provider<FirebaseAuthService>((ref) => FirebaseAuthService());

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

final productRepositoryProvider =
    Provider<ProductRepository>((ref) => ProductRepository());

final addressRepositoryProvider =
    Provider<AddressRepository>((ref) => AddressRepository());

final voucherRepositoryProvider =
    Provider<VoucherRepository>((ref) => VoucherRepository());

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository());

final loyaltyRepositoryProvider =
    Provider<LoyaltyRepository>((ref) => LoyaltyRepository());

final newsRepositoryProvider =
    Provider<NewsRepository>((ref) => NewsRepository());