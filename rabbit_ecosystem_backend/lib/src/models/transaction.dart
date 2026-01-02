import 'package:json_annotation/json_annotation.dart';
import 'order.dart';
import 'payment.dart';

part 'transaction.g.dart';

enum TransactionType {
  orderPayment('order_payment'),
  walletTopup('wallet_topup'),
  withdrawal('withdrawal'),
  commission('commission'),
  refund('refund');

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.orderPayment,
    );
  }
}

enum TransactionStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const TransactionStatus(this.value);
  final String value;

  static TransactionStatus fromString(String value) {
    return TransactionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TransactionStatus.pending,
    );
  }

  bool get isCompleted => this == completed;
  bool get isFailed => this == failed;
  bool get isPending => this == pending;
  bool get isProcessing => this == processing;
  bool get isCancelled => this == cancelled;
}

@JsonSerializable()
class Transaction {
  final int id;
  final String uuid;
  final int userId;
  final int? orderId;
  final TransactionType type;
  final double amount;
  final String? description;
  final String? referenceId;
  final PaymentMethod? paymentMethod;
  final TransactionStatus status;
  final DateTime? processedAt;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.uuid,
    required this.userId,
    this.orderId,
    required this.type,
    required this.amount,
    this.description,
    this.referenceId,
    this.paymentMethod,
    this.status = TransactionStatus.pending,
    this.processedAt,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Transaction copyWith({
    int? id,
    String? uuid,
    int? userId,
    int? orderId,
    TransactionType? type,
    double? amount,
    String? description,
    String? referenceId,
    PaymentMethod? paymentMethod,
    TransactionStatus? status,
    DateTime? processedAt,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCredit => [TransactionType.walletTopup, TransactionType.refund].contains(type);
  bool get isDebit => [TransactionType.orderPayment, TransactionType.withdrawal, TransactionType.commission].contains(type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id && other.uuid == uuid;
  }

  @override
  int get hashCode => Object.hash(id, uuid);

  @override
  String toString() {
    return 'Transaction(id: $id, uuid: $uuid, type: $type, amount: $amount, status: $status)';
  }
}

@JsonSerializable()
class Address {
  final int id;
  final int userId;
  final String? title;
  final String addressLine1;
  final String? addressLine2;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  const Address({
    required this.id,
    required this.userId,
    this.title,
    required this.addressLine1,
    this.addressLine2,
    this.cityId,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);

  Address copyWith({
    int? id,
    int? userId,
    String? title,
    String? addressLine1,
    String? addressLine2,
    int? cityId,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      cityId: cityId ?? this.cityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullAddress {
    final parts = [addressLine1, addressLine2].where((part) => part != null && part.isNotEmpty);
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Address(id: $id, title: $title, address: $fullAddress)';
  }
}

@JsonSerializable()
class Notification {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.isRead = false,
    required this.sentAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, isRead: $isRead)';
  }
}

@JsonSerializable()
class City {
  final int id;
  final String name;
  final String country;
  final bool isActive;
  final DateTime createdAt;

  const City({
    required this.id,
    required this.name,
    this.country = 'Saudi Arabia',
    this.isActive = true,
    required this.createdAt,
  });

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
  Map<String, dynamic> toJson() => _$CityToJson(this);

  City copyWith({
    int? id,
    String? name,
    String? country,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is City && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'City(id: $id, name: $name, country: $country)';
  }
}

@JsonSerializable()
class CreateTransactionRequest {
  final int userId;
  final int? orderId;
  final TransactionType type;
  final double amount;
  final String? description;
  final String? referenceId;
  final PaymentMethod? paymentMethod;
  final TransactionStatus status;

  const CreateTransactionRequest({
    required this.userId,
    this.orderId,
    required this.type,
    required this.amount,
    this.description,
    this.referenceId,
    this.paymentMethod,
    this.status = TransactionStatus.pending,
  });

  factory CreateTransactionRequest.fromJson(Map<String, dynamic> json) => _$CreateTransactionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTransactionRequestToJson(this);
}

@JsonSerializable()
class CreateAddressRequest {
  final int userId;
  final String? title;
  final String addressLine1;
  final String? addressLine2;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final bool? isDefault;

  const CreateAddressRequest({
    required this.userId,
    this.title,
    required this.addressLine1,
    this.addressLine2,
    this.cityId,
    this.latitude,
    this.longitude,
    this.isDefault,
  });

  factory CreateAddressRequest.fromJson(Map<String, dynamic> json) => _$CreateAddressRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAddressRequestToJson(this);
}

@JsonSerializable()
class CreateNotificationRequest {
  final int userId;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;

  const CreateNotificationRequest({
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
  });

  factory CreateNotificationRequest.fromJson(Map<String, dynamic> json) => _$CreateNotificationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateNotificationRequestToJson(this);
}

@JsonSerializable()
class TransactionFilter {
  final int? userId;
  final TransactionType? type;
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilter({
    this.userId,
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  factory TransactionFilter.fromJson(Map<String, dynamic> json) => _$TransactionFilterFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionFilterToJson(this);

  TransactionFilter copyWith({
    int? userId,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) {
    return TransactionFilter(
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}