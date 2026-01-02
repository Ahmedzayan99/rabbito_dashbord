import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/analytics_service.dart';
import '../base_controller.dart';

class AnalyticsController extends BaseController {
  static final AnalyticsService _analyticsService = AnalyticsService();

  /// GET /api/dashboard/analytics/overview
  static Future<Response> getOverview(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final overview = await _analyticsService.getOverview();

      return BaseController.success(
        data: overview,
        message: 'Analytics overview retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/analytics/sales
  static Future<Response> getSalesReport(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final queryParams = request.url.queryParameters;
      final startDateStr = queryParams['start_date'];
      final endDateStr = queryParams['end_date'];

      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return BaseController.error(
            message: 'Invalid start_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return BaseController.error(
            message: 'Invalid end_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      final salesReport = await _analyticsService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: salesReport,
        message: 'Sales analytics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/analytics/users
  static Future<Response> getUserAnalytics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final queryParams = request.url.queryParameters;
      final startDateStr = queryParams['start_date'];
      final endDateStr = queryParams['end_date'];

      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return BaseController.error(
            message: 'Invalid start_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return BaseController.error(
            message: 'Invalid end_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      final userAnalytics = await _analyticsService.getUserAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: userAnalytics,
        message: 'User analytics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/analytics/orders
  static Future<Response> getOrderAnalytics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final queryParams = request.url.queryParameters;
      final startDateStr = queryParams['start_date'];
      final endDateStr = queryParams['end_date'];

      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return BaseController.error(
            message: 'Invalid start_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return BaseController.error(
            message: 'Invalid end_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      final orderAnalytics = await _analyticsService.getOrderAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: orderAnalytics,
        message: 'Order analytics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/analytics/revenue
  static Future<Response> getRevenueAnalytics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final queryParams = request.url.queryParameters;
      final startDateStr = queryParams['start_date'];
      final endDateStr = queryParams['end_date'];
      final groupBy = queryParams['group_by'] ?? 'day'; // day, week, month

      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return BaseController.error(
            message: 'Invalid start_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return BaseController.error(
            message: 'Invalid end_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      // For now, return sales report which includes revenue data
      final revenueData = await _analyticsService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: revenueData,
        message: 'Revenue analytics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/analytics/partners
  static Future<Response> getPartnerAnalytics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
        return BaseController.forbidden();
      }

      final queryParams = request.url.queryParameters;
      final startDateStr = queryParams['start_date'];
      final endDateStr = queryParams['end_date'];

      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return BaseController.error(
            message: 'Invalid start_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return BaseController.error(
            message: 'Invalid end_date format. Use ISO 8601 format.',
            statusCode: 400,
          );
        }
      }

      // Get top partners from sales report
      final salesReport = await _analyticsService.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: {
          'topPartners': salesReport['topPartners'] ?? [],
          'partnerPerformance': await _getPartnerPerformanceMetrics(startDate, endDate),
        },
        message: 'Partner analytics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// Helper method to get partner performance metrics
  static Future<Map<String, dynamic>> _getPartnerPerformanceMetrics(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // This would be implemented to get detailed partner metrics
    // For now, return empty structure
    return {
      'averageRating': 0.0,
      'totalOrders': 0,
      'averagePreparationTime': 0,
      'customerSatisfaction': 0.0,
    };
  }
}