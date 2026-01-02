import 'package:json_annotation/json_annotation.dart';
import 'payment.dart';

part 'order.g.dart';

enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  assigned('assigned'),
  preparing('preparing'),
  onTheWay('on_the_way'),
  ready('ready'),
  pickedUp('picked_up'),
  delivered('delivered'),
  cancelled('cancelled');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  bool get isActive => [pending, confirmed, assigned, preparing, onTheWay, ready, pickedUp].contains(this);
  bool get isCompleted => this == delivered;
  bool get isCancelled => this == cancelled;
}

@JsonSerializable()
class Order {
  final int id;
  final String uuid;
  final int userId;
  final int? riderId;
  final int partnerId;
  final int addressId;
  final double subtotal;
  final double deliveryCharge;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final String? otp;
  final String? notes;
  final String? deliveryTime;
  final String? deliveryDate;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.uuid,
    required this.userId,
    this.riderId,
    required this.partnerId,
    required this.addressId,
    required this.subtotal,
    this.deliveryCharge = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.status = OrderStatus.pending,
    this.otp,
    this.notes,
    this.deliveryTime,
    this.deliveryDate,
    this.estimatedDelivery,
    this.actualDelivery,
    this.items = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  /// Factory constructor from database map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      userId: map['user_id'] as int,
      riderId: map['rider_id'] as int?,
      partnerId: map['partner_id'] as int,
      addressId: map['address_id'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
      deliveryCharge: (map['delivery_charge'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) => method.name == map['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      otp: map['otp'] as String?,
      notes: map['notes'] as String?,
      deliveryTime: map['delivery_time'] as String?,
      deliveryDate: map['delivery_date'] as String?,
      estimatedDelivery: map['estimated_delivery'] != null
          ? DateTime.parse(map['estimated_delivery'] as String)
          : null,
      actualDelivery: map['actual_delivery'] != null
          ? DateTime.parse(map['actual_delivery'] as String)
          : null,
      items: [], // Would need to be populated separately
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Order copyWith({
    int? id,
    String? uuid,
    int? userId,
    int? riderId,
    int? partnerId,
    int? addressId,
    double? subtotal,
    double? deliveryCharge,
    double? taxAmount,
    double? discountAmount,
    double? total,
    PaymentMethod? paymentMethod,
    OrderStatus? status,
    String? otp,
    String? notes,
    String? deliveryTime,
    String? deliveryDate,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      riderId: riderId ?? this.riderId,
      partnerId: partnerId ?? this.partnerId,
      addressId: addressId ?? this.addressId,
      subtotal: subtotal ?? this.subtotal,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      otp: otp ?? this.otp,
      notes: notes ?? this.notes,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id && other.uuid == uuid;
  }

  @override
  int get hashCode => Object.hash(id, uuid);

  // Computed properties for backward compatibility
  int get customerId => userId;
  double get totalAmount => total;
  double get finalTotal => total;
  double get deliveryFee => deliveryCharge;
  DateTime? get estimatedDeliveryTime => estimatedDelivery;

  @override
  String toString() {
    return 'Order(id: $id, uuid: $uuid, status: $status, total: $total)';
  }
}

@JsonSerializable()
class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int? productVariantId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? specialInstructions;
  final List<OrderItemAddon> addons;
  final DateTime createdAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productVariantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.specialInstructions,
    this.addons = const [],
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? productVariantId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? specialInstructions,
    List<OrderItemAddon>? addons,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productVariantId: productVariantId ?? this.productVariantId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      addons: addons ?? this.addons,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class OrderItemAddon {
  final int id;
  final int orderItemId;
  final int productAddonId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemAddon({
    required this.id,
    required this.orderItemId,
    required this.productAddonId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemAddon.fromJson(Map<String, dynamic> json) => _$OrderItemAddonFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemAddonToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemAddon && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class CreateOrderRequest {
  final int userId;
  final int partnerId;
  final int addressId;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String? deliveryTime;
  final String? deliveryDate;
  final List<CreateOrderItemRequest> items;

  const CreateOrderRequest({
    required this.userId,
    required this.partnerId,
    required this.addressId,
    required this.paymentMethod,
    this.notes,
    this.deliveryTime,
    this.deliveryDate,
    required this.items,
  });

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) => _$CreateOrderRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderRequestToJson(this);
}

@JsonSerializable()
class CreateOrderItemRequest {
  final int productId;
  final int? productVariantId;
  final int quantity;
  final String? specialInstructions;
  final List<CreateOrderItemAddonRequest> addons;

  const CreateOrderItemRequest({
    required this.productId,
    this.productVariantId,
    required this.quantity,
    this.specialInstructions,
    this.addons = const [],
  });

  factory CreateOrderItemRequest.fromJson(Map<String, dynamic> json) => _$CreateOrderItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderItemRequestToJson(this);
}

@JsonSerializable()
class CreateOrderItemAddonRequest {
  final int productAddonId;
  final int quantity;

  const CreateOrderItemAddonRequest({
    required this.productAddonId,
    required this.quantity,
  });

  factory CreateOrderItemAddonRequest.fromJson(Map<String, dynamic> json) => _$CreateOrderItemAddonRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateOrderItemAddonRequestToJson(this);
}

@JsonSerializable()
class UpdateOrderStatusRequest {
  final OrderStatus status;
  final int? riderId;
  final String? notes;

  const UpdateOrderStatusRequest({
    required this.status,
    this.riderId,
    this.notes,
  });

  factory UpdateOrderStatusRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrderStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateOrderStatusRequestToJson(this);
}

@JsonSerializable()
class OrderFilter {
  final int? userId;
  final int? partnerId;
  final int? riderId;
  final OrderStatus? status;
  final PaymentMethod? paymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minTotal;
  final double? maxTotal;

  const OrderFilter({
    this.userId,
    this.partnerId,
    this.riderId,
    this.status,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.minTotal,
    this.maxTotal,
  });

  factory OrderFilter.fromJson(Map<String, dynamic> json) => _$OrderFilterFromJson(json);
  Map<String, dynamic> toJson() => _$OrderFilterToJson(this);
}