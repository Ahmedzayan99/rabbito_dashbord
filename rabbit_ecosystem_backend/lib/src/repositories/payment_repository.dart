import 'base_repository.dart';
import '../models/payment.dart';

/// Repository for payment-related database operations
class PaymentRepository extends BaseRepository {
  /// Create new payment
  Future<Payment> createPayment({
    required int orderId,
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String transactionId,
    PaymentStatus status = PaymentStatus.pending,
  }) async {
    final result = await db.query(
      '''
      INSERT INTO payments (
        order_id, user_id, amount, payment_method, transaction_id,
        status, created_at, updated_at
      )
      VALUES (@orderId, @userId, @amount, @method, @transactionId,
              @status, NOW(), NOW())
      RETURNING id, order_id, user_id, amount, payment_method,
                transaction_id, status, created_at, updated_at
      ''',
      substitutionValues: {
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'method': paymentMethod.name,
        'transactionId': transactionId,
        'status': status.name,
      },
    );

    return Payment.fromMap(result.first.asMap());
  }

  /// Find payment by ID
  Future<Payment?> findById(int id) async {
    final result = await db.query(
      '''
      SELECT p.*, o.uuid as order_uuid, u.username, u.mobile
      FROM payments p
      LEFT JOIN orders o ON p.order_id = o.id
      LEFT JOIN users u ON p.user_id = u.id
      WHERE p.id = @id
      ''',
      substitutionValues: {'id': id},
    );

    if (result.isEmpty) return null;
    return Payment.fromMap(result.first.asMap());
  }

  /// Find payment by transaction ID
  Future<Payment?> findByTransactionId(String transactionId) async {
    final result = await db.query(
      'SELECT * FROM payments WHERE transaction_id = @transactionId',
      substitutionValues: {'transactionId': transactionId},
    );

    if (result.isEmpty) return null;
    return Payment.fromMap(result.first.asMap());
  }

  /// Find payments by user ID
  Future<List<Payment>> findByUserId(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await db.query(
      '''
      SELECT p.*, o.uuid as order_uuid
      FROM payments p
      LEFT JOIN orders o ON p.order_id = o.id
      WHERE p.user_id = @userId
      ORDER BY p.created_at DESC
      $limitClause $offsetClause
      ''',
      substitutionValues: {'userId': userId},
    );

    return result.map((row) => Payment.fromMap(row.asMap())).toList();
  }

  /// Find payments by status
  Future<List<Payment>> findByStatus(
    PaymentStatus status, {
    int? limit,
    int? offset,
  }) async {
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await db.query(
      '''
      SELECT p.*, u.username, u.mobile, o.uuid as order_uuid
      FROM payments p
      LEFT JOIN users u ON p.user_id = u.id
      LEFT JOIN orders o ON p.order_id = o.id
      WHERE p.status = @status
      ORDER BY p.created_at DESC
      $limitClause $offsetClause
      ''',
      substitutionValues: {'status': status.name},
    );

    return result.map((row) => Payment.fromMap(row.asMap())).toList();
  }

  /// Update payment status
  Future<Payment?> updatePaymentStatus(int paymentId, PaymentStatus status) async {
    final result = await db.query(
      '''
      UPDATE payments
      SET status = @status, updated_at = NOW()
      WHERE id = @id
      RETURNING id, order_id, user_id, amount, payment_method,
                transaction_id, status, created_at, updated_at
      ''',
      substitutionValues: {
        'id': paymentId,
        'status': status.name,
      },
    );

    if (result.isEmpty) return null;
    return Payment.fromMap(result.first.asMap());
  }

  /// Create refund record
  Future<Refund> createRefund({
    required int paymentId,
    required double amount,
    String? reason,
    required int refundedBy,
    required String refundTransactionId,
  }) async {
    final result = await db.query(
      '''
      INSERT INTO refunds (
        payment_id, amount, reason, refunded_by, refund_transaction_id,
        status, created_at, updated_at
      )
      VALUES (@paymentId, @amount, @reason, @refundedBy, @refundTransactionId,
              'completed', NOW(), NOW())
      RETURNING id, payment_id, amount, reason, refunded_by,
                refund_transaction_id, status, created_at, updated_at
      ''',
      substitutionValues: {
        'paymentId': paymentId,
        'amount': amount,
        'reason': reason,
        'refundedBy': refundedBy,
        'refundTransactionId': refundTransactionId,
      },
    );

    return Refund.fromMap(result.first.asMap());
  }

