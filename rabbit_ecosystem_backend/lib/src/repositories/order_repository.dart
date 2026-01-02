import 'dart:async';
import 'package:postgres/postgres.dart';
import 'base_repository.dart';
import '../models/order.dart';

/// Repository for order-related database operations
class OrderRepository extends BaseRepository<Order> {
  OrderRepository(super.connection);

  @override
  String get tableName => 'orders';

  @override
  Order fromMap(Map<String, dynamic> map) {
    return Order.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Order order) {
    return {
      'user_id': order.userId,
      'partner_id': order.partnerId,
      'rider_id': order.riderId,
      'address_id': order.addressId,
      'status': order.status.value,
      'subtotal': order.subtotal,
      'delivery_charge': order.deliveryCharge,
      'tax_amount': order.taxAmount,
      'discount_amount': order.discountAmount,
      'total': order.total,
      'payment_method': order.paymentMethod.value,
      'otp': order.otp,
      'notes': order.notes,
      'delivery_time': order.deliveryTime,
      'delivery_date': order.deliveryDate,
      'estimated_delivery': order.estimatedDelivery?.toIso8601String(),
      'actual_delivery': order.actualDelivery?.toIso8601String(),
      'created_at': order.createdAt.toIso8601String(),
      'updated_at': order.updatedAt?.toIso8601String(),
    };
  }

