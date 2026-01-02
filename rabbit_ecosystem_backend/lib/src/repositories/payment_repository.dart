import 'package:postgres/postgres.dart';
import 'base_repository.dart';
import '../models/payment.dart';

/// Repository for payment-related database operations
class PaymentRepository extends BaseRepository<Payment> {
  PaymentRepository(super.connection);

  @override
  String get tableName => 'payments';

  @override
  Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      userId: map['user_id'] as int,
      amount: map['amount'] as double,
      paymentMethod: PaymentMethod.fromString(map['payment_method'] as String),
      transactionId: map['transaction_id'] as String,
      status: PaymentStatus.fromString(map['status'] as String),
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Payment payment) {
    return {
      'order_id': payment.orderId,
      'user_id': payment.userId,
      'amount': payment.amount,
      'payment_method': payment.paymentMethod.value,
      'transaction_id': payment.transactionId,
      'status': payment.status.value,
      'paid_at': payment.paidAt?.toIso8601String(),
      'created_at': payment.createdAt.toIso8601String(),
      'updated_at': payment.updatedAt?.toIso8601String(),
    };
  }
  /// Create new payment
  Future<Payment> createPayment({
    required int orderId,
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required String transactionId,
    PaymentStatus status = PaymentStatus.pending,
  }) async {
    final result = await connection.execute(
      '''
      INSERT INTO payments (
        order_id, user_id, amount, payment_method, transaction_id,
        status, created_at, updated_at
      )
      VALUES (\$1, \$2, \$3, \$4, \$5,
              \$6, NOW(), NOW())
      RETURNING id, order_id, user_id, amount, payment_method,
                transaction_id, status, created_at, updated_at
      ''',
      parameters: [
        orderId,
        userId,
        amount,
        paymentMethod.value,
        transactionId,
        status.value,
      ],
    );

    return Payment.fromMap(result.first.toColumnMap());
  }

  /// Find payment by ID
  Future<Payment?> findById(int id) async {
    final result = await connection.execute(
      '''
      SELECT p.*, o.uuid as order_uuid, u.username, u.mobile
      FROM payments p
      LEFT JOIN orders o ON p.order_id = o.id
      LEFT JOIN users u ON p.user_id = u.id
      WHERE p.id = \$1
      ''',
      parameters: [id],
    );

    if (result.isEmpty) return null;
    return Payment.fromMap(result.first.toColumnMap());
  }

  /// Find payment by transaction ID
  Future<Payment?> findByTransactionId(String transactionId) async {
    final result = await connection.execute(
      'SELECT * FROM payments WHERE transaction_id = \$1',
      parameters: [transactionId],
    );

    if (result.isEmpty) return null;
    return Payment.fromMap(result.first.toColumnMap());
  }

  /// Find payments by user ID
  Future<List<Payment>> findByUserId(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    final parameters = [userId];
    var paramIndex = 2;

    var query = '''
      SELECT p.*, o.uuid as order_uuid
      FROM payments p
      LEFT JOIN orders o ON p.order_id = o.id
      WHERE p.user_id = \$1
      ORDER BY p.created_at DESC
    ''';

    if (limit != null) {
      query += ' LIMIT \$${paramIndex}';
      parameters.add(limit);
      paramIndex++;
    }

    if (offset != null) {
      query += ' OFFSET \$${paramIndex}';
      parameters.add(offset);
    }

    final result = await connection.execute(query, parameters: parameters);

    return result.map((row) => Payment.fromMap(row.toColumnMap())).toList();
  }

  /// Find payments by status
  Future<List<Payment>> findByStatus(
    PaymentStatus status, {
    int? limit,
    int? offset,
  }) async {
    final parameters = <dynamic>[status.value];
    var paramIndex = 2;

    var query = '''
      SELECT p.*, u.username, u.mobile, o.uuid as order_uuid
      FROM payments p
      LEFT JOIN users u ON p.user_id = u.id
      LEFT JOIN orders o ON p.order_id = o.id
      WHERE p.status = \$1
      ORDER BY p.created_at DESC
    ''';

    if (limit != null) {
      query += ' LIMIT \$${paramIndex}';
      parameters.add(limit);
      paramIndex++;
    }

    if (offset != null) {
      query += ' OFFSET \$${paramIndex}';
      parameters.add(offset);
    }

    final result = await connection.execute(query, parameters: parameters);

    return result.map((row) => Payment.fromMap(row.toColumnMap())).toList();
  }

  /// Update payment status
  Future<Payment?> updatePaymentStatus(int paymentId, PaymentStatus status) async {
    final result = await connection.execute(
      '''
      UPDATE payments
      SET status = \$2, updated_at = NOW()
      WHERE id = \$1
      RETURNING id, order_id, user_id, amount, payment_method,
                transaction_id, status, created_at, updated_at
      ''',
      parameters: [paymentId, status.value],
    );

    if (result.isEmpty) return null;
    return Payment.fromMap(result.first.toColumnMap());
  }

  /// Create refund record
  Future<Refund> createRefund({
    required int paymentId,
    required double amount,
    String? reason,
    required int refundedBy,
    required String refundTransactionId,
  }) async {
    final result = await connection.execute(
      '''
      INSERT INTO refunds (
        payment_id, amount, reason, refunded_by, refund_transaction_id,
        status, created_at, updated_at
      )
      VALUES (\$1, \$2, \$3, \$4, \$5,
              'completed', NOW(), NOW())
      RETURNING id, payment_id, amount, reason, refunded_by,
                refund_transaction_id, status, created_at, updated_at
      ''',
      parameters: [
        paymentId,
        amount,
        reason,
        refundedBy,
        refundTransactionId,
      ],
    );

    return Refund.fromMap(result.first.toColumnMap());
  }

  /// Get total payments count
  Future<int> getTotalPayments(DateTime startDate, DateTime endDate) async {
    final result = await connection.execute(
      '''
      SELECT COUNT(*) as count
      FROM payments
      WHERE created_at >= \$1 AND created_at <= \$2
      ''',
      parameters: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return result.first[0] as int;
  }

  /// Get total payment amount
  Future<double> getTotalAmount(DateTime startDate, DateTime endDate) async {
    final result = await connection.execute(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM payments
      WHERE status = 'completed'
        AND created_at >= \$1 AND created_at <= \$2
      ''',
      parameters: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return result.first[0] as double? ?? 0.0;
  }

  /// Get payments grouped by method
  Future<Map<String, dynamic>> getPaymentsByMethod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await connection.execute(
      '''
      SELECT payment_method, COUNT(*) as count, SUM(amount) as total_amount
      FROM payments
      WHERE status = 'completed'
        AND created_at >= \$1 AND created_at <= \$2
      GROUP BY payment_method
      ''',
      parameters: [startDate.toIso8601String(), endDate.toIso8601String()],
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
      await connection.execute(
        'UPDATE saved_payment_methods SET is_default = false WHERE user_id = \$1',
        parameters: [userId],
      );
    }

    final result = await connection.execute(
      '''
      INSERT INTO saved_payment_methods (
        user_id, payment_method, payment_details, is_default,
        created_at, updated_at
      )
      VALUES (\$1, \$2, \$3, \$4, NOW(), NOW())
      RETURNING id, user_id, payment_method, payment_details, is_default,
                created_at, updated_at
      ''',
      parameters: [
        userId,
        method.value,
        details,
        isDefault,
      ],
    );

    return PaymentMethodInfo.fromMap(result.first.toColumnMap());
  }

  /// Get user's saved payment methods
  Future<List<PaymentMethodInfo>> getUserSavedPaymentMethods(int userId) async {
    final result = await connection.execute(
      '''
      SELECT * FROM saved_payment_methods
      WHERE user_id = \$1
      ORDER BY is_default DESC, created_at DESC
      ''',
      parameters: [userId],
    );

    return result.map((row) => PaymentMethodInfo.fromMap(row.toColumnMap())).toList();
  }

  /// Find saved payment method by ID
  Future<PaymentMethodInfo?> findSavedPaymentMethodById(int id) async {
    final result = await connection.execute(
      'SELECT * FROM saved_payment_methods WHERE id = \$1',
      parameters: [id],
    );

    if (result.isEmpty) return null;
    return PaymentMethodInfo.fromMap(result.first.toColumnMap());
  }

  /// Delete saved payment method
  Future<bool> deleteSavedPaymentMethod(int id) async {
    final result = await connection.execute(
      'DELETE FROM saved_payment_methods WHERE id = \$1',
      parameters: [id],
    );

    return result.affectedRows > 0;
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(int userId, int methodId) async {
    // First, remove default flag from all methods for this user
    await connection.execute(
      'UPDATE saved_payment_methods SET is_default = false WHERE user_id = \$1',
      parameters: [userId],
    );

    // Set the specified method as default
    final result = await connection.execute(
      'UPDATE saved_payment_methods SET is_default = true WHERE id = \$1 AND user_id = \$2',
      parameters: [methodId, userId],
    );

    return result.affectedRows > 0;
  }

  /// Get payment statistics for dashboard
  Future<Map<String, dynamic>> getPaymentStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? now;

    final result = await connection.execute(
      '''
      SELECT
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_payments,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_payments,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
        COUNT(*) as total_payments,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN amount END), 0) as total_amount,
        COALESCE(AVG(CASE WHEN status = 'completed' THEN amount END), 0) as avg_payment_amount
      FROM payments
      WHERE created_at >= \$1 AND created_at <= \$2
      ''',
      parameters: [start.toIso8601String(), end.toIso8601String()],
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
