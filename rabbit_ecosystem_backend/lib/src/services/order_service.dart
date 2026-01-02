import 'dart:async';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/partner_repository.dart';
import '../repositories/product_repository.dart';
import '../models/order.dart';
import '../models/user.dart';

/// Service for order-related business logic
class OrderService {
  final OrderRepository _orderRepository;
  final UserRepository _userRepository;
  final PartnerRepository _partnerRepository;
  final ProductRepository _productRepository;

  OrderService(
    this._orderRepository,
    this._userRepository,
    this._partnerRepository,
    this._productRepository,
  );

  /// Create a new order
  Future<Order> createOrder({
    required int customerId,
    required int partnerId,
    required int addressId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      // Validate customer
      final customer = await _userRepository.findById(customerId);
      if (customer == null || !customer.isActive) {
        throw Exception('Invalid customer');
      }

      // Validate partner
      final partner = await _partnerRepository.findById(partnerId);
      if (partner == null || partner.status != PartnerStatus.active) {
        throw Exception('Partner is not available');
      }

      // Validate items and calculate totals
      double subtotal = 0.0;
      final validatedItems = <Map<String, dynamic>>[];

      for (final item in items) {
        final productId = item['product_id'] as int;
        final quantity = item['quantity'] as int;
        final variantId = item['variant_id'] as int?;

        if (quantity <= 0) {
          throw Exception('Invalid quantity for product $productId');
        }

        // Get product details
        final productDetails = await _productRepository.getProductWithDetails(productId);
        if (productDetails == null) {
          throw Exception('Product $productId not found');
        }

        final product = productDetails['product'] as Map<String, dynamic>;
        if (product['status'] != 'active') {
          throw Exception('Product ${product['name']} is not available');
        }

        // Calculate item price
        double unitPrice = (product['base_price'] as num).toDouble();
        
        // Add variant price if selected
        if (variantId != null) {
          final variants = productDetails['variants'] as List<Map<String, dynamic>>;
          final variant = variants.firstWhere(
            (v) => v['id'] == variantId,
            orElse: () => throw Exception('Invalid variant selected'),
          );
          unitPrice = (variant['price'] as num).toDouble();
        }

        final totalPrice = unitPrice * quantity;
        subtotal += totalPrice;

        validatedItems.add({
          'product_id': productId,
          'variant_id': variantId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'total_price': totalPrice,
          'special_instructions': item['special_instructions'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Check minimum order amount
      if (subtotal < partner.minimumOrder) {
        throw Exception('Order amount is below minimum order value of ${partner.minimumOrder}');
      }

      // Calculate fees and taxes
      final deliveryFee = partner.deliveryFee;
      final taxRate = 0.15; // 15% VAT
      final taxAmount = subtotal * taxRate;
      final totalAmount = subtotal + deliveryFee + taxAmount;

      // Check customer balance (if paying with wallet)
      if (customer.balance < totalAmount) {
        throw Exception('Insufficient balance. Required: $totalAmount, Available: ${customer.balance}');
      }

      // Create order data
      final orderData = {
        'customer_id': customerId,
        'partner_id': partnerId,
        'address_id': addressId,
        'status': OrderStatus.pending.name,
        'total_amount': totalAmount,
        'delivery_fee': deliveryFee,
        'tax_amount': taxAmount,
        'discount_amount': 0.0,
        'notes': notes,
        'estimated_delivery_time': DateTime.now()
            .add(Duration(minutes: partner.estimatedDeliveryTime))
            .toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Create order with items in transaction
      final order = await _orderRepository.createOrderWithItems(orderData, validatedItems);

      // Deduct amount from customer balance
      await _userRepository.subtractFromBalance(customerId, totalAmount);

      return order;
    } catch (e) {
      throw Exception('Order creation failed: ${e.toString()}');
    }
  }

  /// Get order by ID with items
  Future<Map<String, dynamic>?> getOrderWithItems(int orderId) async {
    return await _orderRepository.getOrderWithItems(orderId);
  }

  /// Get orders for customer
  Future<List<Order>> getCustomerOrders(int customerId, {int? limit, int? offset}) async {
    return await _orderRepository.findByCustomerId(customerId, limit: limit, offset: offset);
  }

  /// Get orders for partner
  Future<List<Order>> getPartnerOrders(int partnerId, {int? limit, int? offset}) async {
    return await _orderRepository.findByPartnerId(partnerId, limit: limit, offset: offset);
  }

  /// Get orders for rider
  Future<List<Order>> getRiderOrders(int riderId, {int? limit, int? offset}) async {
    return await _orderRepository.findByRiderId(riderId, limit: limit, offset: offset);
  }

  /// Get pending orders (available for assignment)
  Future<List<Order>> getPendingOrders({int? limit, int? offset}) async {
    return await _orderRepository.findPendingOrders(limit: limit, offset: offset);
  }

  /// Get active orders for rider
  Future<List<Order>> getActiveOrdersForRider(int riderId) async {
    return await _orderRepository.findActiveOrdersForRider(riderId);
  }

  /// Update order status
  Future<Order?> updateOrderStatus(int orderId, OrderStatus newStatus, {int? userId}) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Validate status transition
      if (!_isValidStatusTransition(order.status, newStatus)) {
        throw Exception('Invalid status transition from ${order.status.name} to ${newStatus.name}');
      }

      // Update status
      final updatedOrder = await _orderRepository.updateStatus(orderId, newStatus);

      // Handle status-specific logic
      await _handleStatusChange(order, newStatus, userId);

      return updatedOrder;
    } catch (e) {
      throw Exception('Status update failed: ${e.toString()}');
    }
  }

  /// Assign rider to order
  Future<Order?> assignRiderToOrder(int orderId, int riderId) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.status != OrderStatus.confirmed) {
        throw Exception('Order must be confirmed before assignment');
      }

      // Check if rider exists and is active
      final rider = await _userRepository.findById(riderId);
      if (rider == null || !rider.isActive || rider.role.value != 'rider') {
        throw Exception('Invalid rider');
      }

      // Check if rider has active orders (limit concurrent orders)
      final activeOrders = await _orderRepository.findActiveOrdersForRider(riderId);
      if (activeOrders.length >= 3) { // Max 3 concurrent orders
        throw Exception('Rider has reached maximum concurrent orders');
      }

      return await _orderRepository.assignRider(orderId, riderId);
    } catch (e) {
      throw Exception('Rider assignment failed: ${e.toString()}');
    }
  }

