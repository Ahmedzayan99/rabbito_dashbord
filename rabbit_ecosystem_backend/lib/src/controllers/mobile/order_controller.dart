import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/order_service.dart';
import '../../models/user.dart';
import '../../models/order.dart';

class OrderController {
  static final OrderService _orderService = OrderService();
  
  static Future<Response> createOrder(Request request) async {
    try {
      final user = request.context['user'] as User;
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final order = Order.fromJson({
        ...data,
        'userId': user.id,
        'status': OrderStatus.pending.name,
      });
      
      final createdOrder = await _orderService.createOrder(order);
      
      if (createdOrder == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to create order'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(createdOrder.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static Future<Response> getUserOrders(Request request) async {
    try {
      final user = request.context['user'] as User;
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      
      final orders = await _orderService.getUserOrders(user.id, page: page, limit: limit);
      
      return Response.ok(
        jsonEncode({
          'orders': orders.map((o) => o.toJson()).toList(),
          'page': page,
          'limit': limit,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static Future<Response> getOrder(Request request) async {
    try {
      final user = request.context['user'] as User;
      final orderId = int.tryParse(request.params['orderId'] ?? '');
      
      if (orderId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid order ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final order = await _orderService.getOrderById(orderId);
      
      if (order == null || order.userId != user.id) {
        return Response.notFound(
          jsonEncode({'error': 'Order not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(order.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}