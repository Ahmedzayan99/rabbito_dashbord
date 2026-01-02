import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'base_controller.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';

/// Controller for payment-related endpoints
class PaymentController extends BaseController {
  final PaymentService _paymentService;

  PaymentController(this._paymentService);

  /// POST /payments/process - Process payment for order
  Future<Response> processPayment(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['order_id', 'payment_method', 'amount'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      // Validate amount
      final amount = body!['amount'];
      if (amount is! num || amount <= 0) {
        return BaseController.error(
          message: 'Amount must be a positive number',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Parse payment method
      PaymentMethod paymentMethod;
      try {
        paymentMethod = PaymentMethod.values.firstWhere(
          (method) => method.name == body['payment_method'],
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid payment method',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Process payment
      final paymentResult = await _paymentService.processPayment(
        orderId: body['order_id'] as int,
        userId: user.id,
        amount: amount.toDouble(),
        paymentMethod: paymentMethod,
        paymentDetails: body['payment_details'] as Map<String, dynamic>?,
      );

      if (!paymentResult.success) {
        return BaseController.error(
          message: paymentResult.message,
          errors: paymentResult.errors,
          statusCode: HttpStatus.badRequest,
        );
      }

      return BaseController.success(
        data: {
          'payment': paymentResult.payment!.toJson(),
          'transaction_id': paymentResult.transactionId,
          'receipt_url': paymentResult.receiptUrl,
        },
        message: paymentResult.message,
        statusCode: HttpStatus.created,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments/{id} - Get payment details
  Future<Response> getPayment(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final paymentId = BaseController.getIdFromParams(request, 'paymentId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (paymentId == null) {
        return BaseController.error(
          message: 'Invalid payment ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final payment = await _paymentService.getPaymentById(paymentId);
      
      if (payment == null) {
        return BaseController.notFound('Payment not found');
      }

      // Check if user can access this payment
      if (!BaseController.canAccessResource(user, payment.userId, 'payments.read')) {
        return BaseController.forbidden();
      }

      return BaseController.success(
        data: payment.toJson(),
        message: 'Payment retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments - Get user payments
  Future<Response> getUserPayments(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final pagination = BaseController.getPaginationParams(request);
      
      final payments = await _paymentService.getUserPayments(
        user.id,
        limit: pagination['limit'],
        offset: pagination['offset'],
      );

      final paymentsJson = payments.map((p) => p.toJson()).toList();

      return BaseController.paginated(
        data: paymentsJson,
        total: paymentsJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Payments retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /payments/{id}/refund - Refund payment
  Future<Response> refundPayment(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final paymentId = BaseController.getIdFromParams(request, 'paymentId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (paymentId == null) {
        return BaseController.error(
          message: 'Invalid payment ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Check permissions
      if (!BaseController.hasPermission(user, 'payments.refund')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      
      final amount = body?['amount'] as num?;
      final reason = body?['reason'] as String?;

      // Validate refund amount if provided
      if (amount != null && amount <= 0) {
        return BaseController.error(
          message: 'Refund amount must be positive',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Process refund
      final refundResult = await _paymentService.refundPayment(
        paymentId,
        amount: amount?.toDouble(),
        reason: reason,
        refundedBy: user.id,
      );

      if (!refundResult.success) {
        return BaseController.error(
          message: refundResult.message,
          statusCode: HttpStatus.badRequest,
        );
      }

      return BaseController.success(
        data: {
          'refund': refundResult.refund!.toJson(),
          'refund_id': refundResult.refundId,
        },
        message: refundResult.message,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments/methods - Get available payment methods
  Future<Response> getPaymentMethods(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final paymentMethods = await _paymentService.getAvailablePaymentMethods(user.id);

      return BaseController.success(
        data: paymentMethods,
        message: 'Payment methods retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /payments/validate - Validate payment details
  Future<Response> validatePayment(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['payment_method', 'payment_details'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      // Parse payment method
      PaymentMethod paymentMethod;
      try {
        paymentMethod = PaymentMethod.values.firstWhere(
          (method) => method.name == body!['payment_method'],
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid payment method',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Validate payment details
      final validation = await _paymentService.validatePaymentDetails(
        paymentMethod,
        body!['payment_details'] as Map<String, dynamic>,
      );

      if (!validation['is_valid']) {
        return BaseController.error(
          message: 'Payment validation failed',
          errors: validation['errors'],
          statusCode: HttpStatus.badRequest,
        );
      }

      return BaseController.success(
        data: validation,
        message: 'Payment details are valid',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /payments/webhook - Handle payment webhook
  Future<Response> handleWebhook(Request request) async {
    try {
      final body = await BaseController.parseJsonBody(request);
      
      if (body == null) {
        return BaseController.error(
          message: 'Request body is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Verify webhook signature
      final signature = request.headers['x-webhook-signature'];
      if (signature == null) {
        return BaseController.error(
          message: 'Webhook signature is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final isValid = await _paymentService.verifyWebhookSignature(
        body,
        signature,
      );

      if (!isValid) {
        return BaseController.error(
          message: 'Invalid webhook signature',
          statusCode: HttpStatus.unauthorized,
        );
      }

      // Process webhook
      await _paymentService.processWebhook(body);

      return BaseController.success(
        message: 'Webhook processed successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments/statistics - Get payment statistics (admin only)
  Future<Response> getPaymentStatistics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (!BaseController.hasPermission(user, 'analytics.read')) {
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

      final statistics = await _paymentService.getPaymentStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: statistics,
        message: 'Payment statistics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments/pending - Get pending payments (admin only)
  Future<Response> getPendingPayments(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (!BaseController.hasPermission(user, 'payments.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      
      final payments = await _paymentService.getPendingPayments(
        limit: pagination['limit'],
        offset: pagination['offset'],
      );

      final paymentsJson = payments.map((p) => p.toJson()).toList();

      return BaseController.paginated(
        data: paymentsJson,
        total: paymentsJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Pending payments retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /payments/{id}/verify - Verify payment status
  Future<Response> verifyPayment(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final paymentId = BaseController.getIdFromParams(request, 'paymentId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (paymentId == null) {
        return BaseController.error(
          message: 'Invalid payment ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Verify payment with payment gateway
      final verificationResult = await _paymentService.verifyPaymentStatus(paymentId);

      return BaseController.success(
        data: verificationResult,
        message: 'Payment verification completed',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments/receipts/{id} - Get payment receipt
  Future<Response> getPaymentReceipt(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final paymentId = BaseController.getIdFromParams(request, 'paymentId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (paymentId == null) {
        return BaseController.error(
          message: 'Invalid payment ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final receipt = await _paymentService.generatePaymentReceipt(paymentId, user.id);
      
      if (receipt == null) {
        return BaseController.notFound('Payment receipt not found');
      }

      return BaseController.success(
        data: receipt,
        message: 'Payment receipt retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /payments/save-method - Save payment method for user
  Future<Response> savePaymentMethod(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['payment_method', 'payment_details'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      // Parse payment method
      PaymentMethod paymentMethod;
      try {
        paymentMethod = PaymentMethod.values.firstWhere(
          (method) => method.name == body!['payment_method'],
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid payment method',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Save payment method
      final savedMethod = await _paymentService.savePaymentMethod(
        user.id,
        paymentMethod,
        body!['payment_details'] as Map<String, dynamic>,
        isDefault: body['is_default'] as bool? ?? false,
      );

      return BaseController.success(
        data: savedMethod.toJson(),
        message: 'Payment method saved successfully',
        statusCode: HttpStatus.created,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /payments/saved-methods - Get user's saved payment methods
  Future<Response> getSavedPaymentMethods(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final savedMethods = await _paymentService.getUserSavedPaymentMethods(user.id);

      return BaseController.success(
        data: savedMethods.map((method) => method.toJson()).toList(),
        message: 'Saved payment methods retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /payments/saved-methods/{id} - Delete saved payment method
  Future<Response> deleteSavedPaymentMethod(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final methodId = BaseController.getIdFromParams(request, 'methodId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (methodId == null) {
        return BaseController.error(
          message: 'Invalid method ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final success = await _paymentService.deleteSavedPaymentMethod(methodId, user.id);

      if (!success) {
        return BaseController.notFound('Payment method not found');
      }

      return BaseController.success(
        message: 'Payment method deleted successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}