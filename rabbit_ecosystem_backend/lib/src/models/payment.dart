import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

/// Payment method enum
enum PaymentMethod {
  cash,
  wallet,
  card,
  online,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Payment model
class Payment {
  final int id;
  final int orderId;
  final int userId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String transactionId;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional information (populated from joins)
  final String? orderUuid;
  final String? username;
  final String? mobile;

  Payment({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.orderUuid,
    this.username,
    this.mobile,
  });

  /// Factory constructor from database map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) => method.name == map['payment_method'],
      ),
      transactionId: map['transaction_id'] as String,
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == map['status'],
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      orderUuid: map['order_uuid'] as String?,
      username: map['username'] as String?,
      mobile: map['mobile'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod.name,
      'transaction_id': transactionId,
      'status': status.name,
      'order_uuid': orderUuid,
      'username': username,
      'mobile': mobile,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Refund model
class Refund {
  final int id;
  final int paymentId;
  final double amount;
  final String? reason;
  final int refundedBy;
  final String refundTransactionId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Refund({
    required this.id,
    required this.paymentId,
    required this.amount,
    this.reason,
    required this.refundedBy,
    required this.refundTransactionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor from database map
  factory Refund.fromMap(Map<String, dynamic> map) {
    return Refund(
      id: map['id'] as int,
      paymentId: map['payment_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String?,
      refundedBy: map['refunded_by'] as int,
      refundTransactionId: map['refund_transaction_id'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'amount': amount,
      'reason': reason,
      'refunded_by': refundedBy,
      'refund_transaction_id': refundTransactionId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Saved payment method information
class PaymentMethodInfo {
  final int id;
  final int userId;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic> paymentDetails;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethodInfo({
    required this.id,
    required this.userId,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor from database map
  factory PaymentMethodInfo.fromMap(Map<String, dynamic> map) {
    return PaymentMethodInfo(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) => method.name == map['payment_method'],
      ),
      paymentDetails: map['payment_details'] as Map<String, dynamic>,
      isDefault: map['is_default'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'payment_method': paymentMethod.name,
      'payment_details': paymentDetails,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get masked card number for display
  String? get maskedCardNumber {
    if (paymentMethod != PaymentMethod.card) return null;

    final cardNumber = paymentDetails['card_number'] as String?;
    if (cardNumber == null || cardNumber.length < 4) return null;

    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  /// Get card brand (simplified)
  String? get cardBrand {
    if (paymentMethod != PaymentMethod.card) return null;

    final cardNumber = paymentDetails['card_number'] as String?;
    if (cardNumber == null) return null;

    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith('5') || cardNumber.startsWith('2')) return 'Mastercard';
    if (cardNumber.startsWith('3')) return 'American Express';

    return 'Unknown';
  }
}

/// Payment gateway integration interface
abstract class PaymentGateway {
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required Map<String, dynamic> paymentDetails,
  });

  Future<Map<String, dynamic>> confirmPayment(String paymentIntentId);

  Future<Map<String, dynamic>> createRefund({
    required String paymentIntentId,
    required double amount,
    String? reason,
  });

  Future<Map<String, dynamic>> getPaymentStatus(String paymentIntentId);
}
