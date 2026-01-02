import 'dart:async';
import '../repositories/notification_repository.dart';
import '../repositories/user_repository.dart';
import '../services/firebase_service.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../models/user_role.dart';

/// Service for handling notifications and push messages
class NotificationService {
  final NotificationRepository _notificationRepository;
  final UserRepository _userRepository;
  final FirebaseService _firebaseService;

  NotificationService(
    NotificationRepository? notificationRepository,
    UserRepository? userRepository,
    FirebaseService? firebaseService,
  ) : _notificationRepository = notificationRepository ?? NotificationRepository(null as dynamic),
      _userRepository = userRepository ?? UserRepository(null as dynamic),
      _firebaseService = firebaseService ?? FirebaseService();

  /// Send notification to user
  Future<bool> sendNotification({
    required int userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification record
      final notification = await _notificationRepository.createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      // Get user device token (assuming it's stored in user profile)
      final user = await _userRepository.findById(userId);
      if (user == null) {
        return false;
      }

      // For now, assume FCM token is stored in user data
      // In real implementation, you'd have a separate device_tokens table
      final fcmToken = await _getUserFCMToken(userId);
      if (fcmToken == null) {
        // Notification saved but not sent (user might not have FCM token)
        return true;
      }

      // Send push notification
      final pushSent = await _firebaseService.sendToDevice(
        token: fcmToken,
        title: title,
        body: body,
        data: data,
      );

      // Update notification with push status
      if (pushSent) {
        // Mark as sent (you might want to add sent_at field)
      }

      return pushSent;
    } catch (e) {
      print('Failed to send notification: $e');
      return false;
    }
  }

  /// Send order status update notification
  Future<bool> sendOrderStatusUpdate({
    required int userId,
    required int orderId,
    required String status,
    required String customerName,
  }) async {
    final fcmToken = await _getUserFCMToken(userId);
    if (fcmToken == null) {
      // Save notification without sending push
      await _notificationRepository.createNotificationFromRequest(CreateNotificationRequest(
        userId: userId,
        title: 'Order Update',
        message: 'Hi $customerName, your order #$orderId status has been updated to: $status',
        type: NotificationType.orderUpdate,
        data: {
          'order_id': orderId.toString(),
          'status': status,
        },
      ));
      return true;
    }

    return await _firebaseService.sendOrderStatusUpdate(
      token: fcmToken,
      orderId: orderId,
      status: status,
      customerName: customerName,
    );
  }

  /// Send rider assignment notification
  Future<bool> sendRiderAssignment({
    required int userId,
    required int orderId,
    required String riderName,
    required String estimatedTime,
  }) async {
    final fcmToken = await _getUserFCMToken(userId);
    if (fcmToken == null) {
      await _notificationRepository.createNotificationFromRequest(CreateNotificationRequest(
        userId: userId,
        title: 'Rider Assigned',
        message: '$riderName has been assigned to deliver your order #$orderId. Estimated delivery: $estimatedTime',
        type: NotificationType.delivery,
        data: {
          'order_id': orderId.toString(),
          'rider_name': riderName,
          'estimated_time': estimatedTime,
        },
      ));
      return true;
    }

    return await _firebaseService.sendRiderAssignment(
      token: fcmToken,
      orderId: orderId,
      riderName: riderName,
      estimatedTime: estimatedTime,
    );
  }

  /// Send partner new order notification
  Future<bool> sendPartnerNewOrder({
    required int partnerId,
    required int orderId,
    required String customerName,
    required double orderAmount,
  }) async {
    final fcmToken = await _getUserFCMToken(partnerId);
    if (fcmToken == null) {
      await _notificationRepository.createNotificationFromRequest(CreateNotificationRequest(
        userId: partnerId,
        title: 'New Order',
        body: 'You have received a new order #$orderId from $customerName for SAR ${orderAmount.toStringAsFixed(2)}',
        type: NotificationType.orderUpdate,
        data: {
          'order_id': orderId.toString(),
          'customer_name': customerName,
          'amount': orderAmount.toString(),
        },
      ));
      return true;
    }

    return await _firebaseService.sendPartnerOrderNotification(
      token: fcmToken,
      orderId: orderId,
      customerName: customerName,
      orderAmount: orderAmount,
    );
  }

