import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/wallet_service.dart';
import '../../models/user.dart';
import '../../models/transaction.dart';
import '../base_controller.dart';

class WalletManagementController extends BaseController {
  static final WalletService _walletService = WalletService(
    // These would be injected in real implementation
    null, null, null,
  );

  /// GET /api/dashboard/wallets/statistics - Get wallet statistics
  static Future<Response> getStatistics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'wallets.read')) {
        return BaseController.forbidden();
      }

      final params = BaseController.getQueryParams(request);
      DateTime? startDate;
      DateTime? endDate;

      if (params['start_date'] != null) {
        startDate = DateTime.tryParse(params['start_date']!);
      }

      if (params['end_date'] != null) {
        endDate = DateTime.tryParse(params['end_date']!);
      }

      final statistics = await _walletService.getWalletStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: statistics,
        message: 'Wallet statistics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/wallets/users - Get users wallet information
  static Future<Response> getUsersWallets(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'wallets.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      final queryParams = request.url.queryParameters;

      // In a real implementation, this would query users with their wallet info
      // For now, return mock data
      final usersWallets = [
        {
          'user_id': 1,
          'username': 'john_doe',
          'email': 'john@example.com',
          'balance': 150.50,
          'total_transactions': 25,
          'last_transaction_date': '2024-01-15T10:30:00Z',
        },
        {
          'user_id': 2,
          'username': 'partner_restaurant',
          'email': 'partner@example.com',
          'balance': 500.00,
          'total_transactions': 45,
          'last_transaction_date': '2024-01-14T16:45:00Z',
        },
      ];

      return BaseController.paginated(
        data: usersWallets,
        total: usersWallets.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Users wallets retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/wallets/user/{userId} - Get specific user wallet details
  static Future<Response> getUserWallet(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.read')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final summary = await _walletService.getWalletSummary(userId);

      return BaseController.success(
        data: summary,
        message: 'User wallet details retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/wallets/user/{userId}/transactions - Get user wallet transactions
  static Future<Response> getUserTransactions(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.read')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final pagination = BaseController.getPaginationParams(request);
      final queryParams = request.url.queryParameters;

      // Parse filters
      TransactionFilter? filter;
      final typeFilter = queryParams['type'];
      final statusFilter = queryParams['status'];

      if (typeFilter != null || statusFilter != null) {
        filter = TransactionFilter();

        if (typeFilter != null && typeFilter.isNotEmpty) {
          try {
            filter = filter.copyWith(type: TransactionType.values.firstWhere(
              (t) => t.name == typeFilter,
            ));
          } catch (e) {
            // Invalid type, ignore filter
          }
        }

        if (statusFilter != null && statusFilter.isNotEmpty) {
          try {
            filter = filter.copyWith(status: TransactionStatus.values.firstWhere(
              (s) => s.name == statusFilter,
            ));
          } catch (e) {
            // Invalid status, ignore filter
          }
        }
      }

      final transactions = await _walletService.getTransactionHistory(
        userId,
        limit: pagination['limit'],
        offset: (pagination['page']! - 1) * pagination['limit']!,
        filter: filter,
      );

      return BaseController.success(
        data: transactions.map((t) => t.toJson()).toList(),
        message: 'User wallet transactions retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/wallets/user/{userId}/credit - Credit user wallet (admin)
  static Future<Response> creditUserWallet(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.admin')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['amount', 'reason']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final amount = (body!['amount'] as num).toDouble();
      final reason = body['reason'] as String;

      if (amount <= 0) {
        return BaseController.error(
          message: 'Amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Apply bonus (admin credit)
      final newBalance = await _walletService.applyWalletBonus(userId, amount, reason);

      return BaseController.success(
        data: {'new_balance': newBalance},
        message: 'User wallet credited successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/wallets/user/{userId}/debit - Debit user wallet (admin)
  static Future<Response> debitUserWallet(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.admin')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['amount', 'reason']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final amount = (body!['amount'] as num).toDouble();
      final reason = body['reason'] as String;

      if (amount <= 0) {
        return BaseController.error(
          message: 'Amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Check sufficient balance
      final hasBalance = await _walletService.hasSufficientBalance(userId, amount);
      if (!hasBalance) {
        return BaseController.error(
          message: 'User has insufficient balance',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Deduct from wallet
      final success = await _walletService.deductPayment(userId, amount);
      if (!success) {
        return BaseController.error(
          message: 'Failed to debit user wallet',
          statusCode: HttpStatus.internalServerError,
        );
      }

      final newBalance = await _walletService.getBalance(userId);

      return BaseController.success(
        data: {'new_balance': newBalance},
        message: 'User wallet debited successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/wallets/user/{userId}/reset - Reset user wallet balance
  static Future<Response> resetUserWallet(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.admin')) {
        return BaseController.forbidden();
      }

      final userIdStr = request.params['userId'];
      if (userIdStr == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return BaseController.error(
          message: 'Invalid user ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final newBalance = await _walletService.resetBalance(userId);

      return BaseController.success(
        data: {'new_balance': newBalance},
        message: 'User wallet reset successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/wallets/low-balance - Get users with low wallet balance
  static Future<Response> getUsersWithLowBalance(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.read')) {
        return BaseController.forbidden();
      }

      final threshold = double.tryParse(request.url.queryParameters['threshold'] ?? '10.0') ?? 10.0;
      final users = await _walletService.getUsersWithLowBalance(threshold);

      return BaseController.success(
        data: users,
        message: 'Users with low balance retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/wallets/activity - Get wallet activity by period
  static Future<Response> getWalletActivity(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final period = request.url.queryParameters['period'] ?? 'daily';
      final params = BaseController.getQueryParams(request);

      DateTime? startDate;
      DateTime? endDate;

      if (params['start_date'] != null) {
        startDate = DateTime.tryParse(params['start_date']!);
      }

      if (params['end_date'] != null) {
        endDate = DateTime.tryParse(params['end_date']!);
      }

      if (!['daily', 'weekly', 'monthly'].contains(period)) {
        return BaseController.error(
          message: 'Invalid period. Must be daily, weekly, or monthly',
          statusCode: HttpStatus.badRequest,
        );
      }

      final activity = await _walletService.getWalletActivityByPeriod(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: activity,
        message: 'Wallet activity retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/wallets/transfer - Transfer money between users (admin)
  static Future<Response> transferBetweenUsers(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'wallets.admin')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['from_user_id', 'to_user_id', 'amount']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final fromUserId = body!['from_user_id'] as int;
      final toUserId = body['to_user_id'] as int;
      final amount = (body['amount'] as num).toDouble();
      final description = body['description'] as String?;

      if (amount <= 0) {
        return BaseController.error(
          message: 'Amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (fromUserId == toUserId) {
        return BaseController.error(
          message: 'Cannot transfer to same user',
          statusCode: HttpStatus.badRequest,
        );
      }

      await _walletService.transferMoney(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        description: description,
      );

      return BaseController.success(
        message: 'Money transferred successfully between users',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}
