// lib/models/group_order.dart
//
// Phòng đặt chung: gộp món của nhiều người thành 1 đơn (chủ phòng trả).

import 'json_x.dart';

class GroupItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final List<Map<String, dynamic>> options;
  final String? note;
  final bool isMine;

  const GroupItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.options = const [],
    this.note,
    this.isMine = false,
  });

  int get lineTotal => unitPrice * quantity;

  factory GroupItem.fromJson(Map<String, dynamic> j) => GroupItem(
        id: JsonX.str(j, ['id']),
        productId: JsonX.str(j, ['productId', 'product_id']),
        productName: JsonX.str(j, ['productName', 'product_name']),
        quantity: JsonX.intVal(j, ['quantity']),
        unitPrice: JsonX.intVal(j, ['unitPrice', 'unit_price']),
        options: JsonX
            .list(j, ['options'])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        note: JsonX.strOrNull(j, ['note']),
        isMine: JsonX.boolVal(j, ['isMine', 'is_mine']),
      );
}

class GroupParticipant {
  final String userId;
  final String name;
  final bool isHost;
  final int subtotal;
  final int? remaining;
  final String? paymentStatus; // PENDING/SUBMITTED/CONFIRMED (chế độ SPLIT)
  final int? paymentAmount;
  final List<GroupItem> items;

  const GroupParticipant({
    required this.userId,
    required this.name,
    this.isHost = false,
    this.subtotal = 0,
    this.remaining,
    this.paymentStatus,
    this.paymentAmount,
    this.items = const [],
  });