  /// Find orders by customer ID
  Future<List<Order>> findByCustomerId(int customerId, {int? limit, int? offset}) async {
    String query = 'SELECT * FROM orders WHERE customer_id = @customer_id ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'customer_id': customerId},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find orders by partner ID
  Future<List<Order>> findByPartnerId(int partnerId, {int? limit, int? offset}) async {
    String query = 'SELECT * FROM orders WHERE partner_id = @partner_id ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'partner_id': partnerId},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find orders by rider ID
  Future<List<Order>> findByRiderId(int riderId, {int? limit, int? offset}) async {
    String query = 'SELECT * FROM orders WHERE rider_id = @rider_id ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'rider_id': riderId},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find orders by status
  Future<List<Order>> findByStatus(OrderStatus status, {int? limit, int? offset}) async {
    String query = 'SELECT * FROM orders WHERE status = @status ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'status': status.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find pending orders (available for riders)
  Future<List<Order>> findPendingOrders({int? limit, int? offset}) async {
    return await findByStatus(OrderStatus.confirmed, limit: limit, offset: offset);
  }

  /// Find active orders for a rider
  Future<List<Order>> findActiveOrdersForRider(int riderId) async {
    return await findWhere(
      'rider_id = @rider_id AND status IN (@status1, @status2)',
      parameters: {
        'rider_id': riderId,
        'status1': OrderStatus.pickedUp.name,
        'status2': OrderStatus.onTheWay.name,
      },
    );
  }

  /// Update order status
  Future<Order?> updateStatus(int orderId, OrderStatus status) async {
    final updateData = <String, dynamic>{'status': status.name};
    
    // Set delivery time for completed orders
    if (status == OrderStatus.delivered) {
      updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
    }

    return await update(orderId, updateData);
  }

  /// Assign rider to order
  Future<Order?> assignRider(int orderId, int riderId) async {
    return await update(orderId, {
      'rider_id': riderId,
      'status': OrderStatus.assigned.name,
    });
  }

  /// Remove rider from order
  Future<Order?> unassignRider(int orderId) async {
    return await update(orderId, {
      'rider_id': null,
      'status': OrderStatus.confirmed.name,
    });
  }

  /// Create order with items
  Future<Order> createOrderWithItems(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> orderItems,
  ) async {
    return await withTransaction(() async {
      // Create the order
      final order = await create(orderData);

      // Create order items
      for (final itemData in orderItems) {
        itemData['order_id'] = order.id;
        await connection.execute(
          '''INSERT INTO order_items (order_id, product_id, variant_id, quantity, unit_price, total_price, special_instructions, created_at)
             VALUES (@order_id, @product_id, @variant_id, @quantity, @unit_price, @total_price, @special_instructions, @created_at)''',
          parameters: itemData,
        );
      }

      return order;
    });
  }

  /// Get order with items
  Future<Map<String, dynamic>?> getOrderWithItems(int orderId) async {
    final orderResult = await executeQuerySingle(
      'SELECT * FROM orders WHERE id = @id',
      parameters: {'id': orderId},
    );

    if (orderResult == null) return null;

    final itemsResult = await executeQuery(
      '''SELECT oi.*, p.name as product_name, pv.name as variant_name
         FROM order_items oi
         LEFT JOIN products p ON oi.product_id = p.id
         LEFT JOIN product_variants pv ON oi.variant_id = pv.id
         WHERE oi.order_id = @order_id
         ORDER BY oi.created_at''',
      parameters: {'order_id': orderId},
    );

    return {
      'order': orderResult,
      'items': itemsResult,
    };
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStats({DateTime? startDate, DateTime? endDate}) async {
    String whereClause = '';
    Map<String, dynamic> parameters = {};

    if (startDate != null || endDate != null) {
      whereClause = 'WHERE ';
      final conditions = <String>[];
      
      if (startDate != null) {
        conditions.add('created_at >= @start_date');
        parameters['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        conditions.add('created_at <= @end_date');
        parameters['end_date'] = endDate.toIso8601String();
      }
      
      whereClause += conditions.join(' AND ');
    }

    final result = await executeQuerySingle('''
      SELECT 
        COUNT(*) as total_orders,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
        COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_orders,
        COUNT(CASE WHEN status = 'assigned' THEN 1 END) as assigned_orders,
        COUNT(CASE WHEN status = 'picked_up' THEN 1 END) as picked_up_orders,
        COUNT(CASE WHEN status = 'on_the_way' THEN 1 END) as on_the_way_orders,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
        AVG(total_amount) as average_order_value,
        SUM(total_amount) as total_revenue
      FROM orders $whereClause
    ''', parameters: parameters);

    return result ?? {};
  }

  /// Get orders by date range
  Future<List<Order>> findByDateRange(DateTime startDate, DateTime endDate, {int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM orders 
      WHERE created_at >= @start_date AND created_at <= @end_date 
      ORDER BY created_at DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Search orders by customer name, order ID, or status
  Future<List<Order>> searchOrders(String query, {int? limit, int? offset}) async {
    final searchQuery = '''
      SELECT o.*, u.username as customer_name 
      FROM orders o
      LEFT JOIN users u ON o.customer_id = u.id
      WHERE (
        o.id::text ILIKE @query OR 
        u.username ILIKE @query OR 
        u.mobile ILIKE @query OR
        o.status ILIKE @query
      )
      ORDER BY o.created_at DESC
    ''';

    String finalQuery = searchQuery;
    if (limit != null) {
      finalQuery += ' LIMIT $limit';
    }
    if (offset != null) {
      finalQuery += ' OFFSET $offset';
    }

    final result = await connection.execute(
      finalQuery,
      parameters: {'query': '%$query%'},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Cancel order
  Future<Order?> cancelOrder(int orderId, String? reason) async {
    final updateData = {
      'status': OrderStatus.cancelled.name,
    };
    
    if (reason != null) {
      updateData['notes'] = reason;
    }

    return await update(orderId, updateData);
  }

  /// Get revenue by partner
  Future<List<Map<String, dynamic>>> getRevenueByPartner({DateTime? startDate, DateTime? endDate}) async {
    String whereClause = "WHERE o.status = 'delivered'";
    Map<String, dynamic> parameters = {};

    if (startDate != null || endDate != null) {
      final conditions = <String>["o.status = 'delivered'"];
      
      if (startDate != null) {
        conditions.add('o.created_at >= @start_date');
        parameters['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        conditions.add('o.created_at <= @end_date');
        parameters['end_date'] = endDate.toIso8601String();
      }
      
      whereClause = 'WHERE ' + conditions.join(' AND ');
    }

    final result = await executeQuery('''
      SELECT 
        p.id as partner_id,
        p.business_name,
        COUNT(o.id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as average_order_value
      FROM orders o
      JOIN partners p ON o.partner_id = p.id
      $whereClause
      GROUP BY p.id, p.business_name
      ORDER BY total_revenue DESC
    ''', parameters: parameters);

    return result;
  }

  /// Find orders with advanced filters
  Future<List<Order>> findAllWithFilters({
    OrderStatus? status,
    int? partnerId,
    int? riderId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (status != null) {
      conditions.add('o.status = @status');
      parameters['status'] = status.name;
    }

    if (partnerId != null) {
      conditions.add('o.partner_id = @partner_id');
      parameters['partner_id'] = partnerId;
    }

    if (riderId != null) {
      conditions.add('o.rider_id = @rider_id');
      parameters['rider_id'] = riderId;
    }

    if (startDate != null) {
      conditions.add('o.created_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('o.created_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await executeQuery('''
      SELECT o.*, u.username as customer_name, p.business_name as partner_name,
             r.username as rider_name, a.street_address, a.city, a.state
      FROM orders o
      LEFT JOIN users u ON o.customer_id = u.id
      LEFT JOIN partners p ON o.partner_id = p.id
      LEFT JOIN users r ON o.rider_id = r.id
      LEFT JOIN addresses a ON o.address_id = a.id
      $whereClause
      ORDER BY o.created_at DESC
      $limitClause $offsetClause
    ''', parameters: parameters);

    return result.map((row) => Order.fromJson(row)).toList();
  }

  /// Count orders with filters
  Future<int> countWithFilters({
    OrderStatus? status,
    int? partnerId,
    int? riderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (status != null) {
      conditions.add('status = @status');
      parameters['status'] = status.name;
    }

    if (partnerId != null) {
      conditions.add('partner_id = @partner_id');
      parameters['partner_id'] = partnerId;
    }

    if (riderId != null) {
      conditions.add('rider_id = @rider_id');
      parameters['rider_id'] = riderId;
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
      SELECT COUNT(*) as count FROM orders
      $whereClause
    ''', parameters: parameters);

    return result.first['count'] as int;
  }


  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics({
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

    final result = await executeQuery('''
      SELECT
        COUNT(*) as total_orders,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
        COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_orders,
        COUNT(CASE WHEN status = 'preparing' THEN 1 END) as preparing_orders,
        COUNT(CASE WHEN status = 'ready' THEN 1 END) as ready_orders,
        COUNT(CASE WHEN status = 'picked_up' THEN 1 END) as picked_up_orders,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as average_order_value
      FROM orders
      $whereClause
    ''', parameters: parameters);

    return result.first;
  }

  /// Get recent orders
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    final result = await executeQuery('''
      SELECT o.*, u.username as customer_name, p.business_name as partner_name
      FROM orders o
      LEFT JOIN users u ON o.customer_id = u.id
      LEFT JOIN partners p ON o.partner_id = p.id
      ORDER BY o.created_at DESC
      LIMIT $limit
    ''');

    return result.map((row) => Order.fromJson(row)).toList();
  }

  /// Get count of orders by status
  Future<int> getCountByStatus(OrderStatus status) async {
    final result = await executeQuerySingle(
      'SELECT COUNT(*) as count FROM orders WHERE status = @status',
      parameters: {'status': status.value},
    );

    return result?['count'] as int? ?? 0;
  }

  /// Get revenue for a specific period
  Future<double> getRevenueForPeriod(DateTime startDate, DateTime endDate) async {
    final result = await executeQuerySingle(
      'SELECT COALESCE(SUM(total_amount), 0) as revenue FROM orders WHERE created_at >= @startDate AND created_at <= @endDate AND status = \'delivered\'',
      parameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    return (result?['revenue'] as num?)?.toDouble() ?? 0.0;
  }
}