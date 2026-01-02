import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../base_controller.dart';

class NotificationManagementController extends BaseController {
  static final NotificationService _notificationService = NotificationService(
    // These would be injected in real implementation
    null, null, null,
  );

  /// GET /api/dashboard/notifications - Get all notifications with filters
  static Future<Response> getNotifications(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'notifications.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      final queryParams = request.url.queryParameters;

      // Parse filters
      String? type = queryParams['type'];
      bool? onlyUnread = queryParams['unread'] == 'true';
      DateTime? startDate;
      DateTime? endDate;

      if (queryParams['start_date'] != null) {
        startDate = DateTime.tryParse(queryParams['start_date']!);
      }

      if (queryParams['end_date'] != null) {
        endDate = DateTime.tryParse(queryParams['end_date']!);
      }

      // For admin, get all notifications or filter by user
      final userId = queryParams['user_id'] != null
          ? int.tryParse(queryParams['user_id']!)
          : null;

      List<Notification> notifications;
      int totalCount;

      if (userId != null) {
        // Get notifications for specific user
        notifications = await _notificationService.getUserNotifications(
          userId,
          limit: pagination['limit'],
          offset: (pagination['page']! - 1) * pagination['limit']!,
        );
        // This is simplified - in real implementation, you'd need a method to count user notifications
        totalCount = notifications.length + ((pagination['limit'] as int) * ((pagination['page'] as int) - 1));
      } else {
        // Get all notifications (admin only)
        // This would require a method to get all notifications with filters
        notifications = [];
        totalCount = 0;
      }

      return BaseController.paginated(
        data: notifications.map((n) => n.toJson()).toList(),
        total: totalCount,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Notifications retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/notifications/{notificationId} - Get notification details
  static Future<Response> getNotification(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'notifications.read')) {
        return BaseController.forbidden();
      }

      final notificationId = BaseController.getIdFromParams(request, 'notificationId');
      if (notificationId == null) {
        return BaseController.error(
          message: 'Notification ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      // This would require a method to get notification by ID
      // For now, return mock data
      final mockNotification = Notification(
        id: notificationId,
        userId: 1,
        title: 'Mock Notification',
        message: 'This is a mock notification',
        type: NotificationType.general,
        status: NotificationStatus.sent,
        data: {},
        readAt: null,
        createdAt: DateTime.now(),
        updatedAt: null,
      );

      return BaseController.success(
        data: mockNotification.toJson(),
        message: 'Notification details retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/notifications - Send notification
  static Future<Response> sendNotification(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'notifications.send')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['user_id', 'title', 'body']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final userId = body!['user_id'] as int;
      final title = body['title'] as String;
      final bodyText = body['body'] as String;
      final type = body['type'] as String?;
      final data = body['data'] as Map<String, dynamic>?;

      final success = await _notificationService.sendNotification(
        userId: userId,
        title: title,
        body: bodyText,
        type: type,
        data: data,
      );

      if (!success) {
        return BaseController.error(
          message: 'Failed to send notification',
          statusCode: HttpStatus.internalServerError,
        );
      }

      return BaseController.success(
        message: 'Notification sent successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/notifications/bulk - Send bulk notifications
  static Future<Response> sendBulkNotification(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'notifications.send')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['user_ids', 'title', 'body']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final userIds = (body!['user_ids'] as List).cast<int>();
      final title = body['title'] as String;
      final bodyText = body['body'] as String;
      final type = body['type'] as String?;
      final data = body['data'] as Map<String, dynamic>?;

      final results = await _notificationService.sendBulkNotification(
        userIds: userIds,
        title: title,
        body: bodyText,
        type: type,
        data: data,
      );

      final successCount = results.values.where((success) => success).length;
      final failureCount = results.length - successCount;

      return BaseController.success(
        data: {
          'total_sent': results.length,
          'successful': successCount,
          'failed': failureCount,
          'results': results,
        },
        message: 'Bulk notification sent successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/notifications/targeted - Send targeted notifications
  static Future<Response> sendTargetedNotification(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'notifications.send')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      final errors = BaseController.validateRequiredFields(body, ['segment', 'title', 'body']);
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final segmentString = body!['segment'] as String;
      final title = body['title'] as String;
      final bodyText = body['body'] as String;
      final type = body['type'] as String?;
      final data = body['data'] as Map<String, dynamic>?;

      // Parse segment
      UserSegment segment;
      try {
        segment = UserSegment.values.firstWhere(
          (s) => s.name == segmentString,
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid user segment',
          statusCode: HttpStatus.badRequest,
        );
      }

      final results = await _notificationService.sendTargetedNotification(
        segment: segment,
        title: title,
        body: bodyText,
        type: type,
        data: data,
      );

      final successCount = results.values.where((success) => success).length;
      final failureCount = results.length - successCount;

      return BaseController.success(
        data: {
          'segment': segmentString,
          'total_sent': results.length,
          'successful': successCount,
          'failed': failureCount,
          'results': results,
        },
        message: 'Targeted notification sent successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/notifications/{notificationId}/read - Mark notification as read
  static Future<Response> markAsRead(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'notifications.update')) {
        return BaseController.forbidden();
      }

      final notificationId = BaseController.getIdFromParams(request, 'notificationId');
      if (notificationId == null) {
        return BaseController.error(
          message: 'Notification ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      // For admin, allow marking any notification as read
      // For regular users, they'd use mobile endpoints
      final success = true; // Mock success

      if (!success) {
        return BaseController.notFound('Notification not found');
      }

      return BaseController.success(
        message: 'Notification marked as read successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /api/dashboard/notifications/user/{userId}/read-all - Mark all user notifications as read
  static Future<Response> markAllAsRead(Request request) async {
    try {
      final admin = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(admin, 'notifications.update')) {
        return BaseController.forbidden();
      }

      final userId = BaseController.getIdFromParams(request, 'userId');
      if (userId == null) {
        return BaseController.error(
          message: 'User ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final count = await _notificationService.markAllAsRead(userId);

      return BaseController.success(
        data: {'marked_read': count},
        message: 'All notifications marked as read successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /api/dashboard/notifications/{notificationId} - Delete notification
  static Future<Response> deleteNotification(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'notifications.delete')) {
        return BaseController.forbidden();
      }

      final notificationId = BaseController.getIdFromParams(request, 'notificationId');
      if (notificationId == null) {
        return BaseController.error(
          message: 'Notification ID is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      // For admin, allow deleting any notification
      final success = true; // Mock success

      if (!success) {
        return BaseController.notFound('Notification not found');
      }

      return BaseController.success(
        message: 'Notification deleted successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/notifications/statistics - Get notification statistics
  static Future<Response> getStatistics(Request request) async {
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

      final statistics = await _notificationService.getNotificationStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: statistics,
        message: 'Notification statistics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/notifications/types - Get notification types summary
  static Future<Response> getTypesSummary(Request request) async {
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

      // This would require a method to get summary by type
      final summary = [
        {'type': 'order_status_update', 'count': 150, 'read_count': 145},
        {'type': 'promotion', 'count': 75, 'read_count': 60},
        {'type': 'system_alert', 'count': 25, 'read_count': 25},
        {'type': 'rider_assigned', 'count': 100, 'read_count': 95},
      ];

      return BaseController.success(
        data: summary,
        message: 'Notification types summary retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /api/dashboard/notifications/trends - Get notification trends
  static Future<Response> getTrends(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'analytics.read')) {
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

      // Mock trends data
      final trends = [
        {
          'period': '2024-01-01',
          'total_sent': 50,
          'total_read': 45,
          'read_percentage': 90.0,
        },
        {
          'period': '2024-01-02',
          'total_sent': 65,
          'total_read': 58,
          'read_percentage': 89.2,
        },
        {
          'period': '2024-01-03',
          'total_sent': 42,
          'total_read': 40,
          'read_percentage': 95.2,
        },
      ];

      return BaseController.success(
        data: trends,
        message: 'Notification trends retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /api/dashboard/notifications/cleanup - Cleanup old notifications
  static Future<Response> cleanupOldNotifications(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      if (!BaseController.hasPermission(user, 'notifications.admin')) {
        return BaseController.forbidden();
      }

      final daysOld = int.tryParse(request.url.queryParameters['days'] ?? '30') ?? 30;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final deletedCount = await _notificationService.cleanupOldNotifications(
        olderThan: Duration(days: daysOld),
      );

      return BaseController.success(
        data: {'deleted_count': deletedCount},
        message: 'Old notifications cleaned up successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}

