import 'dart:async';
import 'package:postgres/postgres.dart';
import '../models/transaction.dart';
import 'base_repository.dart';

class TransactionRepository extends BaseRepository {
  TransactionRepository(PostgreSQLConnection connection) : super(connection);

  /// Create a new transaction
  Future<Transaction> create(CreateTransactionRequest request) async {
    final uuid = generateUuid();
    final result = await executeQuery('''
      INSERT INTO transactions (
        uuid, user_id, order_id, type, amount, description,
        reference_id, payment_method, status, created_at
      )
      VALUES (
        @uuid, @user_id, @order_id, @type, @amount, @description,
        @reference_id, @payment_method, @status, CURRENT_TIMESTAMP
      )
      RETURNING *
    ''', parameters: {
      'uuid': uuid,
      'user_id': request.userId,
      'order_id': request.orderId,
      'type': request.type.value,
      'amount': request.amount,
      'description': request.description,
      'reference_id': request.referenceId,
      'payment_method': request.paymentMethod?.name,
      'status': TransactionStatus.pending.value,
    });

    if (result.isEmpty) {
      throw Exception('Failed to create transaction');
    }

    return Transaction.fromJson(result.first);
  }

  /// Find transaction by ID
  Future<Transaction?> findById(int id) async {
    final result = await executeQuery('''
      SELECT t.*, u.username as user_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE t.id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) {
      return null;
    }

    return Transaction.fromJson(result.first);
  }

  /// Find transaction by UUID
  Future<Transaction?> findByUuid(String uuid) async {
    final result = await executeQuery('''
      SELECT t.*, u.username as user_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE t.uuid = @uuid
    ''', parameters: {'uuid': uuid});

    if (result.isEmpty) {
      return null;
    }

    return Transaction.fromJson(result.first);
  }

  /// Find transactions by user ID
  Future<List<Transaction>> findByUserId(int userId, {
    int? limit,
    int? offset,
    TransactionFilter? filter,
  }) async {
    final conditions = <String>['t.user_id = @user_id'];
    final parameters = <String, dynamic>{'user_id': userId};

    if (filter != null) {
      if (filter.type != null) {
        conditions.add('t.type = @type');
        parameters['type'] = filter.type!.value;
      }

      if (filter.status != null) {
        conditions.add('t.status = @status');
        parameters['status'] = filter.status!.value;
      }

      if (filter.startDate != null) {
        conditions.add('t.created_at >= @start_date');
        parameters['start_date'] = filter.startDate!.toIso8601String();
      }

      if (filter.endDate != null) {
        conditions.add('t.created_at <= @end_date');
        parameters['end_date'] = filter.endDate!.toIso8601String();
      }

      if (filter.minAmount != null) {
        conditions.add('t.amount >= @min_amount');
        parameters['min_amount'] = filter.minAmount!;
      }

      if (filter.maxAmount != null) {
        conditions.add('t.amount <= @max_amount');
        parameters['max_amount'] = filter.maxAmount!;
      }
    }

    final whereClause = 'WHERE ${conditions.join(' AND ')}';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await executeQuery('''
      SELECT t.*, u.username as user_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      $whereClause
      ORDER BY t.created_at DESC
      $limitClause $offsetClause
    ''', parameters: parameters);

    return result.map((row) => Transaction.fromJson(row)).toList();
  }

  /// Find transactions by order ID
  Future<List<Transaction>> findByOrderId(int orderId) async {
    final result = await executeQuery('''
      SELECT t.*, u.username as user_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE t.order_id = @order_id
      ORDER BY t.created_at DESC
    ''', parameters: {'order_id': orderId});

    return result.map((row) => Transaction.fromJson(row)).toList();
  }

  /// Update transaction status
  Future<Transaction?> updateStatus(int id, TransactionStatus status) async {
    final processedAt = status.isCompleted ? 'CURRENT_TIMESTAMP' : null;

    final result = await executeQuery('''
      UPDATE transactions
      SET status = @status, processed_at = $processedAt, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
      RETURNING *
    ''', parameters: {
      'id': id,
      'status': status.value,
    });

    if (result.isEmpty) {
      return null;
    }

    return Transaction.fromJson(result.first);
  }

  /// Get transactions with filters (admin)
  Future<List<Transaction>> findAllWithFilters({
    TransactionFilter? filter,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (filter != null) {
      if (filter.userId != null) {
        conditions.add('t.user_id = @user_id');
        parameters['user_id'] = filter.userId!;
      }

      if (filter.type != null) {
        conditions.add('t.type = @type');
        parameters['type'] = filter.type!.value;
      }

      if (filter.status != null) {
        conditions.add('t.status = @status');
        parameters['status'] = filter.status!.value;
      }

      if (filter.startDate != null) {
        conditions.add('t.created_at >= @start_date');
        parameters['start_date'] = filter.startDate!.toIso8601String();
      }

      if (filter.endDate != null) {
        conditions.add('t.created_at <= @end_date');
        parameters['end_date'] = filter.endDate!.toIso8601String();
      }

      if (filter.minAmount != null) {
        conditions.add('t.amount >= @min_amount');
        parameters['min_amount'] = filter.minAmount!;
      }

      if (filter.maxAmount != null) {
        conditions.add('t.amount <= @max_amount');
        parameters['max_amount'] = filter.maxAmount!;
      }
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await executeQuery('''
      SELECT t.*, u.username as user_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      $whereClause
      ORDER BY t.created_at DESC
      $limitClause $offsetClause
    ''', parameters: parameters);

    return result.map((row) => Transaction.fromJson(row)).toList();
  }

  /// Count transactions with filters
  Future<int> countWithFilters(TransactionFilter? filter) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (filter != null) {
      if (filter.userId != null) {
        conditions.add('user_id = @user_id');
        parameters['user_id'] = filter.userId!;
      }

      if (filter.type != null) {
        conditions.add('type = @type');
        parameters['type'] = filter.type!.value;
      }

      if (filter.status != null) {
        conditions.add('status = @status');
        parameters['status'] = filter.status!.value;
      }

      if (filter.startDate != null) {
        conditions.add('created_at >= @start_date');
        parameters['start_date'] = filter.startDate!.toIso8601String();
      }

      if (filter.endDate != null) {
        conditions.add('created_at <= @end_date');
        parameters['end_date'] = filter.endDate!.toIso8601String();
      }

      if (filter.minAmount != null) {
        conditions.add('amount >= @min_amount');
        parameters['min_amount'] = filter.minAmount!;
      }

      if (filter.maxAmount != null) {
        conditions.add('amount <= @max_amount');
        parameters['max_amount'] = filter.maxAmount!;
      }
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT COUNT(*) as count FROM transactions
      $whereClause
    ''', parameters: parameters);

    return result.first['count'] as int;
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (userId != null) {
      conditions.add('user_id = @user_id');
      parameters['user_id'] = userId;
    }

    if (startDate != null) {
      conditions.add('created_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('created_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT
        COUNT(*) as total_transactions,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_transactions,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_transactions,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_transactions,
        SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as total_amount,
        AVG(CASE WHEN status = 'completed' THEN amount ELSE NULL END) as average_amount,
        MIN(CASE WHEN status = 'completed' THEN amount ELSE NULL END) as min_amount,
        MAX(CASE WHEN status = 'completed' THEN amount ELSE NULL END) as max_amount
      FROM transactions
      $whereClause
    ''', parameters: parameters);

    return result.first;
  }

  /// Get transaction summary by type
  Future<Map<String, dynamic>> getTransactionSummaryByType({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (userId != null) {
      conditions.add('user_id = @user_id');
      parameters['user_id'] = userId;
    }

    if (startDate != null) {
      conditions.add('created_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('created_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT
        type,
        COUNT(*) as count,
        SUM(amount) as total_amount,
        AVG(amount) as average_amount
      FROM transactions
      $whereClause
      GROUP BY type
      ORDER BY total_amount DESC
    ''', parameters: parameters);

    return {'summary': result};
  }

  /// Get monthly transaction summary
  Future<List<Map<String, dynamic>>> getMonthlyTransactionSummary({
    int? userId,
    int? year,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (userId != null) {
      conditions.add('user_id = @user_id');
      parameters['user_id'] = userId;
    }

    if (year != null) {
      conditions.add('EXTRACT(year FROM created_at) = @year');
      parameters['year'] = year;
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT
        EXTRACT(month FROM created_at) as month,
        EXTRACT(year FROM created_at) as year,
        COUNT(*) as total_transactions,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_transactions,
        SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as total_amount
      FROM transactions
      $whereClause
      GROUP BY EXTRACT(year FROM created_at), EXTRACT(month FROM created_at)
      ORDER BY year DESC, month DESC
      LIMIT 12
    ''', parameters: parameters);

    return result;
  }

  /// Process commission for order
  Future<Transaction> createCommissionTransaction({
    required int orderId,
    required int partnerId,
    required double commissionAmount,
    required double platformFee,
  }) async {
    // Create commission transaction for partner
    final commissionRequest = CreateTransactionRequest(
      userId: partnerId,
      orderId: orderId,
      type: TransactionType.commission,
      amount: commissionAmount,
      description: 'Commission for order #$orderId',
      referenceId: 'commission_$orderId',
    );

    final commissionTransaction = await create(commissionRequest);

    // Mark commission as completed
    await updateStatus(commissionTransaction.id, TransactionStatus.completed);

    return commissionTransaction;
  }

  /// Process refund
  Future<Transaction> createRefundTransaction({
    required int orderId,
    required int userId,
    required double refundAmount,
    required String reason,
  }) async {
    final refundRequest = CreateTransactionRequest(
      userId: userId,
      orderId: orderId,
      type: TransactionType.refund,
      amount: refundAmount,
      description: 'Refund for order #$orderId: $reason',
      referenceId: 'refund_$orderId',
    );

    final refundTransaction = await create(refundRequest);

    // Mark refund as completed
    await updateStatus(refundTransaction.id, TransactionStatus.completed);

    return refundTransaction;
  }

  /// Process payment distribution for completed order
  Future<void> processPaymentDistribution(int orderId) async {
    // Get order details
    final orderResult = await executeQuery('''
      SELECT o.*, p.user_id as partner_user_id
      FROM orders o
      JOIN partners p ON o.partner_id = p.id
      WHERE o.id = @order_id
    ''', parameters: {'order_id': orderId});

    if (orderResult.isEmpty) {
      throw Exception('Order not found');
    }

    final order = orderResult.first;
    final partnerUserId = order['partner_user_id'] as int;
    final orderAmount = order['total_amount'] as double;

    // Calculate commission and platform fee
    // Assuming 10% commission for partner, 5% platform fee
    final commissionRate = 0.10; // 10%
    final platformFeeRate = 0.05; // 5%

    final commissionAmount = orderAmount * commissionRate;
    final platformFee = orderAmount * platformFeeRate;
    final partnerRevenue = commissionAmount;

    // Create commission transaction
    await createCommissionTransaction(
      orderId: orderId,
      partnerId: partnerUserId,
      commissionAmount: partnerRevenue,
      platformFee: platformFee,
    );

    // Log platform fee (this could be used for accounting)
    // await _accountingService.recordPlatformFee(orderId, platformFee);
  }
}
