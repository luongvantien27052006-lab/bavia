# Bavia Coffee — App khách hàng (Flutter + Riverpod)

App đặt món kết nối backend Bavia (NestJS) trên Railway. Kiến trúc Riverpod,
nối API thật: Firebase Phone Auth → JWT Bavia, menu, giỏ hàng, voucher, đặt đơn
(COD/VietQR), thanh toán realtime qua Socket.IO, lịch sử đơn, địa chỉ, điểm thưởng.

## Cấu trúc

```
lib/
├── core/
│   ├── config/      api_config.dart (domain Railway), loyalty_config.dart
│   ├── network/     api_client.dart (Dio + JWT auto-refresh), api_exception.dart
│   ├── realtime/    socket_service.dart (Socket.IO /realtime)
│   ├── storage/     secure_storage.dart (JWT trong Keystore/Keychain)
│   └── theme/       app_theme.dart (nâu cà phê, Material 3)
├── models/          product, user, address, voucher, order, loyalty, paginated, json_x
├── repositories/    auth, product, address, voucher, order, loyalty
├── providers/       auth, login, cart, menu, checkout, order, address, loyalty, repository
├── screens/         auth, home, menu, product, cart, checkout, orders, address, loyalty,
│                    scan, account, splash + main_shell
├── widgets/         product_card, product_image
├── utils/           formatters (tiền VND, SĐT E.164, ngày giờ)
├── app.dart         điều hướng theo trạng thái đăng nhập
└── main.dart        khởi tạo Firebase + ApiClient
```

## Chạy app — các bước bắt buộc

### 1. Tạo project và copy code
```bash
flutter create bavia        # đúng tên "bavia" để khớp imports package:bavia/...
# Copy đè thư mục lib/ và file pubspec.yaml vào project
flutter pub get
```

### 2. Điền domain backend
Mở `lib/core/config/api_config.dart`, sửa đúng 1 dòng:
```dart
static const String _appHost = 'merry-harmony-production-ae63.up.railway.app';
```
KHÔNG kèm `https://`, KHÔNG kèm `/api` (code tự thêm). Đây phải là domain của
service APP (merry-harmony), KHÔNG phải Postgres.

Kiểm tra backend sống: mở `https://<domain>/api/health` trên browser → `{"status":"ok"}`.

### 3. Firebase
```bash
flutterfire configure --project=<firebase-project-id>
```
Rồi mở dòng `DefaultFirebaseOptions` trong `main.dart`. Trong Firebase Console:
bật Phone Auth, thêm số test `+84900000001` (OTP `123456`), thêm SHA-1 lấy từ
`cd android && ./gradlew signingReport`.

### 4. AndroidManifest
Đảm bảo `android/app/src/main/AndroidManifest.xml` có:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 5. Chạy
```bash
flutter run
```

## Lưu ý quan trọng

- `loyalty_config.dart` chứa `pointValue` và `maxRedeemPercent` để ƯỚC TÍNH mức
  giảm khi dùng điểm. Các giá trị này PHẢI khớp `.env` backend
  (`LOYALTY_POINT_VALUE`, `LOYALTY_MAX_REDEEM_PERCENT`). Backend vẫn là nguồn
  sự thật cuối cùng khi tạo đơn.
- Backend hết credit Railway sẽ suspend → app timeout. Theo dõi credit.
- `image_url` sản phẩm hiện trả null → app dùng placeholder theo category.

## Endpoint backend đang dùng (đã xác nhận từ source)

- `POST /auth/login/phone`, `POST /auth/refresh`, `GET /auth/me`
- `GET /products`, `GET /products/:id`
- `GET/POST/PATCH/DELETE /addresses`
- `POST /vouchers/validate`
- `POST /orders` (items, paymentMethod, voucherCode, validationToken,
  pointsToRedeem, deliveryAddress), `GET /orders`, `GET /orders/:id`,
  `POST /orders/:id/cancel`
- `GET /loyalty/balance`, `GET /loyalty/history`
- Socket `/realtime`: nghe `payment.confirmed`
