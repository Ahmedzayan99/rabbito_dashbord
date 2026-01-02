// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: (json['id'] as num).toInt(),
      uuid: json['uuid'] as String,
      userId: (json['userId'] as num).toInt(),
      orderId: (json['orderId'] as num?)?.toInt(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']),
      status: $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']) ??
          TransactionStatus.pending,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'userId': instance.userId,
      'orderId': instance.orderId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'description': instance.description,
      'referenceId': instance.referenceId,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'processedAt': instance.processedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.orderPayment: 'orderPayment',
  TransactionType.walletTopup: 'walletTopup',
  TransactionType.withdrawal: 'withdrawal',
  TransactionType.commission: 'commission',
  TransactionType.refund: 'refund',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.card: 'card',
  PaymentMethod.online: 'online',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.processing: 'processing',
  TransactionStatus.completed: 'completed',
  TransactionStatus.failed: 'failed',
  TransactionStatus.cancelled: 'cancelled',
};

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      title: json['title'] as String?,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      cityId: (json['cityId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'addressLine1': instance.addressLine1,
      'addressLine2': instance.addressLine2,
      'cityId': instance.cityId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt.toIso8601String(),
    };

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'body': instance.body,
      'type': instance.type,
      'data': instance.data,
      'isRead': instance.isRead,
      'sentAt': instance.sentAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };

City _$CityFromJson(Map<String, dynamic> json) => City(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      country: json['country'] as String? ?? 'Saudi Arabia',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CityToJson(City instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'country': instance.country,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

CreateTransactionRequest _$CreateTransactionRequestFromJson(
        Map<String, dynamic> json) =>
    CreateTransactionRequest(
      userId: (json['userId'] as num).toInt(),
      orderId: (json['orderId'] as num?)?.toInt(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']),
    );

Map<String, dynamic> _$CreateTransactionRequestToJson(
        CreateTransactionRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'orderId': instance.orderId,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'description': instance.description,
      'referenceId': instance.referenceId,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
    };

CreateAddressRequest _$CreateAddressRequestFromJson(
        Map<String, dynamic> json) =>
    CreateAddressRequest(
      userId: (json['userId'] as num).toInt(),
      title: json['title'] as String?,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      cityId: (json['cityId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool?,
    );

Map<String, dynamic> _$CreateAddressRequestToJson(
        CreateAddressRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'title': instance.title,
      'addressLine1': instance.addressLine1,
      'addressLine2': instance.addressLine2,
      'cityId': instance.cityId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'isDefault': instance.isDefault,
    };

CreateNotificationRequest _$CreateNotificationRequestFromJson(
        Map<String, dynamic> json) =>
    CreateNotificationRequest(
      userId: (json['userId'] as num).toInt(),
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CreateNotificationRequestToJson(
        CreateNotificationRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'title': instance.title,
      'body': instance.body,
      'type': instance.type,
      'data': instance.data,
    };

TransactionFilter _$TransactionFilterFromJson(Map<String, dynamic> json) =>
    TransactionFilter(
      userId: (json['userId'] as num?)?.toInt(),
      type: $enumDecodeNullable(_$TransactionTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      minAmount: (json['minAmount'] as num?)?.toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TransactionFilterToJson(TransactionFilter instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'type': _$TransactionTypeEnumMap[instance.type],
      'status': _$TransactionStatusEnumMap[instance.status],
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'minAmount': instance.minAmount,
      'maxAmount': instance.maxAmount,
    };