  /// Get total payments count
  Future<int> getTotalPayments(DateTime startDate, DateTime endDate) async {
    final result = await db.query(
      '''
      SELECT COUNT(*) as count
      FROM payments
      WHERE created_at >= @startDate AND created_at <= @endDate
      ''',
      substitutionValues: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    return result.first[0] as int;
  }

  /// Get total payment amount
  Future<double> getTotalAmount(DateTime startDate, DateTime endDate) async {
    final result = await db.query(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM payments
      WHERE status = 'completed'
        AND created_at >= @startDate AND created_at <= @endDate
      ''',
      substitutionValues: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    return result.first[0] as double? ?? 0.0;
  }

  /// Get payments grouped by method
  Future<Map<String, dynamic>> getPaymentsByMethod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await db.query(
      '''
      SELECT payment_method, COUNT(*) as count, SUM(amount) as total_amount
      FROM payments
      WHERE status = 'completed'
        AND created_at >= @startDate AND created_at <= @endDate
      GROUP BY payment_method
      ''',
      substitutionValues: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    final paymentsByMethod = <String, dynamic>{};
    for (final row in result) {
      paymentsByMethod[row[0] as String] = {
        'count': row[1] as int,
        'total_amount': row[2] as double,
      };
    }

    return paymentsByMethod;
  }

  /// Save payment method for user
  Future<PaymentMethodInfo> savePaymentMethod({
    required int userId,
    required PaymentMethod method,
    required Map<String, dynamic> details,
    bool isDefault = false,
  }) async {
    // First, if this is set as default, remove default flag from other methods
    if (isDefault) {
      await db.query(
        'UPDATE saved_payment_methods SET is_default = false WHERE user_id = @userId',
        substitutionValues: {'userId': userId},
      );
    }

    final result = await db.query(
      '''
      INSERT INTO saved_payment_methods (
        user_id, payment_method, payment_details, is_default,
        created_at, updated_at
      )
      VALUES (@userId, @method, @details::jsonb, @isDefault, NOW(), NOW())
      RETURNING id, user_id, payment_method, payment_details, is_default,
                created_at, updated_at
      ''',
      substitutionValues: {
        'userId': userId,
        'method': method.name,
        'details': details,
        'isDefault': isDefault,
      },
    );

    return PaymentMethodInfo.fromMap(result.first.asMap());
  }

  /// Get user's saved payment methods
  Future<List<PaymentMethodInfo>> getUserSavedPaymentMethods(int userId) async {
    final result = await db.query(
      '''
      SELECT * FROM saved_payment_methods
      WHERE user_id = @userId
      ORDER BY is_default DESC, created_at DESC
      ''',
      substitutionValues: {'userId': userId},
    );

    return result.map((row) => PaymentMethodInfo.fromMap(row.asMap())).toList();
  }

  /// Find saved payment method by ID
  Future<PaymentMethodInfo?> findSavedPaymentMethodById(int id) async {
    final result = await db.query(
      'SELECT * FROM saved_payment_methods WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (result.isEmpty) return null;
    return PaymentMethodInfo.fromMap(result.first.asMap());
  }

  /// Delete saved payment method
  Future<bool> deleteSavedPaymentMethod(int id) async {
    final result = await db.query(
      'DELETE FROM saved_payment_methods WHERE id = @id',
      substitutionValues: {'id': id},
    );

    return result.affectedRowCount > 0;
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(int userId, int methodId) async {
    // First, remove default flag from all methods for this user
    await db.query(
      'UPDATE saved_payment_methods SET is_default = false WHERE user_id = @userId',
      substitutionValues: {'userId': userId},
    );

    // Set the specified method as default
    final result = await db.query(
      'UPDATE saved_payment_methods SET is_default = true WHERE id = @id AND user_id = @userId',
      substitutionValues: {'id': methodId, 'userId': userId},
    );

    return result.affectedRowCount > 0;
  }

  /// Get payment statistics for dashboard
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;

    final result = await db.query(
      '''
      SELECT
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_payments,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_payments,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
        COUNT(*) as total_payments,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN amount END), 0) as total_amount,
        COALESCE(AVG(CASE WHEN status = 'completed' THEN amount END), 0) as avg_payment_amount
      FROM payments
      WHERE created_at >= @startDate AND created_at <= @endDate
      ''',
      substitutionValues: {
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      },
    );

    final row = result.first;
    return {
      'completed_payments': row[0] as int,
      'pending_payments': row[1] as int,
      'failed_payments': row[2] as int,
      'total_payments': row[3] as int,
      'total_amount': row[4] as double,
      'avg_payment_amount': row[5] as double,
      'period': {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      },
    };
  }
}
