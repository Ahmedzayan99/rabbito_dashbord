import 'dart:async';
import '../repositories/wallet_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/user.dart';
import '../models/transaction.dart';

/// Service for wallet-related business logic
class WalletService {
  final WalletRepository _walletRepository;
  final UserRepository _userRepository;
  final TransactionRepository _transactionRepository;

  WalletService(
    this._walletRepository,
    this._userRepository,
    this._transactionRepository,
  );

  /// Get user wallet balance
  Future<double> getBalance(int userId) async {
    try {
      return await _walletRepository.getBalance(userId);
    } catch (e) {
      throw Exception('Failed to get wallet balance: ${e.toString()}');
    }
  }

  /// Get wallet summary for user
  Future<Map<String, dynamic>> getWalletSummary(int userId) async {
    try {
      return await _walletRepository.getWalletSummary(userId);
    } catch (e) {
      throw Exception('Failed to get wallet summary: ${e.toString()}');
    }
  }

  /// Add money to wallet (topup)
  Future<double> addMoney({
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be positive');
      }

      // Validate user exists
      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Create transaction first
      final transaction = await _transactionRepository.create(CreateTransactionRequest(
        userId: userId,
        type: TransactionType.walletTopup,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description ?? 'Wallet topup',
        referenceId: 'wallet_topup_${DateTime.now().millisecondsSinceEpoch}',
      ));

      // In a real implementation, this would integrate with payment gateway
      // For now, we'll simulate successful payment and update balance
      await _walletRepository.addToBalance(userId, amount);

      // Mark transaction as completed
      await _transactionRepository.updateStatus(transaction.id, TransactionStatus.completed);

      return await _walletRepository.getBalance(userId);
    } catch (e) {
      throw Exception('Failed to add money to wallet: ${e.toString()}');
    }
  }

  /// Withdraw money from wallet
  Future<double> withdrawMoney({
    required int userId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? description,
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        throw Exception('Amount must be positive');
      }

      // Validate user exists and is active
      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      if (!user.isActive) {
        throw Exception('User account is not active');
      }

      // Check sufficient balance
      final hasBalance = await _walletRepository.hasSufficientBalance(userId, amount);
      if (!hasBalance) {
        throw Exception('Insufficient wallet balance');
      }

      // Check withdrawal limits (could be configurable)
      const maxWithdrawalAmount = 1000.0; // Example limit
      if (amount > maxWithdrawalAmount) {
        throw Exception('Withdrawal amount exceeds maximum limit');
      }

      // Create transaction
      final transaction = await _transactionRepository.create(CreateTransactionRequest(
        userId: userId,
        type: TransactionType.withdrawal,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description ?? 'Wallet withdrawal',
        referenceId: 'withdrawal_${DateTime.now().millisecondsSinceEpoch}',
      ));

      // In a real implementation, this would process the withdrawal through payment gateway
      // For now, we'll simulate successful withdrawal and update balance
      await _walletRepository.subtractFromBalance(userId, amount);

      // Mark transaction as completed
      await _transactionRepository.updateStatus(transaction.id, TransactionStatus.completed);

      return await _walletRepository.getBalance(userId);
    } catch (e) {
      throw Exception('Failed to withdraw money: ${e.toString()}');
    }
  }

  /// Transfer money between users
  Future<void> transferMoney({
    required int fromUserId,
    required int toUserId,
    required double amount,
    String? description,
  }) async {
    try {
      if (fromUserId == toUserId) {
        throw Exception('Cannot transfer to same user');
      }

      // Validate users exist
      final fromUser = await _userRepository.findById(fromUserId);
      final toUser = await _userRepository.findById(toUserId);

      if (fromUser == null || toUser == null) {
        throw Exception('User not found');
      }

      if (!fromUser.isActive || !toUser.isActive) {
        throw Exception('User account is not active');
      }

      // Use repository transfer method
      await _walletRepository.transferBetweenUsers(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        description: description,
      );

      // Could create transfer transactions for audit trail
      // This is a simplified version

    } catch (e) {
      throw Exception('Failed to transfer money: ${e.toString()}');
    }
  }

  /// Get wallet transaction history
  Future<List<Transaction>> getTransactionHistory(
    int userId, {
    int? limit,
    int? offset,
    TransactionFilter? filter,
  }) async {
    try {
      return await _walletRepository.getTransactionHistory(
        userId,
        limit: limit,
        offset: offset,
        filter: filter,
      );
    } catch (e) {
      throw Exception('Failed to get transaction history: ${e.toString()}');
    }
  }

  /// Check if user has sufficient balance for a transaction
  Future<bool> hasSufficientBalance(int userId, double amount) async {
    try {
      return await _walletRepository.hasSufficientBalance(userId, amount);
    } catch (e) {
      return false;
    }
  }

  /// Get wallet statistics (admin)
  Future<Map<String, dynamic>> getWalletStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _walletRepository.getWalletStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get wallet statistics: ${e.toString()}');
    }
  }

  /// Get users with low wallet balance
  Future<List<Map<String, dynamic>>> getUsersWithLowBalance(double threshold) async {
    try {
      return await _walletRepository.getUsersWithLowBalance(threshold);
    } catch (e) {
      throw Exception('Failed to get users with low balance: ${e.toString()}');
    }
  }

  /// Process commission payment to partner
  Future<void> processCommissionPayment(int partnerId, double commissionAmount) async {
    try {
      // Validate partner
      final partner = await _userRepository.findById(partnerId);
      if (partner == null || partner.role != UserRole.partner) {
        throw Exception('Invalid partner');
      }

      // Add commission to partner wallet
      await _walletRepository.addToBalance(partnerId, commissionAmount);

      // Commission transaction should already be created by TransactionService
      // This method just handles the wallet balance update

    } catch (e) {
      throw Exception('Failed to process commission payment: ${e.toString()}');
    }
  }

  /// Process refund to user wallet
  Future<void> processRefund(int userId, double refundAmount) async {
    try {
      // Add refund to user wallet
      await _walletRepository.addToBalance(userId, refundAmount);

      // Refund transaction should already be created by TransactionService
      // This method just handles the wallet balance update

    } catch (e) {
      throw Exception('Failed to process refund: ${e.toString()}');
    }
  }

  /// Deduct payment from user wallet (for wallet payments)
  Future<bool> deductPayment(int userId, double amount) async {
    try {
      // Check sufficient balance
      final hasBalance = await _walletRepository.hasSufficientBalance(userId, amount);
      if (!hasBalance) {
        return false;
      }

      // Deduct amount
      await _walletRepository.subtractFromBalance(userId, amount);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset wallet balance (admin function)
  Future<double> resetBalance(int userId) async {
    try {
      // Validate user exists
      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      return await _walletRepository.resetBalance(userId);
    } catch (e) {
      throw Exception('Failed to reset wallet balance: ${e.toString()}');
    }
  }

  /// Get wallet activity summary
  Future<List<Map<String, dynamic>>> getWalletActivityByPeriod({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _walletRepository.getWalletActivityByPeriod(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get wallet activity: ${e.toString()}');
    }
  }

  /// Validate wallet operation
  Future<bool> validateWalletOperation({
    required int userId,
    required double amount,
    required String operation, // 'debit', 'credit'
  }) async {
    try {
      // Validate user exists and is active
      final user = await _userRepository.findById(userId);
      if (user == null || !user.isActive) {
        return false;
      }

      // For debit operations, check sufficient balance
      if (operation == 'debit') {
        return await _walletRepository.hasSufficientBalance(userId, amount);
      }

      // For credit operations, just validate positive amount
      return amount > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get wallet limits for user (could be based on user type/rating)
  Future<Map<String, dynamic>> getWalletLimits(int userId) async {
    try {
      final user = await _userRepository.findById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Example limits - in real implementation, these could be configurable
      final limits = {
        'max_balance': 5000.0, // Maximum wallet balance
        'max_daily_withdrawal': 1000.0, // Maximum daily withdrawal
        'max_monthly_withdrawal': 5000.0, // Maximum monthly withdrawal
        'min_withdrawal': 10.0, // Minimum withdrawal amount
        'max_topup': 1000.0, // Maximum single topup
      };

      // Adjust limits based on user role/rating
      if (user.role == UserRole.partner) {
        limits['max_balance'] = 10000.0;
        limits['max_daily_withdrawal'] = 2000.0;
      }

      return limits;
    } catch (e) {
      throw Exception('Failed to get wallet limits: ${e.toString()}');
    }
  }

  /// Apply wallet bonus (promotional feature)
  Future<double> applyWalletBonus(int userId, double bonusAmount, String reason) async {
    try {
      if (bonusAmount <= 0) {
        throw Exception('Bonus amount must be positive');
      }

      // Add bonus to wallet
      final newBalance = await _walletRepository.addToBalance(userId, bonusAmount);

      // Create bonus transaction record (could be a special transaction type)
      // For now, we'll use wallet_topup with special reference

      return newBalance;
    } catch (e) {
      throw Exception('Failed to apply wallet bonus: ${e.toString()}');
    }
  }
}
