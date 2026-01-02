import 'dart:async';
import 'package:postgres/postgres.dart' hide Notification;
import '../models/notification.dart' as model;
import '../models/transaction.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository<model.Notification> {
  NotificationRepository(super.connection);

  @override
  String get tableName => 'notifications';

  @override
  model.Notification fromMap(Map<String, dynamic> map) {
    return model.Notification(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] != null ? model.NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => model.NotificationType.general,
      ) : model.NotificationType.general,
      status: model.NotificationStatus.sent,
      data: map['data'] as Map<String, dynamic>?,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  @override
  Map<String, dynamic> toMap(model.Notification notification) {
    return {
      'user_id': notification.userId,
      'title': notification.title,
      'message': notification.message,
      'type': notification.type?.name,
      'status': notification.status.name,
      'data': notification.data,
      'read_at': notification.readAt?.toIso8601String(),
      'created_at': notification.createdAt.toIso8601String(),
      'updated_at': notification.updatedAt?.toIso8601String(),
    };
  }

  /// Create a new notification
  Future<model.Notification> createNotification({
    required int userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    final result = await executeQuery('''
      INSERT INTO notifications (
        user_id, title, body, type, data, sent_at, created_at
      )
      VALUES (
        @user_id, @title, @body, @type, @data::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )
      RETURNING *
    ''', parameters: {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
    });

    if (result.isEmpty) {
      throw Exception('Failed to create notification');
    }

    return model.Notification.fromJson(result.first);
  }

  /// Create a new notification from request
  Future<model.Notification> createNotificationFromRequest(model.CreateNotificationRequest request) async {
    if (request.userId == null) {
      throw ArgumentError('userId is required for notification creation');
    }
    return await createNotification(
      userId: request.userId!,
      title: request.title,
      body: request.message,
      type: request.type.name,
      data: request.data,
    );
  }

  /// Find notification by ID
  Future<model.Notification?> findById(int id) async {
    final result = await executeQuery('''
      SELECT n.*, u.username as user_name
      FROM notifications n
      LEFT JOIN users u ON n.user_id = u.id
      WHERE n.id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) {
      return null;
    }

    return model.Notification.fromJson(result.first);
  }

  /// Find notifications by user ID
  Future<List<model.Notification>> findByUserId(
    int userId, {
    int? limit,
    int? offset,
    bool? onlyUnread,
  }) async {
    final conditions = <String>['n.user_id = @user_id'];
    final parameters = <String, dynamic>{'user_id': userId};

    if (onlyUnread == true) {
      conditions.add('n.is_read = false');
    }

    final whereClause = 'WHERE ${conditions.join(' AND ')}';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await executeQuery('''
      SELECT n.*, u.username as user_name
      FROM notifications n
      LEFT JOIN users u ON n.user_id = u.id
      $whereClause
      ORDER BY n.sent_at DESC
      $limitClause $offsetClause
    ''', parameters: parameters);

    return result.map((row) => model.Notification.fromJson(row)).toList();
  }

  /// Find notifications by type
  Future<List<model.Notification>> findByType(
    String type, {
    int? limit,
    int? offset,
  }) async {
    final result = await executeQuery('''
      SELECT n.*, u.username as user_name
      FROM notifications n
      LEFT JOIN users u ON n.user_id = u.id
      WHERE n.type = @type
      ORDER BY n.sent_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''', parameters: {'type': type});

    return result.map((row) => model.Notification.fromJson(row)).toList();
  }

  /// Mark notification as read
  Future<void> markAsRead(int id) async {
    await executeQuery('''
      UPDATE notifications
      SET is_read = true, read_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  /// Mark all notifications as read for user
  Future<int> markAllAsRead(int userId) async {
    final result = await executeQuery('''
      UPDATE notifications
      SET is_read = true, read_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = @user_id AND is_read = false
      RETURNING id
    ''', parameters: {'user_id': userId});

    return result.length;
  }

  /// Delete notification
  Future<bool> delete(int id) async {
    try {
      await executeQuery('''
        DELETE FROM notifications WHERE id = @id
      ''', parameters: {'id': id});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get unread notification count for user
  Future<int> getUnreadCount(int userId) async {
    final result = await executeQuery('''
      SELECT COUNT(*) as count
      FROM notifications
      WHERE user_id = @user_id AND is_read = false
    ''', parameters: {'user_id': userId});

    return result.first['count'] as int;
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (startDate != null) {
      conditions.add('sent_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('sent_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT
        COUNT(*) as total_notifications,
        COUNT(CASE WHEN is_read = true THEN 1 END) as read_notifications,
        COUNT(CASE WHEN is_read = false THEN 1 END) as unread_notifications,
        COUNT(DISTINCT user_id) as unique_users_notified,
        COUNT(DISTINCT CASE WHEN sent_at >= CURRENT_DATE THEN user_id END) as users_notified_today
      FROM notifications
      $whereClause
    ''', parameters: parameters);

    return result.first;
  }

  /// Get notification summary by type
  Future<List<Map<String, dynamic>>> getSummaryByType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (startDate != null) {
      conditions.add('sent_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('sent_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT
        type,
        COUNT(*) as count,
        COUNT(CASE WHEN is_read = true THEN 1 END) as read_count,
        COUNT(CASE WHEN is_read = false THEN 1 END) as unread_count
      FROM notifications
      $whereClause
      GROUP BY type
      ORDER BY count DESC
    ''', parameters: parameters);

    return result;
  }

  /// Get notifications by date range
  Future<List<model.Notification>> findByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    int? offset,
  }) async {
    final result = await executeQuery('''
      SELECT n.*, u.username as user_name
      FROM notifications n
      LEFT JOIN users u ON n.user_id = u.id
      WHERE n.sent_at >= @start_date AND n.sent_at <= @end_date
      ORDER BY n.sent_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''', parameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });

    return result.map((row) => model.Notification.fromJson(row)).toList();
  }

  /// Delete old notifications
  Future<int> deleteOldNotifications(DateTime cutoffDate) async {
    final result = await executeQuery('''
      DELETE FROM notifications
      WHERE sent_at < @cutoff_date AND is_read = true
      RETURNING id
    ''', parameters: {'cutoff_date': cutoffDate.toIso8601String()});

    return result.length;
  }

  /// Get notifications for admin (all users)
  Future<List<model.Notification>> findAll({
    int? limit,
    int? offset,
    String? type,
    bool? onlyUnread,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (type != null && type.isNotEmpty) {
      conditions.add('n.type = @type');
      parameters['type'] = type;
    }

    if (onlyUnread == true) {
      conditions.add('n.is_read = false');
    }

    if (startDate != null) {
      conditions.add('n.sent_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('n.sent_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await executeQuery('''
      SELECT n.*, u.username as user_name
      FROM notifications n
      LEFT JOIN users u ON n.user_id = u.id
      $whereClause
      ORDER BY n.sent_at DESC
      $limitClause $offsetClause
    ''', parameters: parameters);

    return result.map((row) => model.Notification.fromJson(row)).toList();
  }

  /// Count notifications with filters
  Future<int> countWithFilters({
    String? type,
    bool? onlyUnread,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (type != null && type.isNotEmpty) {
      conditions.add('type = @type');
      parameters['type'] = type;
    }

    if (onlyUnread == true) {
      conditions.add('is_read = false');
    }

    if (startDate != null) {
      conditions.add('sent_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('sent_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT COUNT(*) as count FROM notifications
      $whereClause
    ''', parameters: parameters);

    return result.first['count'] as int;
  }

  /// Get notification trends (daily/weekly/monthly)
  Future<List<Map<String, dynamic>>> getNotificationTrends({
    required String period, // 'daily', 'weekly', 'monthly'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dateFormat = switch (period) {
      'daily' => "DATE(sent_at)",
      'weekly' => "DATE_TRUNC('week', sent_at)",
      'monthly' => "DATE_TRUNC('month', sent_at)",
      _ => "DATE(sent_at)",
    };

    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (startDate != null) {
      conditions.add('sent_at >= @start_date');
      parameters['start_date'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      conditions.add('sent_at <= @end_date');
      parameters['end_date'] = endDate.toIso8601String();
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await executeQuery('''
      SELECT
        $dateFormat as period,
        COUNT(*) as total_sent,
        COUNT(CASE WHEN is_read = true THEN 1 END) as total_read,
        ROUND(
          COUNT(CASE WHEN is_read = true THEN 1 END)::decimal /
          NULLIF(COUNT(*), 0) * 100, 2
        ) as read_percentage
      FROM notifications
      $whereClause
      GROUP BY $dateFormat
      ORDER BY period DESC
      LIMIT 30
    ''', parameters: parameters);

    return result;
  }
}
