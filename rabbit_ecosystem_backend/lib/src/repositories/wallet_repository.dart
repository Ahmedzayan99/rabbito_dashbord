import 'dart:async';
import 'package:postgres/postgres.dart';
import '../models/transaction.dart';
import 'base_repository.dart';

class WalletRepository extends BaseRepository {
  WalletRepository(PostgreSQLConnection connection) : super(connection);

  /// Get user wallet balance
  Future<double> getBalance(int userId) async {
    final result = await executeQuery('''
      SELECT balance FROM users WHERE id = @user_id
    ''', parameters: {'user_id': userId});

    if (result.isEmpty) {
      throw Exception('User not found');
    }

    return result.first['balance'] as double;
  }

  /// Update user wallet balance
  Future<double> updateBalance(int userId, double newBalance) async {
    final result = await executeQuery('''
      UPDATE users
      SET balance = @balance, updated_at = CURRENT_TIMESTAMP
      WHERE id = @user_id
      RETURNING balance
    ''', parameters: {
      'user_id': userId,
      'balance': newBalance,
    });

    if (result.isEmpty) {
      throw Exception('User not found');
    }

    return result.first['balance'] as double;
  }

  /// Add amount to user wallet
  Future<double> addToBalance(int userId, double amount) async {
    if (amount <= 0) {
      throw Exception('Amount must be positive');
    }

    final result = await executeQuery('''
      UPDATE users
      SET balance = balance + @amount, updated_at = CURRENT_TIMESTAMP
      WHERE id = @user_id
      RETURNING balance
    ''', parameters: {
      'user_id': userId,
      'amount': amount,
    });

    if (result.isEmpty) {
      throw Exception('User not found');
    }

    return result.first['balance'] as double;
  }

  /// Subtract amount from user wallet
  Future<double> subtractFromBalance(int userId, double amount) async {
    if (amount <= 0) {
      throw Exception('Amount must be positive');
    }

    final result = await executeQuery('''
      UPDATE users
      SET balance = balance - @amount, updated_at = CURRENT_TIMESTAMP
      WHERE id = @user_id AND balance >= @amount
      RETURNING balance
    ''', parameters: {
      'user_id': userId,
      'amount': amount,
    });

    if (result.isEmpty) {
      throw Exception('Insufficient balance or user not found');
    }

    return result.first['balance'] as double;
  }

  /// Get wallet transaction history
  Future<List<Transaction>> getTransactionHistory(
    int userId, {
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
    }

    final whereClause = 'WHERE ${conditions.join(' AND ')}';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await executeQuery('''
      SELECT t.*
      FROM transactions t
      $whereClause
      ORDER BY t.created_at DESC
      $limitClause $offsetClause
    ''', parameters: parameters);

    return result.map((row) => Transaction.fromJson(row)).toList();
  }

