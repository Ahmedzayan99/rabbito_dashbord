import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/wallet_service.dart';
import '../../models/payment.dart';
import '../../models/transaction.dart';
import '../base_controller.dart';

class WalletController extends BaseController {
  static final WalletService _walletService = WalletService(
    // These would be injected in real implementation
    null, null, null,
  );

  /// GET /api/mobile/wallet/balance - Get user wallet balance
  static Future<Response> getBalance(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final balance = await _walletService.getBalance(user.id);

      return BaseController.success(
        data: {'balance': balance},
        message: 'Wallet balance retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/mobile/wallet/summary - Get wallet summary
  static Future<Response> getSummary(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final summary = await _walletService.getWalletSummary(user.id);

      return BaseController.success(
        data: summary,
        message: 'Wallet summary retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/mobile/wallet/topup - Add money to wallet
  static Future<Response> topup(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['amount', 'payment_method']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final amount = (body!['amount'] as num).toDouble();
      final paymentMethodString = body['payment_method'] as String;
      final description = body['description'] as String?;

      // Validate amount
      if (amount <= 0) {
        return BaseController.error(
          message: 'Amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Parse payment method
      PaymentMethod paymentMethod;
      try {
        paymentMethod = PaymentMethod.values.firstWhere(
          (m) => m.name == paymentMethodString,
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid payment method',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Check wallet limits
      final limits = await _walletService.getWalletLimits(user.id);
      if (amount > limits['max_topup']) {
        return BaseController.error(
          message: 'Amount exceeds maximum topup limit',
          statusCode: HttpStatus.badRequest,
        );
      }

      final newBalance = await _walletService.addMoney(
        userId: user.id,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );

      return BaseController.success(
        data: {'new_balance': newBalance},
        message: 'Wallet topped up successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/mobile/wallet/withdraw - Withdraw money from wallet
  static Future<Response> withdraw(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['amount', 'payment_method']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final amount = (body!['amount'] as num).toDouble();
      final paymentMethodString = body['payment_method'] as String;
      final description = body['description'] as String?;

      // Validate amount
      if (amount <= 0) {
        return BaseController.error(
          message: 'Amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Parse payment method
      PaymentMethod paymentMethod;
      try {
        paymentMethod = PaymentMethod.values.firstWhere(
          (m) => m.name == paymentMethodString,
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid payment method',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Check wallet limits
      final limits = await _walletService.getWalletLimits(user.id);
      if (amount < limits['min_withdrawal']) {
        return BaseController.error(
          message: 'Amount below minimum withdrawal limit',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (amount > limits['max_daily_withdrawal']) {
        return BaseController.error(
          message: 'Amount exceeds maximum daily withdrawal limit',
          statusCode: HttpStatus.badRequest,
        );
      }

      final newBalance = await _walletService.withdrawMoney(
        userId: user.id,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );

      return BaseController.success(
        data: {'new_balance': newBalance},
        message: 'Withdrawal processed successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/mobile/wallet/transfer - Transfer money to another user
  static Future<Response> transfer(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['to_user_id', 'amount']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final toUserId = body!['to_user_id'] as int;
      final amount = (body['amount'] as num).toDouble();
      final description = body['description'] as String?;

      // Validate amount
      if (amount <= 0) {
        return BaseController.error(
          message: 'Amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (toUserId == user.id) {
        return BaseController.error(
          message: 'Cannot transfer to yourself',
          statusCode: HttpStatus.badRequest,
        );
      }

      await _walletService.transferMoney(
        fromUserId: user.id,
        toUserId: toUserId,
        amount: amount,
        description: description,
      );

      final newBalance = await _walletService.getBalance(user.id);

      return BaseController.success(
        data: {'new_balance': newBalance},
        message: 'Money transferred successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/mobile/wallet/transactions - Get wallet transaction history
  static Future<Response> getTransactions(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
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
        user.id,
        limit: pagination['limit'],
        offset: (pagination['page']! - 1) * pagination['limit']!,
        filter: filter,
      );

      return BaseController.success(
        data: transactions.map((t) => t.toJson()).toList(),
        message: 'Wallet transactions retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/mobile/wallet/limits - Get wallet limits for user
  static Future<Response> getLimits(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final limits = await _walletService.getWalletLimits(user.id);

      return BaseController.success(
        data: limits,
        message: 'Wallet limits retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/mobile/wallet/validate - Validate wallet operation
  static Future<Response> validateOperation(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['amount', 'operation']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final amount = (body!['amount'] as num).toDouble();
      final operation = body['operation'] as String;

      if (!['debit', 'credit'].contains(operation)) {
        return BaseController.error(
          message: 'Invalid operation. Must be "debit" or "credit"',
          statusCode: HttpStatus.badRequest,
        );
      }

      final isValid = await _walletService.validateWalletOperation(
        userId: user.id,
        amount: amount,
        operation: operation,
      );

      return BaseController.success(
        data: {'valid': isValid},
        message: 'Wallet operation validated',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}
