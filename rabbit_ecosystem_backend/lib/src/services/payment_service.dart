import '../repositories/payment_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import '../models/payment.dart';
import '../models/transaction.dart';
import '../models/user.dart';

/// Service for payment-related business logic
class PaymentService {
  final PaymentRepository _paymentRepository;
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;

  PaymentService(
    this._paymentRepository,
    this._transactionRepository,
    this._userRepository,
  );

  /// Process payment for an order
  Future<PaymentResult> processPayment({
    required int orderId,
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Validate user
      final user = await _userRepository.findById(userId);
      if (user == null) {
        return PaymentResult.error('User not found');
      }

      // Validate amount
      if (amount <= 0) {
        return PaymentResult.error('Invalid payment amount');
      }

      // Process payment based on method
      final paymentResult = await _processPaymentByMethod(
        paymentMethod,
        amount,
        paymentDetails ?? {},
      );

      if (!paymentResult.success) {
        return paymentResult;
      }

      // Create payment record
      final transactionId = paymentResult.transactionId;
      if (transactionId == null) {
        return PaymentResult.error('Payment processing failed: no transaction ID');
      }

      final payment = await _paymentRepository.createPayment(
        orderId: orderId,
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        status: PaymentStatus.completed,
      );

      // Create transaction record
      await _transactionRepository.createTransaction(CreateTransactionRequest(
        userId: userId,
        orderId: orderId,
        type: TransactionType.orderPayment,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceId: payment.transactionId,
        status: TransactionStatus.completed,
      ));

      return PaymentResult.success(
        payment: payment,
        transactionId: payment.transactionId,
        message: 'Payment processed successfully',
      );
    } catch (e) {
      return PaymentResult.error('Payment processing failed: ${e.toString()}');
    }
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(int paymentId) async {
    return await _paymentRepository.findById(paymentId);
  }

  /// Get user payments
  Future<List<Payment>> getUserPayments(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    return await _paymentRepository.findByUserId(
      userId,
      limit: limit,
      offset: offset,
    );
  }

  /// Refund payment
  Future<PaymentResult> refundPayment(
    int paymentId, {
    double? amount,
    String? reason,
    required int refundedBy,
  }) async {
    try {
      final payment = await _paymentRepository.findById(paymentId);
      if (payment == null) {
        return PaymentResult.error('Payment not found');
      }

      if (payment.status != PaymentStatus.completed) {
        return PaymentResult.error('Payment cannot be refunded');
      }

      // Calculate refund amount
      final refundAmount = amount ?? payment.amount;

      if (refundAmount > payment.amount) {
        return PaymentResult.error('Refund amount exceeds payment amount');
      }

      // Process refund with payment gateway
      final refundResult = await _processRefund(
        payment.transactionId,
        refundAmount,
        payment.paymentMethod,
      );

      if (!refundResult.success) {
        return refundResult;
      }

      final refundTransactionId = refundResult.transactionId;
      if (refundTransactionId == null) {
        return PaymentResult.error('Refund processing failed: no transaction ID');
      }

      // Create refund record
      final refund = await _paymentRepository.createRefund(
        paymentId: paymentId,
        amount: refundAmount,
        reason: reason,
        refundedBy: refundedBy,
        refundTransactionId: refundTransactionId,
      );

      // Create refund transaction record
      await _transactionRepository.createTransaction(CreateTransactionRequest(
        userId: payment.userId,
        orderId: payment.orderId,
        type: TransactionType.refund,
        amount: refundAmount,
        paymentMethod: payment.paymentMethod,
        referenceId: refund.refundTransactionId,
        status: TransactionStatus.completed,
      ));

      return PaymentResult.success(
        refund: refund,
        refundId: refund.id.toString(),
        message: 'Refund processed successfully',
      );
    } catch (e) {
      return PaymentResult.error('Refund processing failed: ${e.toString()}');
    }
  }

  /// Get available payment methods for user
  Future<List<Map<String, dynamic>>> getAvailablePaymentMethods(int userId) async {
    // This would typically check user preferences, region, etc.
    return [
      {
        'method': 'cash',
        'name': 'Cash on Delivery',
        'description': 'Pay when you receive your order',
        'is_available': true,
      },
      {
        'method': 'wallet',
        'name': 'Wallet',
        'description': 'Pay using your wallet balance',
        'is_available': true,
        'balance': await _getWalletBalance(userId),
      },
      {
        'method': 'card',
        'name': 'Credit/Debit Card',
        'description': 'Pay using your card',
        'is_available': true,
      },
    ];
  }

  /// Validate payment details
  Future<Map<String, dynamic>> validatePaymentDetails(
    PaymentMethod method,
    Map<String, dynamic> details,
  ) async {
    try {
      switch (method) {
        case PaymentMethod.cash:
          return {'is_valid': true};

        case PaymentMethod.wallet:
          // Validate wallet balance
          final userId = details['user_id'] as int?;
          final amount = details['amount'] as double?;
          if (userId == null || amount == null) {
            return {'is_valid': false, 'errors': ['User ID and amount are required']};
          }

          final balance = await _getWalletBalance(userId);
          if (balance < amount) {
            return {'is_valid': false, 'errors': ['Insufficient wallet balance']};
          }
          return {'is_valid': true};

        case PaymentMethod.card:
          // Basic card validation
          final cardNumber = details['card_number'] as String?;
          final expiryMonth = details['expiry_month'] as int?;
          final expiryYear = details['expiry_year'] as int?;
          final cvv = details['cvv'] as String?;

          final errors = <String>[];

          if (cardNumber == null || cardNumber.length < 13) {
            errors.add('Invalid card number');
          }

          if (expiryMonth == null || expiryMonth < 1 || expiryMonth > 12) {
            errors.add('Invalid expiry month');
          }

          if (expiryYear == null || expiryYear < DateTime.now().year) {
            errors.add('Invalid expiry year');
          }

          if (cvv == null || cvv.length < 3) {
            errors.add('Invalid CVV');
          }

          return {
            'is_valid': errors.isEmpty,
            'errors': errors,
          };

        default:
          return {'is_valid': false, 'errors': ['Unsupported payment method']};
      }
    } catch (e) {
      return {'is_valid': false, 'errors': ['Validation failed: ${e.toString()}']};
    }
  }

  /// Process webhook from payment gateway
  Future<void> processWebhook(Map<String, dynamic> webhookData) async {
    // This would handle webhooks from payment gateways
    // Implementation would depend on the specific gateway used
    final eventType = webhookData['event_type'];
    final transactionId = webhookData['transaction_id'];

    switch (eventType) {
      case 'payment.completed':
        await _handlePaymentCompleted(transactionId, webhookData);
        break;
      case 'payment.failed':
        await _handlePaymentFailed(transactionId, webhookData);
        break;
      case 'refund.completed':
        await _handleRefundCompleted(transactionId, webhookData);
        break;
    }
  }

  /// Verify webhook signature
  Future<bool> verifyWebhookSignature(
    Map<String, dynamic> data,
    String signature,
  ) async {
    // This would implement webhook signature verification
    // Implementation depends on payment gateway
    return true; // Placeholder
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;

    final totalPayments = await _paymentRepository.getTotalPayments(start, end);
    final totalAmount = await _paymentRepository.getTotalAmount(start, end);
    final paymentsByMethod = await _paymentRepository.getPaymentsByMethod(start, end);

    return {
      'total_payments': totalPayments,
      'total_amount': totalAmount,
      'payments_by_method': paymentsByMethod,
      'period': {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      },
    };
  }

  /// Get pending payments
  Future<List<Payment>> getPendingPayments({
    int? limit,
    int? offset,
  }) async {
    return await _paymentRepository.findByStatus(
      PaymentStatus.pending,
      limit: limit,
      offset: offset,
    );
  }

  /// Verify payment status with gateway
  Future<Map<String, dynamic>> verifyPaymentStatus(int paymentId) async {
    final payment = await _paymentRepository.findById(paymentId);
    if (payment == null) {
      return {'status': 'not_found'};
    }

    // This would call the payment gateway API to verify status
    // Placeholder implementation
    return {
      'payment_id': paymentId,
      'status': payment.status.name,
      'verified': true,
      'gateway_response': 'Payment verified',
    };
  }

  /// Generate payment receipt
  Future<Map<String, dynamic>?> generatePaymentReceipt(int paymentId, int userId) async {
    final payment = await _paymentRepository.findById(paymentId);
    if (payment == null || payment.userId != userId) {
      return null;
    }

    // Generate receipt data
    return {
      'receipt_id': 'RCP${paymentId.toString().padLeft(6, '0')}',
      'payment_id': paymentId,
      'amount': payment.amount,
      'method': payment.paymentMethod.name,
      'status': payment.status.name,
      'date': payment.createdAt.toIso8601String(),
      'transaction_id': payment.transactionId,
    };
  }

  /// Save payment method for user
  Future<PaymentMethodInfo> savePaymentMethod(
    int userId,
    PaymentMethod method,
    Map<String, dynamic> details, {
    bool isDefault = false,
  }) async {
    // Validate payment method details
    final validation = await validatePaymentDetails(method, details);
    if (!validation['is_valid']) {
      throw Exception('Invalid payment method details');
    }

    return await _paymentRepository.savePaymentMethod(
      userId: userId,
      method: method,
      details: details,
      isDefault: isDefault,
    );
  }

  /// Get user's saved payment methods
  Future<List<PaymentMethodInfo>> getUserSavedPaymentMethods(int userId) async {
    return await _paymentRepository.getUserSavedPaymentMethods(userId);
  }

  /// Delete saved payment method
  Future<bool> deleteSavedPaymentMethod(int methodId, int userId) async {
    final method = await _paymentRepository.findSavedPaymentMethodById(methodId);
    if (method == null || method.userId != userId) {
      return false;
    }

    return await _paymentRepository.deleteSavedPaymentMethod(methodId);
  }

  // Private helper methods

  Future<PaymentResult> _processPaymentByMethod(
    PaymentMethod method,
    double amount,
    Map<String, dynamic> details,
  ) async {
    switch (method) {
      case PaymentMethod.cash:
        return PaymentResult.success(
          transactionId: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
          message: 'Cash payment recorded',
        );

      case PaymentMethod.wallet:
        final userId = details['user_id'] as int?;
        if (userId == null) {
          return PaymentResult.error('User ID required for wallet payment');
        }

        final balance = await _getWalletBalance(userId);
        if (balance < amount) {
          return PaymentResult.error('Insufficient wallet balance');
        }

        // Deduct from wallet
        await _userRepository.subtractFromBalance(userId, amount);

        return PaymentResult.success(
          transactionId: 'WALLET_${DateTime.now().millisecondsSinceEpoch}',
          message: 'Wallet payment processed',
        );

      case PaymentMethod.card:
        // This would integrate with a payment gateway like Stripe, PayPal, etc.
        // Placeholder implementation
        return PaymentResult.success(
          transactionId: 'CARD_${DateTime.now().millisecondsSinceEpoch}',
          message: 'Card payment processed',
        );

      default:
        return PaymentResult.error('Unsupported payment method');
    }
  }

  Future<PaymentResult> _processRefund(
    String transactionId,
    double amount,
    PaymentMethod method,
  ) async {
    // This would integrate with payment gateway for refunds
    // Placeholder implementation
    return PaymentResult.success(
      transactionId: 'REFUND_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Refund processed',
    );
  }

  Future<double> _getWalletBalance(int userId) async {
    final user = await _userRepository.findById(userId);
    return user?.balance ?? 0.0;
  }

  Future<void> _handlePaymentCompleted(String transactionId, Map<String, dynamic> data) async {
    // Update payment status
    final payment = await _paymentRepository.findByTransactionId(transactionId);
    if (payment != null) {
      await _paymentRepository.updatePaymentStatus(payment.id, PaymentStatus.completed);
    }
  }

  Future<void> _handlePaymentFailed(String transactionId, Map<String, dynamic> data) async {
    // Update payment status
    final payment = await _paymentRepository.findByTransactionId(transactionId);
    if (payment != null) {
      await _paymentRepository.updatePaymentStatus(payment.id, PaymentStatus.failed);
    }
  }

  Future<void> _handleRefundCompleted(String transactionId, Map<String, dynamic> data) async {
    // Update refund status if needed
    // This would be handled by the refund creation logic above
  }
}

/// Result class for payment operations
class PaymentResult {
  final bool success;
  final String message;
  final Payment? payment;
  final Refund? refund;
  final String? transactionId;
  final String? refundId;
  final List<String>? errors;

  PaymentResult({
    required this.success,
    required this.message,
    this.payment,
    this.refund,
    this.transactionId,
    this.refundId,
    this.errors,
  });

  factory PaymentResult.success({
    Payment? payment,
    Refund? refund,
    String? transactionId,
    String? refundId,
    required String message,
  }) {
    return PaymentResult(
      success: true,
      message: message,
      payment: payment,
      refund: refund,
      transactionId: transactionId,
      refundId: refundId,
    );
  }

  factory PaymentResult.error(String message, [List<String>? errors]) {
    return PaymentResult(
      success: false,
      message: message,
      errors: errors,
    );
  }
}

