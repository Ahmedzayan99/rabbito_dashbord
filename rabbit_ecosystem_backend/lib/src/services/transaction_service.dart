import 'dart:async';
import 'package:rabbit_ecosystem_backend/src/models/payment.dart';

import '../repositories/transaction_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/order_repository.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/order.dart';

/// Service for transaction-related business logic
class TransactionService {
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;
  final OrderRepository _orderRepository;

  TransactionService(
    this._transactionRepository,
    this._userRepository,
    this._orderRepository,
  );

  /// Create a new transaction
  Future<Transaction> createTransaction(CreateTransactionRequest request) async {
    try {
      // Validate user exists
      final user = await _userRepository.findById(request.userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Validate order if provided
      if (request.orderId != null) {
        final order = await _orderRepository.findById(request.orderId!);
        if (order == null) {
          throw Exception('Order not found');
        }
      }

      // Validate amount
      if (request.amount <= 0) {
        throw Exception('Transaction amount must be positive');
      }

      // Additional validation based on transaction type
      switch (request.type) {
        case TransactionType.orderPayment:
          if (request.orderId == null) {
            throw Exception('Order ID is required for order payment transactions');
          }
          break;
        case TransactionType.walletTopup:
          if (request.paymentMethod == null) {
            throw Exception('Payment method is required for wallet topup');
          }
          break;
        case TransactionType.withdrawal:
          // Check user balance (would need wallet service)
          break;
        case TransactionType.commission:
        case TransactionType.refund:
          // These are usually created internally
          break;
      }

      return await _transactionRepository.create(request.toJson());
    } catch (e) {
      throw Exception('Failed to create transaction: ${e.toString()}');
    }
  }

  /// Get transaction by ID
  Future<Transaction?> getTransactionById(int id) async {
    return await _transactionRepository.findById(id);
  }

  /// Get transaction by UUID
  Future<Transaction?> getTransactionByUuid(String uuid) async {
    return await _transactionRepository.findByUuid(uuid);
  }

  /// Get user transactions
  Future<List<Transaction>> getUserTransactions(
    int userId, {
    int? limit,
    int? offset,
    TransactionFilter? filter,
  }) async {
    return await _transactionRepository.findByUserId(
      userId,
      limit: limit,
      offset: offset,
      filter: filter,
    );
  }

  /// Get transactions by order ID
  Future<List<Transaction>> getTransactionsByOrderId(int orderId) async {
    return await _transactionRepository.findByOrderId(orderId);
  }

  /// Get all transactions (admin)
  Future<List<Transaction>> getAllTransactions({
    TransactionFilter? filter,
    int? limit,
    int? offset,
  }) async {
    return await _transactionRepository.findAllWithFilters(
      filter: filter,
      limit: limit,
      offset: offset,
    );
  }

  /// Count transactions with filters
  Future<int> getTransactionCount(TransactionFilter? filter) async {
    return await _transactionRepository.countWithFilters(filter);
  }

  /// Update transaction status
  Future<Transaction?> updateTransactionStatus(int id, TransactionStatus status) async {
    try {
      final transaction = await _transactionRepository.findById(id);
      if (transaction == null) {
        return null;
      }

      // Validate status transition
      if (!_isValidStatusTransition(transaction.status, status)) {
        throw Exception('Invalid status transition from ${transaction.status} to $status');
      }

      final updatedTransaction = await _transactionRepository.updateStatus(id, status);

      if (updatedTransaction != null) {
        // Handle side effects based on status change
        if (status.isCompleted) {
          await _handleTransactionCompleted(updatedTransaction);
        } else if (status.isFailed) {
          await _handleTransactionFailed(updatedTransaction);
        }
      }

      return updatedTransaction;
    } catch (e) {
      throw Exception('Failed to update transaction status: ${e.toString()}');
    }
  }

  /// Process payment for order
  Future<Transaction> processOrderPayment({
    required int orderId,
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    final request = CreateTransactionRequest(
      userId: userId,
      orderId: orderId,
      type: TransactionType.orderPayment,
      amount: amount,
      paymentMethod: paymentMethod,
      description: description ?? 'Payment for order #$orderId',
      referenceId: 'order_payment_$orderId',
    );

    final transaction = await createTransaction(request);

    // In a real implementation, this would integrate with payment gateway
    // For now, we'll simulate successful payment processing
    await updateTransactionStatus(transaction.id, TransactionStatus.completed);

    return transaction;
  }

  /// Process wallet topup
  Future<Transaction> processWalletTopup({
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    final request = CreateTransactionRequest(
      userId: userId,
      type: TransactionType.walletTopup,
      amount: amount,
      paymentMethod: paymentMethod,
      description: description ?? 'Wallet topup',
      referenceId: 'wallet_topup_${DateTime.now().millisecondsSinceEpoch}',
    );

    final transaction = await createTransaction(request);

    // In a real implementation, this would integrate with payment gateway
    // For now, we'll simulate successful payment processing
    await updateTransactionStatus(transaction.id, TransactionStatus.completed);

    return transaction;
  }

  /// Process withdrawal
  Future<Transaction> processWithdrawal({
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    // Validate user has sufficient balance (would need wallet service)
    // For now, assume balance check passes

    final request = CreateTransactionRequest(
      userId: userId,
      type: TransactionType.withdrawal,
      amount: amount,
      paymentMethod: paymentMethod,
      description: description ?? 'Wallet withdrawal',
      referenceId: 'withdrawal_${DateTime.now().millisecondsSinceEpoch}',
    );

    final transaction = await createTransaction(request);

    // In a real implementation, this would process the withdrawal through payment gateway
    // For now, we'll simulate successful processing
    await updateTransactionStatus(transaction.id, TransactionStatus.completed);

    return transaction;
  }

  /// Process refund
  Future<Transaction> processRefund({
    required int orderId,
    required int userId,
    required double refundAmount,
    required String reason,
  }) async {
    return await _transactionRepository.createRefundTransaction(
      orderId: orderId,
      userId: userId,
      refundAmount: refundAmount,
      reason: reason,
    );
  }

  /// Process payment distribution for completed order
  Future<void> processPaymentDistribution(int orderId) async {
    try {
      await _transactionRepository.processPaymentDistribution(orderId);
    } catch (e) {
      throw Exception('Failed to process payment distribution: ${e.toString()}');
    }
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _transactionRepository.getTransactionStatistics(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get transaction summary by type
  Future<Map<String, dynamic>> getTransactionSummaryByType({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _transactionRepository.getTransactionSummaryByType(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get monthly transaction summary
  Future<List<Map<String, dynamic>>> getMonthlyTransactionSummary({
    int? userId,
    int? year,
  }) async {
    return await _transactionRepository.getMonthlyTransactionSummary(
      userId: userId,
      year: year,
    );
  }

  /// Validate status transition
  bool _isValidStatusTransition(TransactionStatus current, TransactionStatus next) {
    switch (current) {
      case TransactionStatus.pending:
        return [TransactionStatus.processing, TransactionStatus.completed, TransactionStatus.failed, TransactionStatus.cancelled].contains(next);
      case TransactionStatus.processing:
        return [TransactionStatus.completed, TransactionStatus.failed].contains(next);
      case TransactionStatus.completed:
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return false; // Terminal states
      default:
        return false;
    }
  }

  /// Handle transaction completion
  Future<void> _handleTransactionCompleted(Transaction transaction) async {
    switch (transaction.type) {
      case TransactionType.orderPayment:
        // Process payment distribution for order
        if (transaction.orderId != null) {
          await processPaymentDistribution(transaction.orderId!);
        }
        break;
      case TransactionType.walletTopup:
        // Update user wallet balance (would need wallet service)
        break;
      case TransactionType.withdrawal:
        // Update user wallet balance (would need wallet service)
        break;
      case TransactionType.commission:
        // Update partner wallet balance (would need wallet service)
        break;
      case TransactionType.refund:
        // Update user wallet balance (would need wallet service)
        break;
    }
  }

  /// Handle transaction failure
  Future<void> _handleTransactionFailed(Transaction transaction) async {
    // Log failure and potentially trigger notifications
    // In a real implementation, this might trigger refund processes or user notifications
  }

  /// Get pending transactions for processing
  Future<List<Transaction>> getPendingTransactions({int? limit}) async {
    final filter = TransactionFilter(status: TransactionStatus.pending);
    return await getAllTransactions(
      filter: filter,
      limit: limit ?? 50,
    );
  }

  /// Process pending transactions (batch processing)
  Future<void> processPendingTransactions() async {
    final pendingTransactions = await getPendingTransactions();

    for (final transaction in pendingTransactions) {
      try {
        // In a real implementation, this would integrate with payment gateways
        // For now, we'll just mark them as completed
        await updateTransactionStatus(transaction.id, TransactionStatus.completed);
      } catch (e) {
        // Log error and continue processing other transactions
        print('Failed to process transaction ${transaction.id}: $e');
      }
    }
  }

  /// Get transaction analytics for dashboard
  Future<Map<String, dynamic>> getTransactionAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final stats = await getTransactionStatistics(
      startDate: startDate,
      endDate: endDate,
    );

    final summaryByType = await getTransactionSummaryByType(
      startDate: startDate,
      endDate: endDate,
    );

    final monthlySummary = await getMonthlyTransactionSummary();

    return {
      'statistics': stats,
      'summary_by_type': summaryByType,
      'monthly_summary': monthlySummary,
    };
  }
}