  /// Get wallet summary for user
  Future<Map<String, dynamic>> getWalletSummary(int userId) async {
    final balanceResult = await executeQuery('''
      SELECT balance FROM users WHERE id = @user_id
    ''', parameters: {'user_id': userId});

    if (balanceResult.isEmpty) {
      throw Exception('User not found');
    }

    final currentBalance = balanceResult.first['balance'] as double;

    final transactionsResult = await executeQuery('''
      SELECT
        COUNT(*) as total_transactions,
        COUNT(CASE WHEN type IN ('wallet_topup', 'commission', 'refund') THEN 1 END) as credits,
        COUNT(CASE WHEN type IN ('order_payment', 'withdrawal') THEN 1 END) as debits,
        COALESCE(SUM(CASE WHEN type IN ('wallet_topup', 'commission', 'refund') THEN amount END), 0) as total_credits,
        COALESCE(SUM(CASE WHEN type IN ('order_payment', 'withdrawal') THEN amount END), 0) as total_debits
      FROM transactions
      WHERE user_id = @user_id AND status = 'completed'
    ''', parameters: {'user_id': userId});

    final stats = transactionsResult.first;

    return {
      'current_balance': currentBalance,
      'total_transactions': stats['total_transactions'],
      'total_credits': stats['total_credits'],
      'total_debits': stats['total_debits'],
      'available_balance': currentBalance,
    };
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(int userId, double amount) async {
    final result = await executeQuery('''
      SELECT balance FROM users WHERE id = @user_id
    ''', parameters: {'user_id': userId});

    if (result.isEmpty) {
      return false;
    }

    final balance = result.first['balance'] as double;
    return balance >= amount;
  }

  /// Get wallet statistics for admin
  Future<Map<String, dynamic>> getWalletStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (startDate != null) {
      conditions.add('created_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('created_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    // Get total wallet balances
    final balanceResult = await executeQuery('''
      SELECT
        COUNT(*) as total_users_with_wallet,
        SUM(balance) as total_wallet_balance,
        AVG(balance) as average_wallet_balance,
        MIN(balance) as min_wallet_balance,
        MAX(balance) as max_wallet_balance
      FROM users
      WHERE balance > 0
    ''');

    // Get transaction statistics
    final transactionResult = await executeQuery('''
      SELECT
        COUNT(*) as total_wallet_transactions,
        COUNT(CASE WHEN type = 'wallet_topup' THEN 1 END) as total_topups,
        COUNT(CASE WHEN type = 'withdrawal' THEN 1 END) as total_withdrawals,
        COALESCE(SUM(CASE WHEN type = 'wallet_topup' THEN amount END), 0) as total_topup_amount,
        COALESCE(SUM(CASE WHEN type = 'withdrawal' THEN amount END), 0) as total_withdrawal_amount
      FROM transactions
      $whereClause
    ''', parameters: parameters);

    final balanceStats = balanceResult.first;
    final transactionStats = transactionResult.first;

    return {
      'wallet_statistics': balanceStats,
      'transaction_statistics': transactionStats,
    };
  }

  /// Get users with low wallet balance (for notifications)
  Future<List<Map<String, dynamic>>> getUsersWithLowBalance(double threshold) async {
    final result = await executeQuery('''
      SELECT id, username, email, mobile, balance
      FROM users
      WHERE balance < @threshold AND balance > 0 AND is_active = true
      ORDER BY balance ASC
    ''', parameters: {'threshold': threshold});

    return result;
  }

  /// Transfer money between users (admin function)
  Future<void> transferBetweenUsers({
    required int fromUserId,
    required int toUserId,
    required double amount,
    String? description,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be positive');
    }

    // Check if sender has sufficient balance
    final hasBalance = await hasSufficientBalance(fromUserId, amount);
    if (!hasBalance) {
      throw Exception('Insufficient balance');
    }

    // Start transaction
    await connection.execute('BEGIN');

    try {
      // Subtract from sender
      await subtractFromBalance(fromUserId, amount);

      // Add to receiver
      await addToBalance(toUserId, amount);

      // Log the transfer (you might want to create transfer records)
      // This could be enhanced with a transfer transaction record

      await connection.execute('COMMIT');
    } catch (e) {
      await connection.execute('ROLLBACK');
      throw Exception('Transfer failed: ${e.toString()}');
    }
  }

  /// Reset wallet balance (admin function)
  Future<double> resetBalance(int userId) async {
    final result = await executeQuery('''
      UPDATE users
      SET balance = 0, updated_at = CURRENT_TIMESTAMP
      WHERE id = @user_id
      RETURNING balance
    ''', parameters: {'user_id': userId});

    if (result.isEmpty) {
      throw Exception('User not found');
    }

    return result.first['balance'] as double;
  }

  /// Get wallet activity summary by period
  Future<List<Map<String, dynamic>>> getWalletActivityByPeriod({
    required String period, // 'daily', 'weekly', 'monthly'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dateFormat = switch (period) {
      'daily' => "DATE(created_at)",
      'weekly' => "DATE_TRUNC('week', created_at)",
      'monthly' => "DATE_TRUNC('month', created_at)",
      _ => "DATE(created_at)",
    };

    final conditions = <String>[];
    final parameters = <String, dynamic>{};

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
        $dateFormat as period,
        COUNT(*) as total_transactions,
        COUNT(CASE WHEN type = 'wallet_topup' THEN 1 END) as topups,
        COUNT(CASE WHEN type = 'withdrawal' THEN 1 END) as withdrawals,
        COALESCE(SUM(CASE WHEN type = 'wallet_topup' THEN amount END), 0) as topup_amount,
        COALESCE(SUM(CASE WHEN type = 'withdrawal' THEN amount END), 0) as withdrawal_amount
      FROM transactions
      $whereClause
      GROUP BY $dateFormat
      ORDER BY period DESC
      LIMIT 30
    ''', parameters: parameters);

    return result;
  }
}
