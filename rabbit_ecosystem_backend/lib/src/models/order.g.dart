// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
      id: (json['id'] as num).toInt(),
      uuid: json['uuid'] as String,
      userId: (json['userId'] as num).toInt(),
      riderId: (json['riderId'] as num?)?.toInt(),
      partnerId: (json['partnerId'] as num).toInt(),
      addressId: (json['addressId'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
          OrderStatus.pending,
      otp: json['otp'] as String?,
      notes: json['notes'] as String?,
      deliveryTime: json['deliveryTime'] as String?,
      deliveryDate: json['deliveryDate'] as String?,
      estimatedDelivery: json['estimatedDelivery'] == null
          ? null
          : DateTime.parse(json['estimatedDelivery'] as String),
      actualDelivery: json['actualDelivery'] == null
          ? null
          : DateTime.parse(json['actualDelivery'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'userId': instance.userId,
      'riderId': instance.riderId,
      'partnerId': instance.partnerId,
      'addressId': instance.addressId,
      'subtotal': instance.subtotal,
      'deliveryCharge': instance.deliveryCharge,
      'taxAmount': instance.taxAmount,
      'discountAmount': instance.discountAmount,
      'total': instance.total,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'otp': instance.otp,
      'notes': instance.notes,
      'deliveryTime': instance.deliveryTime,
      'deliveryDate': instance.deliveryDate,
      'estimatedDelivery': instance.estimatedDelivery?.toIso8601String(),
      'actualDelivery': instance.actualDelivery?.toIso8601String(),
      'items': instance.items,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.card: 'card',
  PaymentMethod.online: 'online',
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.assigned: 'assigned',
  OrderStatus.preparing: 'preparing',
  OrderStatus.onTheWay: 'onTheWay',
  OrderStatus.ready: 'ready',
  OrderStatus.pickedUp: 'pickedUp',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
      id: (json['id'] as num).toInt(),
      orderId: (json['orderId'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productVariantId: (json['productVariantId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      specialInstructions: json['specialInstructions'] as String?,
      addons: (json['addons'] as List<dynamic>?)
              ?.map((e) => OrderItemAddon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'productId': instance.productId,
      'productVariantId': instance.productVariantId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'totalPrice': instance.totalPrice,
      'specialInstructions': instance.specialInstructions,
      'addons': instance.addons,
      'createdAt': instance.createdAt.toIso8601String(),
    };

OrderItemAddon _$OrderItemAddonFromJson(Map<String, dynamic> json) =>
    OrderItemAddon(
      id: (json['id'] as num).toInt(),
      orderItemId: (json['orderItemId'] as num).toInt(),
      productAddonId: (json['productAddonId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderItemAddonToJson(OrderItemAddon instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderItemId': instance.orderItemId,
      'productAddonId': instance.productAddonId,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
      'totalPrice': instance.totalPrice,
    };

CreateOrderRequest _$CreateOrderRequestFromJson(Map<String, dynamic> json) =>
    CreateOrderRequest(
      userId: (json['userId'] as num).toInt(),
      partnerId: (json['partnerId'] as num).toInt(),
      addressId: (json['addressId'] as num).toInt(),
      paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
      notes: json['notes'] as String?,
      deliveryTime: json['deliveryTime'] as String?,
      deliveryDate: json['deliveryDate'] as String?,
      items: (json['items'] as List<dynamic>)
          .map(
              (e) => CreateOrderItemRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateOrderRequestToJson(CreateOrderRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'partnerId': instance.partnerId,
      'addressId': instance.addressId,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'notes': instance.notes,
      'deliveryTime': instance.deliveryTime,
      'deliveryDate': instance.deliveryDate,
      'items': instance.items,
    };

CreateOrderItemRequest _$CreateOrderItemRequestFromJson(
        Map<String, dynamic> json) =>
    CreateOrderItemRequest(
      productId: (json['productId'] as num).toInt(),
      productVariantId: (json['productVariantId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num).toInt(),
      specialInstructions: json['specialInstructions'] as String?,
      addons: (json['addons'] as List<dynamic>?)
              ?.map((e) => CreateOrderItemAddonRequest.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CreateOrderItemRequestToJson(
        CreateOrderItemRequest instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productVariantId': instance.productVariantId,
      'quantity': instance.quantity,
      'specialInstructions': instance.specialInstructions,
      'addons': instance.addons,
    };

CreateOrderItemAddonRequest _$CreateOrderItemAddonRequestFromJson(
        Map<String, dynamic> json) =>
    CreateOrderItemAddonRequest(
      productAddonId: (json['productAddonId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$CreateOrderItemAddonRequestToJson(
        CreateOrderItemAddonRequest instance) =>
    <String, dynamic>{
      'productAddonId': instance.productAddonId,
      'quantity': instance.quantity,
    };

UpdateOrderStatusRequest _$UpdateOrderStatusRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateOrderStatusRequest(
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      riderId: (json['riderId'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$UpdateOrderStatusRequestToJson(
        UpdateOrderStatusRequest instance) =>
    <String, dynamic>{
      'status': _$OrderStatusEnumMap[instance.status]!,
      'riderId': instance.riderId,
      'notes': instance.notes,
    };

OrderFilter _$OrderFilterFromJson(Map<String, dynamic> json) => OrderFilter(
      userId: (json['userId'] as num?)?.toInt(),
      partnerId: (json['partnerId'] as num?)?.toInt(),
      riderId: (json['riderId'] as num?)?.toInt(),
      status: $enumDecodeNullable(_$OrderStatusEnumMap, json['status']),
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      minTotal: (json['minTotal'] as num?)?.toDouble(),
      maxTotal: (json['maxTotal'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$OrderFilterToJson(OrderFilter instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'partnerId': instance.partnerId,
      'riderId': instance.riderId,
      'status': _$OrderStatusEnumMap[instance.status],
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'minTotal': instance.minTotal,
      'maxTotal': instance.maxTotal,
    };
