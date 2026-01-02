import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/notification_service.dart';

class NotificationController {
  static final NotificationService _notificationService = NotificationService(null as dynamic, null as dynamic, null as dynamic);

  static Future<Response> sendNotification(Request request) async {
    try {
      final requestBody = await request.readAsString();
      final data = jsonDecode(requestBody) as Map<String, dynamic>;

      final title = data['title'] as String?;
      final notificationBody = data['body'] as String? ?? data['message'] as String?;
      final userId = data['userId'] as int?;
      final type = data['type'] as String?;

      if (title == null || notificationBody == null || userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Title, body, and userId are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _notificationService.sendNotification(
        userId: userId,
        title: title,
        body: notificationBody,
        type: type,
      );

      if (!success) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to send notification'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'message': 'Notification sent successfully',
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

  static Future<Response> getNotifications(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final type = queryParams['type'];

      final offset = (page - 1) * limit;
      final notifications = await _notificationService.getNotifications(
        limit: limit,
        offset: offset,
        type: type,
      );

      return Response.ok(
        jsonEncode({
          'notifications': notifications.map((n) => n.toJson()).toList(),
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

  static Future<Response> getNotification(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final notificationId = params?['notificationId'];
      final id = int.tryParse(notificationId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid notification ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final notification = await _notificationService.getNotificationById(id);
      if (notification == null) {
        return Response.notFound(
          jsonEncode({'error': 'Notification not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(notification.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deleteNotification(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final notificationId = params?['notificationId'];
      final id = int.tryParse(notificationId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid notification ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get userId from request context or query params
      final userId = int.tryParse(request.url.queryParameters['userId'] ?? '0') ?? 0;
      final success = await _notificationService.deleteNotification(id, userId);
      if (!success) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to delete notification'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'Notification deleted successfully'}),
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