  /// Cancel order
  Future<Order?> cancelOrder(int orderId, String? reason, {int? userId}) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Check if order can be cancelled
      if (!_canCancelOrder(order.status)) {
        throw Exception('Order cannot be cancelled in current status: ${order.status.name}');
      }

      // Refund customer if payment was made
      if (order.status != OrderStatus.pending) {
        await _userRepository.addToBalance(order.customerId, order.totalAmount);
      }

      return await _orderRepository.cancelOrder(orderId, reason);
    } catch (e) {
      throw Exception('Order cancellation failed: ${e.toString()}');
    }
  }

  /// Accept order by rider
  Future<Order?> acceptOrderByRider(int orderId, int riderId) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.riderId != riderId) {
        throw Exception('Order is not assigned to this rider');
      }

      if (order.status != OrderStatus.assigned) {
        throw Exception('Order is not in assigned status');
      }

      return await _orderRepository.updateStatus(orderId, OrderStatus.pickedUp);
    } catch (e) {
      throw Exception('Order acceptance failed: ${e.toString()}');
    }
  }

  /// Complete order delivery
  Future<Order?> completeOrderDelivery(int orderId, int riderId) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.riderId != riderId) {
        throw Exception('Order is not assigned to this rider');
      }

      if (order.status != OrderStatus.onTheWay) {
        throw Exception('Order is not in delivery status');
      }

      // Update status to delivered
      final updatedOrder = await _orderRepository.updateStatus(orderId, OrderStatus.delivered);

      // Process payment to partner (commission calculation)
      await _processOrderPayment(order);

      return updatedOrder;
    } catch (e) {
      throw Exception('Order completion failed: ${e.toString()}');
    }
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics({DateTime? startDate, DateTime? endDate}) async {
    return await _orderRepository.getOrderStats(startDate: startDate, endDate: endDate);
  }

  /// Search orders
  Future<List<Order>> searchOrders(String query, {int? limit, int? offset}) async {
    return await _orderRepository.searchOrders(query, limit: limit, offset: offset);
  }

  /// Get orders by date range
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate, {int? limit, int? offset}) async {
    return await _orderRepository.findByDateRange(startDate, endDate, limit: limit, offset: offset);
  }

  /// Get revenue by partner
  Future<List<Map<String, dynamic>>> getRevenueByPartner({DateTime? startDate, DateTime? endDate}) async {
    return await _orderRepository.getRevenueByPartner(startDate: startDate, endDate: endDate);
  }

  /// Validate status transition
  bool _isValidStatusTransition(OrderStatus currentStatus, OrderStatus newStatus) {
    const validTransitions = {
      OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.cancelled],
      OrderStatus.confirmed: [OrderStatus.assigned, OrderStatus.cancelled],
      OrderStatus.assigned: [OrderStatus.pickedUp, OrderStatus.cancelled],
      OrderStatus.pickedUp: [OrderStatus.onTheWay, OrderStatus.cancelled],
      OrderStatus.onTheWay: [OrderStatus.delivered, OrderStatus.cancelled],
      OrderStatus.delivered: [], // Final state
      OrderStatus.cancelled: [], // Final state
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  /// Check if order can be cancelled
  bool _canCancelOrder(OrderStatus status) {
    return [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.assigned,
      OrderStatus.pickedUp,
    ].contains(status);
  }

  /// Handle status change side effects
  Future<void> _handleStatusChange(Order order, OrderStatus newStatus, int? userId) async {
    switch (newStatus) {
      case OrderStatus.confirmed:
        // Notify partner about new order
        // Send notification logic here
        break;
      case OrderStatus.assigned:
        // Notify rider about assignment
        // Send notification logic here
        break;
      case OrderStatus.pickedUp:
        // Notify customer that order is picked up
        // Send notification logic here
        break;
      case OrderStatus.onTheWay:
        // Notify customer that order is on the way
        // Send notification logic here
        break;
      case OrderStatus.delivered:
        // Notify customer about delivery completion
        // Update ratings and reviews
        break;
      case OrderStatus.cancelled:
        // Handle cancellation notifications
        // Process refunds if needed
        break;
      default:
        break;
    }
  }

  /// Process order payment (commission calculation)
  Future<void> _processOrderPayment(Order order) async {
    try {
      // Get partner details for commission rate
      final partner = await _partnerRepository.findById(order.partnerId);
      if (partner == null) return;

      // Calculate commission
      final commissionAmount = order.totalAmount * (partner.commissionRate / 100);
      final partnerAmount = order.totalAmount - commissionAmount;

      // Add amount to partner balance (in a real system, this would be more complex)
      await _userRepository.addToBalance(order.partnerId, partnerAmount);

      // Log transaction (would be implemented with transaction service)
      // await _transactionService.createTransaction(...)
    } catch (e) {
      // Log error but don't fail the order completion
      print('Payment processing error: $e');
    }
  }

  /// Get order by ID
  Future<Order?> getOrderById(int orderId) async {
    return await _orderRepository.findById(orderId);
  }

  /// Check if user can access order
  bool canUserAccessOrder(User user, Order order) {
    // Customer can access their own orders
    if (user.id == order.customerId) return true;
    
    // Partner can access their orders
    if (user.role.value == 'partner') {
      // Would need to check if user owns the partner account
      return true; // Simplified for now
    }
    
    // Rider can access assigned orders
    if (user.role.value == 'rider' && order.riderId == user.id) return true;
    
    // Admin/staff can access all orders
    if (user.role.isStaff) return true;
    
    return false;
  }

  /// Get all orders (admin only)
  Future<List<Order>> getAllOrders({int? limit, int? offset}) async {
    return await _orderRepository.findAll(limit: limit, offset: offset);
  }

  /// Get all orders with filters (enhanced version)
  Future<List<Order>> getAllOrdersWithFilters({
    int page = 1,
    int limit = 20,
    OrderStatus? status,
    int? partnerId,
    int? riderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final offset = (page - 1) * limit;
    return await _orderRepository.findAllWithFilters(
      status: status,
      partnerId: partnerId,
      riderId: riderId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  /// Get total order count with filters
  Future<int> getTotalOrderCount({
    OrderStatus? status,
    int? partnerId,
    int? riderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _orderRepository.countWithFilters(
      status: status,
      partnerId: partnerId,
      riderId: riderId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Update order status (admin)
  Future<Order?> updateOrderStatus(
    int orderId,
    OrderStatus status, {
    String? notes,
    int? updatedBy,
  }) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        return null;
      }

      // Update the order status
      final updatedOrder = await _orderRepository.updateStatus(orderId, status);

      if (updatedOrder != null) {
        // Log the status change
        // await _auditService.logOrderStatusChange(orderId, order.status, status, updatedBy, notes);

        // Trigger notifications based on status change
        // await _notificationService.notifyOrderStatusChange(updatedOrder);
      }

      return updatedOrder;
    } catch (e) {
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  /// Assign rider to order
  Future<Order?> assignRiderToOrder(
    int orderId,
    int riderId, {
    int? assignedBy,
    String? notes,
  }) async {
    try {
      // Validate rider
      final rider = await _userRepository.findById(riderId);
      if (rider == null || rider.role != UserRole.rider || !rider.isActive) {
        throw Exception('Invalid rider');
      }

      // Check if order exists and can be assigned
      final order = await _orderRepository.findById(orderId);
      if (order == null || order.status != OrderStatus.confirmed) {
        throw Exception('Order cannot be assigned to rider');
      }

      // Update order with rider assignment
      final updatedOrder = await _orderRepository.assignRider(orderId, riderId);

      if (updatedOrder != null) {
        // Update order status to preparing
        await _orderRepository.updateStatus(orderId, OrderStatus.preparing);

        // Log the assignment
        // await _auditService.logRiderAssignment(orderId, riderId, assignedBy, notes);

        // Notify rider and customer
        // await _notificationService.notifyRiderAssigned(updatedOrder);
      }

      return updatedOrder;
    } catch (e) {
      throw Exception('Failed to assign rider: ${e.toString()}');
    }
  }

  /// Cancel order (admin)
  Future<Order?> cancelOrder(
    int orderId, {
    required String reason,
    int? cancelledBy,
    String? notes,
  }) async {
    try {
      final order = await _orderRepository.findById(orderId);
      if (order == null) {
        return null;
      }

      // Only allow cancellation for certain statuses
      if (![OrderStatus.pending, OrderStatus.confirmed, OrderStatus.preparing].contains(order.status)) {
        throw Exception('Order cannot be cancelled at this stage');
      }

      // Update order status to cancelled
      final cancelledOrder = await _orderRepository.updateStatus(orderId, OrderStatus.cancelled);

      if (cancelledOrder != null) {
        // Process refund if payment was made
        // await _paymentService.processOrderCancellationRefund(orderId, reason);

        // Log the cancellation
        // await _auditService.logOrderCancellation(orderId, reason, cancelledBy, notes);

        // Notify all parties
        // await _notificationService.notifyOrderCancelled(cancelledOrder, reason);
      }

      return cancelledOrder;
    } catch (e) {
      throw Exception('Failed to cancel order: ${e.toString()}');
    }
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _orderRepository.getOrderStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get recent orders
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    return await _orderRepository.getRecentOrders(limit: limit);
  }

  /// Get pending orders for rider assignment
  Future<List<Order>> getPendingOrders({int? limit, int? offset}) async {
    return await _orderRepository.findByStatus(
      OrderStatus.confirmed,
      limit: limit,
      offset: offset,
    );
  }
}