import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../base_controller.dart';

class OrderManagementController extends BaseController {
  static final OrderService _orderService = OrderService();

  /// GET /api/dashboard/orders - Get all orders with filters
  static Future<Response> getOrders(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      final queryParams = request.url.queryParameters;

      // Parse filters
      OrderStatus? status;
      final statusFilter = queryParams['status'];
      if (statusFilter != null && statusFilter.isNotEmpty) {
        try {
          status = OrderStatus.values.firstWhere((s) => s.name == statusFilter);
        } catch (e) {
          // Invalid status, ignore filter
        }
      }

      final partnerId = queryParams['partner_id'] != null
          ? int.tryParse(queryParams['partner_id']!)
          : null;

      final riderId = queryParams['rider_id'] != null
          ? int.tryParse(queryParams['rider_id']!)
          : null;

      final startDate = queryParams['start_date'] != null
          ? DateTime.tryParse(queryParams['start_date']!)
          : null;

      final endDate = queryParams['end_date'] != null
          ? DateTime.tryParse(queryParams['end_date']!)
          : null;

      final orders = await _orderService.getAllOrders(
        page: pagination['page']!,
        limit: pagination['limit']!,
        status: status,
        partnerId: partnerId,
        riderId: riderId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalCount = await _orderService.getTotalOrderCount(
        status: status,
        partnerId: partnerId,
        riderId: riderId,
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.paginated(
        data: orders.map((o) => o.toJson()).toList(),
        total: totalCount,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Orders retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/orders/{orderId} - Get order details
  static Future<Response> getOrder(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.read')) {
        return BaseController.forbidden();
      }

      final orderIdStr = request.params['orderId'];
      if (orderIdStr == null) {
        return BaseController.error(
          message: 'Order ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final orderId = int.tryParse(orderIdStr);
      if (orderId == null) {
        return BaseController.error(
          message: 'Invalid order ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final order = await _orderService.getOrderById(orderId);
      if (order == null) {
        return BaseController.notFound('Order not found');
      }

      return BaseController.success(
        data: order.toJson(),
        message: 'Order details retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/orders/{orderId}/status - Update order status
  static Future<Response> updateOrderStatus(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.update')) {
        return BaseController.forbidden();
      }

      final orderIdStr = request.params['orderId'];
      if (orderIdStr == null) {
        return BaseController.error(
          message: 'Order ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final orderId = int.tryParse(orderIdStr);
      if (orderId == null) {
        return BaseController.error(
          message: 'Invalid order ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['status']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final statusString = body!['status'] as String;
      OrderStatus status;
      try {
        status = OrderStatus.values.firstWhere((s) => s.name == statusString);
      } catch (e) {
        return BaseController.error(
          message: 'Invalid order status',
          statusCode: HttpStatus.badRequest,
        );
      }

      final notes = body['notes'] as String?;
      final updatedOrder = await _orderService.updateOrderStatus(
        orderId,
        status,
        notes: notes,
        updatedBy: user!.id,
      );

      if (updatedOrder == null) {
        return BaseController.notFound('Order not found');
      }

      return BaseController.success(
        data: updatedOrder.toJson(),
        message: 'Order status updated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/orders/{orderId}/assign-rider - Assign rider to order
  static Future<Response> assignRider(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.update')) {
        return BaseController.forbidden();
      }

      final orderIdStr = request.params['orderId'];
      if (orderIdStr == null) {
        return BaseController.error(
          message: 'Order ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final orderId = int.tryParse(orderIdStr);
      if (orderId == null) {
        return BaseController.error(
          message: 'Invalid order ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['rider_id']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final riderId = body!['rider_id'] as int;
      final notes = body['notes'] as String?;

      final updatedOrder = await _orderService.assignRiderToOrder(
        orderId,
        riderId,
        assignedBy: user!.id,
        notes: notes,
      );

      if (updatedOrder == null) {
        return BaseController.notFound('Order not found or rider not available');
      }

      return BaseController.success(
        data: updatedOrder.toJson(),
        message: 'Rider assigned to order successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/orders/statistics - Get order statistics
  static Future<Response> getOrderStatistics(Request request) async {
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

      final statistics = await _orderService.getOrderStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: statistics,
        message: 'Order statistics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/orders/{orderId}/cancel - Cancel order (admin)
  static Future<Response> cancelOrder(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.cancel')) {
        return BaseController.forbidden();
      }

      final orderIdStr = request.params['orderId'];
      if (orderIdStr == null) {
        return BaseController.error(
          message: 'Order ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final orderId = int.tryParse(orderIdStr);
      if (orderId == null) {
        return BaseController.error(
          message: 'Invalid order ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['reason']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final reason = body!['reason'] as String;
      final notes = body['notes'] as String?;

      final cancelledOrder = await _orderService.cancelOrder(
        orderId,
        reason: reason,
        cancelledBy: user!.id,
        notes: notes,
      );

      if (cancelledOrder == null) {
        return BaseController.notFound('Order not found');
      }

      return BaseController.success(
        data: cancelledOrder.toJson(),
        message: 'Order cancelled successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/orders/recent - Get recent orders
  static Future<Response> getRecentOrders(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.read')) {
        return BaseController.forbidden();
      }

      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
      final orders = await _orderService.getRecentOrders(limit: limit);

      return BaseController.success(
        data: orders.map((o) => o.toJson()).toList(),
        message: 'Recent orders retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/orders/pending - Get pending orders for assignment
  static Future<Response> getPendingOrders(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'orders.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      final orders = await _orderService.getPendingOrders(
        limit: pagination['limit'],
        offset: (pagination['page']! - 1) * pagination['limit']!,
      );

      return BaseController.success(
        data: orders.map((o) => o.toJson()).toList(),
        message: 'Pending orders retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}