  factory GroupParticipant.fromJson(Map<String, dynamic> j) =>
      GroupParticipant(
        userId: JsonX.str(j, ['userId', 'user_id']),
        name: JsonX.str(j, ['name']),
        isHost: JsonX.boolVal(j, ['isHost', 'is_host']),
        subtotal: JsonX.intVal(j, ['subtotal']),
        remaining: JsonX.pick(j, ['remaining']) is num
            ? JsonX.intVal(j, ['remaining'])
            : null,
        paymentStatus: JsonX.strOrNull(j, ['paymentStatus', 'payment_status']),
        paymentAmount: JsonX.pick(j, ['paymentAmount']) is num
            ? JsonX.intVal(j, ['paymentAmount'])
            : null,
        items: JsonX
            .list(j, ['items'])
            .whereType<Map>()
            .map((e) => GroupItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class GroupOrder {
  final String id;
  final String code;
  final String status; // OPEN, LOCKED, ORDERED, CANCELLED
  final String fulfillment;
  final Map<String, dynamic>? deliveryAddress;
  final String hostUserId;
  final bool isHost;
  final String? orderId;
  final String? orderStatus; // trạng thái đơn sau khi chốt
  final List<GroupParticipant> participants;
  final int totalItems;
  final int subtotal;
  final int? spendingLimit;
  final String paymentMode;
  final String splitMethod;
  final GroupBill? bill;
  final GroupPayment? myPayment;

  const GroupOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.fulfillment,
    required this.hostUserId,
    this.deliveryAddress,
    this.isHost = false,
    this.orderId,
    this.orderStatus,
    this.participants = const [],
    this.totalItems = 0,
    this.subtotal = 0,
    this.spendingLimit,
    this.paymentMode = 'HOST_PAYS',
    this.splitMethod = 'PROPORTIONAL',
    this.bill,
    this.myPayment,
  });

  bool get isOpen => status == 'OPEN';
  bool get isLocked => status == 'LOCKED';
  bool get isOrdered => status == 'ORDERED';
  bool get isCollecting => status == 'COLLECTING';
  bool get isSplit => paymentMode == 'SPLIT';
  bool get isDelivery => fulfillment == 'DELIVERY';

  factory GroupOrder.fromJson(Map<String, dynamic> j) => GroupOrder(
        id: JsonX.str(j, ['id']),
        code: JsonX.str(j, ['code']),
        status: JsonX.str(j, ['status']),
        fulfillment: JsonX.str(j, ['fulfillment']),
        deliveryAddress: JsonX.pick(j, ['deliveryAddress', 'delivery_address'])
                is Map
            ? Map<String, dynamic>.from(
                JsonX.pick(j, ['deliveryAddress', 'delivery_address']) as Map)
            : null,
        hostUserId: JsonX.str(j, ['hostUserId', 'host_user_id']),
        isHost: JsonX.boolVal(j, ['isHost', 'is_host']),
        orderId: JsonX.strOrNull(j, ['orderId', 'order_id']),
        orderStatus: JsonX.strOrNull(j, ['orderStatus', 'order_status']),
        participants: JsonX
            .list(j, ['participants'])
            .whereType<Map>()
            .map((e) =>
                GroupParticipant.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totalItems: JsonX.intVal(j, ['totalItems', 'total_items']),
        subtotal: JsonX.intVal(j, ['subtotal']),
        spendingLimit:
            JsonX.pick(j, ['spendingLimit', 'spending_limit']) is num
                ? JsonX.intVal(j, ['spendingLimit', 'spending_limit'])
                : null,
        paymentMode: JsonX.str(j, ['paymentMode', 'payment_mode'],
            fallback: 'HOST_PAYS'),
        splitMethod: JsonX.str(j, ['splitMethod', 'split_method'],
            fallback: 'PROPORTIONAL'),
        bill: JsonX.pick(j, ['bill']) is Map
            ? GroupBill.fromJson(
                Map<String, dynamic>.from(JsonX.pick(j, ['bill']) as Map))
            : null,
        myPayment: JsonX.pick(j, ['myPayment']) is Map
            ? GroupPayment.fromJson(
                Map<String, dynamic>.from(JsonX.pick(j, ['myPayment']) as Map))
            : null,
      );
}

class GroupPayment {
  final int amount;
  final String? qrUrl;
  final String? transferContent;
  final String status; // PENDING/SUBMITTED/CONFIRMED

  const GroupPayment({
    required this.amount,
    this.qrUrl,
    this.transferContent,
    this.status = 'PENDING',
  });

  bool get isPending => status == 'PENDING';

  factory GroupPayment.fromJson(Map<String, dynamic> j) => GroupPayment(
        amount: JsonX.intVal(j, ['amount']),
        qrUrl: JsonX.strOrNull(j, ['qrUrl', 'qr_url']),
        transferContent:
            JsonX.strOrNull(j, ['transferContent', 'transfer_content']),
        status: JsonX.str(j, ['status'], fallback: 'PENDING'),
      );
}

class BillShare {
  final String userId;
  final String name;
  final int itemsSubtotal;
  final int discountShare;
  final int shippingShare;
  final int finalShare;

  const BillShare({
    required this.userId,
    required this.name,
    required this.itemsSubtotal,
    required this.discountShare,
    required this.shippingShare,
    required this.finalShare,
  });

  factory BillShare.fromJson(Map<String, dynamic> j) => BillShare(
        userId: JsonX.str(j, ['userId', 'user_id']),
        name: JsonX.str(j, ['name']),
        itemsSubtotal: JsonX.intVal(j, ['itemsSubtotal']),
        discountShare: JsonX.intVal(j, ['discountShare']),
        shippingShare: JsonX.intVal(j, ['shippingShare']),
        finalShare: JsonX.intVal(j, ['finalShare']),
      );
}

class GroupBill {
  final bool preview;
  final String paymentMode;
  final int subtotal;
  final int itemDiscount;
  final int shippingFee;
  final int grandTotal;
  final List<BillShare> shares;

  const GroupBill({
    this.preview = false,
    this.paymentMode = 'HOST_PAYS',
    this.subtotal = 0,
    this.itemDiscount = 0,
    this.shippingFee = 0,
    this.grandTotal = 0,
    this.shares = const [],
  });

  factory GroupBill.fromJson(Map<String, dynamic> j) => GroupBill(
        preview: JsonX.boolVal(j, ['preview']),
        paymentMode: JsonX.str(j, ['paymentMode', 'payment_mode'],
            fallback: 'HOST_PAYS'),
        subtotal: JsonX.intVal(j, ['subtotal']),
        itemDiscount: JsonX.intVal(j, ['itemDiscount']),
        shippingFee: JsonX.intVal(j, ['shippingFee']),
        grandTotal: JsonX.intVal(j, ['grandTotal']),
        shares: JsonX
            .list(j, ['shares'])
            .whereType<Map>()
            .map((e) => BillShare.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}