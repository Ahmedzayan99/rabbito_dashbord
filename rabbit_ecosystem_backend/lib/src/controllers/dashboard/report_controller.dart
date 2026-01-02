import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/analytics_service.dart';

class ReportController {
  static final AnalyticsService _analyticsService = AnalyticsService();

  static Future<Response> getSalesReport(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final startDateStr = queryParams['start_date'];
      final endDateStr = queryParams['end_date'];
      final reportType = queryParams['type'] ?? 'sales'; // sales, performance, revenue

      DateTime? startDate;
      DateTime? endDate;

      if (startDateStr != null) {
        startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid start_date format. Use ISO 8601 format.'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      if (endDateStr != null) {
        endDate = DateTime.tryParse(endDateStr);
        if (endDate == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid end_date format. Use ISO 8601 format.'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      }

      Map<String, dynamic> report;

      switch (reportType) {
        case 'sales':
          report = await _analyticsService.getSalesReport(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'performance':
          report = await _analyticsService.getOrderAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        case 'revenue':
          report = await _analyticsService.getRevenueAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
          break;
        default:
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid report type. Use: sales, performance, or revenue'}),
            headers: {'Content-Type': 'application/json'},
          );
      }

      return Response.ok(
        jsonEncode({
          'report': report,
          'type': reportType,
          'generatedAt': DateTime.now().toIso8601String(),
          'dateRange': {
            'start': startDate?.toIso8601String(),
            'end': endDate?.toIso8601String(),
          },
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
}
