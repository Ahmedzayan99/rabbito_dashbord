import '../repositories/user_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/partner_repository.dart';
import '../models/order.dart';

class AnalyticsService {
  // TODO: Initialize with proper repository instances
  final UserRepository _userRepository = UserRepository(null as dynamic);
  final OrderRepository _orderRepository = OrderRepository(null as dynamic);
  final PartnerRepository _partnerRepository = PartnerRepository(null as dynamic);
  
  Future<Map<String, dynamic>> getOverview() async {
    try {
      // TODO: Implement these methods in repositories
      final totalUsers = 0; // await _userRepository.getTotalCount();
      final totalPartners = 0; // await _partnerRepository.getTotalCount();
      final totalOrders = 0; // await _orderRepository.getTotalCount();
      final todayOrders = 0; // await _orderRepository.getTodayCount();

      final totalRevenue = 0.0; // await _orderRepository.getTotalRevenue();
      final todayRevenue = 0.0; // await _orderRepository.getTodayRevenue();

      final activeOrders = 0; // await _orderRepository.getActiveOrdersCount();
      final completedOrders = 0; // await _orderRepository.getCompletedOrdersCount();
      
      return {
        'totalUsers': totalUsers,
        'totalPartners': totalPartners,
        'totalOrders': totalOrders,
        'todayOrders': todayOrders,
        'totalRevenue': totalRevenue,
        'todayRevenue': todayRevenue,
        'activeOrders': activeOrders,
        'completedOrders': completedOrders,
        'orderStatusBreakdown': await _getOrderStatusBreakdown(),
        'revenueGrowth': await _getRevenueGrowth(),
      };
    } catch (e) {
      print('Error getting overview: $e');
      return {};
    }
  }
  
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();
      
      final orders = await _orderRepository.findByDateRange(startDate, endDate);
      
      double totalRevenue = 0;
      double totalDeliveryCharges = 0;
      double totalTax = 0;
      int totalOrders = orders.length;
      
      Map<String, int> ordersByStatus = {};
      Map<String, double> revenueByDay = {};
      
      for (final order in orders) {
        totalRevenue += order.finalTotal;
        totalDeliveryCharges += order.deliveryCharge;
        totalTax += order.taxAmount;
        
        // Count by status
        final status = order.status.name;
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
        
        // Revenue by day
        final dayKey = order.createdAt.toIso8601String().split('T')[0];
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + order.finalTotal;
      }
      
