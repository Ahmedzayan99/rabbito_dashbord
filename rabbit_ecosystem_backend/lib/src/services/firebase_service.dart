import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';
import '../models/notification.dart';

/// Firebase Cloud Messaging service for sending push notifications
class FirebaseService {
  final http.Client _httpClient;
  final String _serverKey;

  FirebaseService({
    http.Client? httpClient,
    String? serverKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _serverKey = serverKey ?? FirebaseConfig.serverKey;

  /// Initialize Firebase service
  static Future<FirebaseService> initialize() async {
    FirebaseConfig.validateConfiguration();
    return FirebaseService();
  }

  /// Send notification to a single device
  Future<bool> sendToDevice({
    required String token,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    int? ttlSeconds,
  }) async {
    try {
      final message = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': data ?? {},
        'priority': priority.value,
        if (ttlSeconds != null) 'time_to_live': ttlSeconds,
      };

      return await _sendMessage(message);
    } catch (e) {
      print('Failed to send notification to device: $e');
      return false;
    }
  }

  /// Send notification to multiple devices
  Future<Map<String, bool>> sendToDevices({
    required List<String> tokens,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    int? ttlSeconds,
  }) async {
    final results = <String, bool>{};

    // Send in batches to avoid FCM limits
    for (var i = 0; i < tokens.length; i += FirebaseConfig.batchSize) {
      final batch = tokens.sublist(
        i,
        i + FirebaseConfig.batchSize > tokens.length
            ? tokens.length
            : i + FirebaseConfig.batchSize,
      );

      final message = {
        'registration_ids': batch,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': data ?? {},
        'priority': priority.value,
        if (ttlSeconds != null) 'time_to_live': ttlSeconds,
      };

      try {
        final success = await _sendMessage(message);
        for (final token in batch) {
          results[token] = success;
        }
      } catch (e) {
        print('Failed to send batch notification: $e');
        for (final token in batch) {
          results[token] = false;
        }
      }
    }

    return results;
  }

  /// Send notification to a topic
  Future<bool> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    int? ttlSeconds,
  }) async {
    try {
      final message = {
        'to': '/topics/$topic',
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': data ?? {},
        'priority': priority.value,
        if (ttlSeconds != null) 'time_to_live': ttlSeconds,
      };

      return await _sendMessage(message);
    } catch (e) {
      print('Failed to send notification to topic: $e');
      return false;
    }
  }

  /// Subscribe device to topic
  Future<bool> subscribeToTopic({
    required String token,
    required String topic,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('https://iid.googleapis.com/iid/v1/$token/rel/topics/$topic'),
        headers: {
          'Authorization': 'key=$_serverKey',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to subscribe to topic: $e');
      return false;
    }
  }

  /// Unsubscribe device from topic
  Future<bool> unsubscribeFromTopic({
    required String token,
    required String topic,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('https://iid.googleapis.com/iid/v1:unsubscribeFromTopic'),
        headers: {
          'Authorization': 'key=$_serverKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': '/topics/$topic',
          'registration_tokens': [token],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
      return false;
    }
  }

  /// Send order status update notification
  Future<bool> sendOrderStatusUpdate({
    required String token,
    required int orderId,
    required String status,
    required String customerName,
  }) async {
    final title = 'Order Update';
    final body = 'Hi $customerName, your order #$orderId status has been updated to: $status';

    return await sendToDevice(
      token: token,
      title: title,
      body: body,
      data: {
        'type': 'order_status_update',
        'order_id': orderId.toString(),
        'status': status,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      priority: NotificationPriority.high,
    );
  }

  /// Send promotional notification
  Future<bool> sendPromotion({
    required String token,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    return await sendToDevice(
      token: token,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: {
        'type': 'promotion',
        ...?data,
      },
      priority: NotificationPriority.normal,
    );
  }

  /// Send rider assignment notification
  Future<bool> sendRiderAssignment({
    required String token,
    required int orderId,
    required String riderName,
    required String estimatedTime,
  }) async {
    final title = 'Rider Assigned';
    final body = '$riderName has been assigned to deliver your order #$orderId. Estimated delivery: $estimatedTime';

    return await sendToDevice(
      token: token,
      title: title,
      body: body,
      data: {
        'type': 'rider_assigned',
        'order_id': orderId.toString(),
        'rider_name': riderName,
        'estimated_time': estimatedTime,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      priority: NotificationPriority.high,
    );
  }

  /// Send partner order notification
  Future<bool> sendPartnerOrderNotification({
    required String token,
    required int orderId,
    required String customerName,
    required double orderAmount,
  }) async {
    final title = 'New Order';
    final body = 'You have received a new order #$orderId from $customerName for SAR ${orderAmount.toStringAsFixed(2)}';

    return await sendToDevice(
      token: token,
      title: title,
      body: body,
      data: {
        'type': 'new_order',
        'order_id': orderId.toString(),
        'customer_name': customerName,
        'amount': orderAmount.toString(),
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      priority: NotificationPriority.high,
    );
  }

  /// Send system alert
  Future<bool> sendSystemAlert({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await sendToDevice(
      token: token,
      title: title,
      body: body,
      data: {
        'type': 'system_alert',
        ...?data,
      },
      priority: NotificationPriority.high,
    );
  }

  /// Validate FCM token
  Future<bool> validateToken(String token) async {
    try {
      // Send a test message with dry run
      final message = {
        'to': token,
        'notification': {
          'title': 'Test',
          'body': 'Test notification',
        },
        'dry_run': true,
      };

      final response = await _httpClient.post(
        Uri.parse(FirebaseConfig.fcmSendUrl),
        headers: {
          'Authorization': 'key=$_serverKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send notification with retry logic
  Future<bool> _sendMessage(Map<String, dynamic> message) async {
    for (var attempt = 1; attempt <= FirebaseConfig.maxRetries; attempt++) {
      try {
        final response = await _httpClient.post(
          Uri.parse(FirebaseConfig.fcmSendUrl),
          headers: {
            'Authorization': 'key=$_serverKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(message),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final successCount = responseData['success'] ?? 0;
          final failureCount = responseData['failure'] ?? 0;

          // Consider it successful if at least one message was sent successfully
          return successCount > 0;
        } else if (response.statusCode == 400) {
          // Bad request - don't retry
          print('FCM Bad Request: ${response.body}');
          return false;
        } else if (response.statusCode >= 500) {
          // Server error - retry
          if (attempt < FirebaseConfig.maxRetries) {
            await Future.delayed(FirebaseConfig.retryDelay * attempt);
            continue;
          }
        }

        return false;
      } catch (e) {
        if (attempt == FirebaseConfig.maxRetries) {
          print('Failed to send FCM message after $FirebaseConfig.maxRetries attempts: $e');
          return false;
        }

        await Future.delayed(FirebaseConfig.retryDelay * attempt);
      }
    }

    return false;
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Notification priority levels
enum NotificationPriority {
  normal('normal'),
  high('high');

  const NotificationPriority(this.value);
  final String value;
}

