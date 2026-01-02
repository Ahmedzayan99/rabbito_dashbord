import 'dart:async';
import 'package:postgres/postgres.dart';
import '../models/notification.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository(PostgreSQLConnection connection) : super(connection);

  /// Create a new notification
  Future<Notification> create(CreateNotificationRequest request) async {
    final result = await executeQuery('''
      INSERT INTO notifications (
        user_id, title, body, type, data, sent_at, created_at
      )
      VALUES (
        @user_id, @title, @body, @type, @data::jsonb, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )
      RETURNING *
    ''', parameters: {
      'user_id': request.userId,
      'title': request.title,
      'body': request.body,
      'type': request.type,
      'data': request.data != null ? request.data : {},
    });

    if (result.isEmpty) {
      throw Exception('Failed to create notification');
    }

    return Notification.fromJson(result.first);
  }

  /// Find notification by ID
  Future<Notification?> findById(int id) async {
    final result = await executeQuery('''
      SELECT n.*, u.username as user_name
      FROM notifications n
      LEFT JOIN users u ON n.user_id = u.id
      WHERE n.id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) {
      return null;
    }

    return Notification.fromJson(result.first);
  }

  /// Find notifications by user ID
  Future<List<Notification>> findByUserId(
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

    return result.map((row) => Notification.fromJson(row)).toList();
  }

  /// Find notifications by type
  Future<List<Notification>> findByType(
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

    return result.map((row) => Notification.fromJson(row)).toList();
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
    ''', parameters: {'user_id': userId});

    return result.affectedRows;
  }

  /// Delete notification
  Future<void> delete(int id) async {
    await executeQuery('''
      DELETE FROM notifications WHERE id = @id
    ''', parameters: {'id': id});
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
  Future<List<Notification>> findByDateRange({
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

    return result.map((row) => Notification.fromJson(row)).toList();
  }

  /// Delete old notifications
  Future<int> deleteOldNotifications(DateTime cutoffDate) async {
    final result = await executeQuery('''
      DELETE FROM notifications
      WHERE sent_at < @cutoff_date AND is_read = true
    ''', parameters: {'cutoff_date': cutoffDate.toIso8601String()});

    return result.affectedRows;
  }

  /// Get notifications for admin (all users)
  Future<List<Notification>> findAll({
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

    return result.map((row) => Notification.fromJson(row)).toList();
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