      return {
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        'summary': {
          'totalOrders': totalOrders,
          'totalRevenue': totalRevenue,
          'totalDeliveryCharges': totalDeliveryCharges,
          'totalTax': totalTax,
          'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
        },
        'ordersByStatus': ordersByStatus,
        'revenueByDay': revenueByDay,
        'topPartners': await _getTopPartnersByRevenue(startDate, endDate),
      };
    } catch (e) {
      print('Error getting sales report: $e');
      return {};
    }
  }
  
  Future<Map<String, int>> _getOrderStatusBreakdown() async {
    final breakdown = <String, int>{};
    
    for (final status in OrderStatus.values) {
      final count = await _orderRepository.getCountByStatus(status);
      breakdown[status.name] = count;
    }
    
    return breakdown;
  }
  
  Future<Map<String, double>> _getRevenueGrowth() async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    final thisMonthRevenue = await _orderRepository.getRevenueForPeriod(
      thisMonth, 
      now,
    );
    
    final lastMonthRevenue = await _orderRepository.getRevenueForPeriod(
      lastMonth, 
      thisMonth,
    );
    
    final growthRate = lastMonthRevenue > 0 
        ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
        : 0.0;
    
    return {
      'thisMonth': thisMonthRevenue,
      'lastMonth': lastMonthRevenue,
      'growthRate': growthRate,
    };
  }
  
  Future<List<Map<String, dynamic>>> _getTopPartnersByRevenue(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // TODO: Implement getTopPartnersByRevenue in repository
    return []; // await _orderRepository.getTopPartnersByRevenue(startDate, endDate, limit: 10);
  }

  /// Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final totalUsers = 0; // await _userRepository.getTotalCount();
      final newUsers = 0; // await _userRepository.getNewUsersCount(startDate, endDate);
      final activeUsers = 0; // await _userRepository.getActiveUsersCount();

      final usersByRole = await _getUsersByRole();
      final userRegistrationTrend = await _getUserRegistrationTrend(startDate, endDate);
      final topUserCities = await _getTopUserCities();

      return {
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        'summary': {
          'totalUsers': totalUsers,
          'newUsers': newUsers,
          'activeUsers': activeUsers,
        },
        'usersByRole': usersByRole,
        'userRegistrationTrend': userRegistrationTrend,
        'topUserCities': topUserCities,
      };
    } catch (e) {
      print('Error getting user analytics: $e');
      return {};
    }
  }

  /// Get order analytics
  Future<Map<String, dynamic>> getOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final totalOrders = 0; // await _orderRepository.getTotalCount();
      final ordersInPeriod = 0; // await _orderRepository.getOrdersInPeriod(startDate, endDate);
      final avgOrderValue = 0.0; // await _orderRepository.getAverageOrderValue(startDate, endDate);

      final ordersByStatus = await _getOrderStatusBreakdownInPeriod(startDate, endDate);
      final ordersByDay = await _getOrdersByDay(startDate, endDate);
      final topProducts = await _getTopProductsByOrders(startDate, endDate);

      return {
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        'summary': {
          'totalOrders': totalOrders,
          'ordersInPeriod': ordersInPeriod,
          'avgOrderValue': avgOrderValue,
        },
        'ordersByStatus': ordersByStatus,
        'ordersByDay': ordersByDay,
        'topProducts': topProducts,
      };
    } catch (e) {
      print('Error getting order analytics: $e');
      return {};
    }
  }

  Future<Map<String, int>> _getUsersByRole() async {
    // This would need to be implemented in UserRepository
    return {};
  }

  Future<Map<String, int>> _getUserRegistrationTrend(DateTime startDate, DateTime endDate) async {
    // This would need to be implemented in UserRepository
    return {};
  }

  Future<List<Map<String, dynamic>>> _getTopUserCities() async {
    // This would need to be implemented in UserRepository
    return [];
  }

  Future<Map<String, int>> _getOrderStatusBreakdownInPeriod(DateTime startDate, DateTime endDate) async {
    final breakdown = <String, int>{};

    // TODO: Implement getCountByStatusInPeriod in repository
    for (final status in OrderStatus.values) {
      // final count = await _orderRepository.getCountByStatusInPeriod(status, startDate, endDate);
      breakdown[status.name] = 0;
    }

    return breakdown;
  }

  Future<Map<String, int>> _getOrdersByDay(DateTime startDate, DateTime endDate) async {
    final ordersByDay = <String, int>{};
    final orders = await _orderRepository.findByDateRange(startDate, endDate);

    for (final order in orders) {
      final dayKey = order.createdAt.toIso8601String().split('T')[0];
      ordersByDay[dayKey] = (ordersByDay[dayKey] ?? 0) + 1;
    }

    return ordersByDay;
  }

  Future<List<Map<String, dynamic>>> _getTopProductsByOrders(DateTime startDate, DateTime endDate) async {
    // This would need to be implemented in OrderRepository or ProductRepository
    return [];
  }

  /// Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final orders = await _orderRepository.findByDateRange(startDate, endDate);

      double totalRevenue = 0;
      double totalDeliveryCharges = 0;
      double totalTax = 0;
      double totalCommission = 0;
      int totalOrders = orders.length;

      Map<String, double> revenueByDay = {};
      Map<String, double> revenueByPartner = {};
      Map<String, double> revenueByPaymentMethod = {};

      for (final order in orders) {
        totalRevenue += order.finalTotal;
        totalDeliveryCharges += order.deliveryCharge;
        totalTax += order.taxAmount;
        // Commission would be calculated based on partner commission rate
        // totalCommission += order.finalTotal * (order.partnerCommissionRate / 100);

        // Revenue by day
        final dayKey = order.createdAt.toIso8601String().split('T')[0];
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + order.finalTotal;

        // Revenue by partner
        final partnerId = order.partnerId.toString();
        revenueByPartner[partnerId] = (revenueByPartner[partnerId] ?? 0) + order.finalTotal;

        // Revenue by payment method (if available)
        final paymentMethod = order.paymentMethod?.name ?? 'unknown';
        revenueByPaymentMethod[paymentMethod] = (revenueByPaymentMethod[paymentMethod] ?? 0) + order.finalTotal;
      }

      final revenueGrowth = await _getRevenueGrowth();

      return {
        'period': {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        'summary': {
          'totalRevenue': totalRevenue,
          'totalOrders': totalOrders,
          'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
          'totalDeliveryCharges': totalDeliveryCharges,
          'totalTax': totalTax,
          'totalCommission': totalCommission,
          'netRevenue': totalRevenue - totalDeliveryCharges - totalTax - totalCommission,
        },
        'revenueByDay': revenueByDay,
        'revenueByPartner': revenueByPartner,
        'revenueByPaymentMethod': revenueByPaymentMethod,
        'revenueGrowth': revenueGrowth,
        'topPartners': await _getTopPartnersByRevenue(startDate, endDate),
      };
    } catch (e) {
      print('Error getting revenue analytics: $e');
      return {};
    }
  }
}