  /// Send promotional notification
  Future<bool> sendPromotion({
    required int userId,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final fcmToken = await _getUserFCMToken(userId);
    if (fcmToken == null) {
      await _notificationRepository.createNotificationFromRequest(CreateNotificationRequest(
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.general,
        data: data,
      ));
      return true;
    }

    return await _firebaseService.sendPromotion(
      token: fcmToken,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
    );
  }

  /// Send system alert
  Future<bool> sendSystemAlert({
    required int userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final fcmToken = await _getUserFCMToken(userId);
    if (fcmToken == null) {
      await _notificationRepository.createNotificationFromRequest(CreateNotificationRequest(
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.general,
        data: data,
      ));
      return true;
    }

    return await _firebaseService.sendSystemAlert(
      token: fcmToken,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send notification to multiple users
  Future<Map<int, bool>> sendBulkNotification({
    required List<int> userIds,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    final results = <int, bool>{};

    for (final userId in userIds) {
      final success = await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
      results[userId] = success;
    }

    return results;
  }

  /// Get user notifications
  Future<List<Notification>> getUserNotifications(
    int userId, {
    int? limit,
    int? offset,
    bool? onlyUnread,
  }) async {
    return await _notificationRepository.findByUserId(
      userId,
      limit: limit,
      offset: offset,
      onlyUnread: onlyUnread,
    );
  }

  /// Get all notifications (admin)
  Future<List<Notification>> getNotifications({
    int? limit,
    int? offset,
    String? type,
  }) async {
    return await _notificationRepository.findAll(
      limit: limit,
      offset: offset,
      type: type,
    );
  }

  /// Get notification by ID
  Future<Notification?> getNotificationById(int id) async {
    return await _notificationRepository.findById(id);
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId, int userId) async {
    try {
      final notification = await _notificationRepository.findById(notificationId);
      if (notification == null || notification.userId != userId) {
        return false;
      }

      await _notificationRepository.markAsRead(notificationId);
      return true;
    } catch (e) {
      print('Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Mark all user notifications as read
  Future<int> markAllAsRead(int userId) async {
    try {
      return await _notificationRepository.markAllAsRead(userId);
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
      return 0;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId, int userId) async {
    try {
      final notification = await _notificationRepository.findById(notificationId);
      if (notification == null || notification.userId != userId) {
        return false;
      }

      await _notificationRepository.delete(notificationId);
      return true;
    } catch (e) {
      print('Failed to delete notification: $e');
      return false;
    }
  }

  /// Get notification statistics for admin
  Future<Map<String, dynamic>> getNotificationStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _notificationRepository.getStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Send targeted notifications based on user segment
  Future<Map<int, bool>> sendTargetedNotification({
    required UserSegment segment,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    final userIds = await _getUsersBySegment(segment);
    return await sendBulkNotification(
      userIds: userIds,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  /// Subscribe user to topic
  Future<bool> subscribeToTopic(int userId, String topic) async {
    try {
      final fcmToken = await _getUserFCMToken(userId);
      if (fcmToken == null) {
        return false;
      }

      return await _firebaseService.subscribeToTopic(
        token: fcmToken,
        topic: topic,
      );
    } catch (e) {
      print('Failed to subscribe to topic: $e');
      return false;
    }
  }

  /// Unsubscribe user from topic
  Future<bool> unsubscribeFromTopic(int userId, String topic) async {
    try {
      final fcmToken = await _getUserFCMToken(userId);
      if (fcmToken == null) {
        return false;
      }

      return await _firebaseService.unsubscribeFromTopic(
        token: fcmToken,
        topic: topic,
      );
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
      return false;
    }
  }

  /// Get unread notification count for user
  Future<int> getUnreadCount(int userId) async {
    try {
      return await _notificationRepository.getUnreadCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// Helper method to get user's FCM token
  /// In a real implementation, this would query a device_tokens table
  Future<String?> _getUserFCMToken(int userId) async {
    try {
      // This is a placeholder - in real implementation, you'd have:
      // final deviceTokens = await _deviceTokenRepository.findByUserId(userId);
      // return deviceTokens.isNotEmpty ? deviceTokens.first.token : null;

      // For now, return null to indicate no token available
      return null;
    } catch (e) {
      print('Failed to get FCM token for user $userId: $e');
      return null;
    }
  }

  /// Helper method to get users by segment
  Future<List<int>> _getUsersBySegment(UserSegment segment) async {
    try {
      switch (segment) {
        case UserSegment.allCustomers:
          final customers = await _userRepository.findByRole(UserRole.customer);
          return customers.map((u) => u.id).toList();

        case UserSegment.allPartners:
          final partners = await _userRepository.findByRole(UserRole.partner);
          return partners.map((u) => u.id).toList();

        case UserSegment.allRiders:
          final riders = await _userRepository.findByRole(UserRole.rider);
          return riders.map((u) => u.id).toList();

        case UserSegment.activeUsers:
          final activeUsers = await _userRepository.findActiveUsers();
          return activeUsers.map((u) => u.id).toList();

        default:
          return [];
      }
    } catch (e) {
      print('Failed to get users by segment: $e');
      return [];
    }
  }

  /// Cleanup old notifications
  Future<int> cleanupOldNotifications({Duration? olderThan}) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
      return await _notificationRepository.deleteOldNotifications(cutoffDate);
    } catch (e) {
      print('Failed to cleanup old notifications: $e');
      return 0;
    }
  }
}

/// User segments for targeted notifications
enum UserSegment {
  allCustomers,
  allPartners,
  allRiders,
  activeUsers,
  inactiveUsers,
  highValueCustomers,
  newUsers,
}