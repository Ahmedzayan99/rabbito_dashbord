// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: (json['id'] as num).toInt(),
      orderId: (json['orderId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
      transactionId: json['transactionId'] as String,
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      orderUuid: json['orderUuid'] as String?,
      username: json['username'] as String?,
      mobile: json['mobile'] as String?,
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'userId': instance.userId,
      'amount': instance.amount,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'transactionId': instance.transactionId,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'paidAt': instance.paidAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'orderUuid': instance.orderUuid,
      'username': instance.username,
      'mobile': instance.mobile,
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.card: 'card',
  PaymentMethod.online: 'online',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.processing: 'processing',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.cancelled: 'cancelled',
  PaymentStatus.refunded: 'refunded',
};
