import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../models/order.dart';
import '../models/notification.dart';

/// WebSocket message types
enum WebSocketMessageType {
  orderUpdate('order_update'),
  orderStatusChange('order_status_change'),
  riderLocationUpdate('rider_location_update'),
  chatMessage('chat_message'),
  notification('notification'),
  userOnline('user_online'),
  userOffline('user_offline'),
  ping('ping'),
  pong('pong'),
  error('error');

  const WebSocketMessageType(this.value);
  final String value;

  static WebSocketMessageType fromString(String value) {
    return WebSocketMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => WebSocketMessageType.error,
    );
  }
}

/// WebSocket message
class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  WebSocketMessage({
    required this.type,
    required this.data,
    this.userId,
    this.sessionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketMessageType.fromString(json['type'] ?? 'error'),
      data: json['data'] ?? {},
      userId: json['userId'],
      sessionId: json['sessionId'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'data': data,
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage(type: ${type.value}, data: $data, userId: $userId)';
  }
}

/// WebSocket client connection
class WebSocketClient {
  final WebSocket socket;
  final String? userId;
  final String sessionId;
  final UserRole? userRole;
  final DateTime connectedAt;
  DateTime lastActivity;
  bool isAlive = true;

  WebSocketClient({
    required this.socket,
    this.userId,
    required this.sessionId,
    this.userRole,
    DateTime? connectedAt,
  })  : connectedAt = connectedAt ?? DateTime.now(),
        lastActivity = DateTime.now();

  void updateActivity() {
    lastActivity = DateTime.now();
  }

  bool get isStale => DateTime.now().difference(lastActivity) > Duration(minutes: 30);

  Future<void> sendMessage(WebSocketMessage message) async {
    try {
      if (!isAlive) return;

      final jsonMessage = jsonEncode(message.toJson());
      socket.add(jsonMessage);
      updateActivity();
    } catch (e) {
      isAlive = false;
      print('Failed to send message to client $sessionId: $e');
    }
  }

  void dispose() {
    try {
      socket.close();
    } catch (e) {
      print('Error closing WebSocket: $e');
    }
    isAlive = false;
  }
}

/// WebSocket service for real-time communication
class WebSocketService {
  final Map<String, WebSocketClient> _clients = {};
  final Map<String, Set<String>> _userSessions = {}; // userId -> Set<sessionId>
  final Map<String, Set<String>> _roleSubscriptions = {}; // role -> Set<sessionId>
  final Map<String, Set<String>> _orderSubscriptions = {}; // orderId -> Set<sessionId>
  final Map<String, Set<String>> _chatSubscriptions = {}; // chatId -> Set<sessionId>

  Timer? _pingTimer;
  Timer? _cleanupTimer;

  /// Initialize WebSocket service
  void initialize() {
    // Start ping timer to keep connections alive
    _pingTimer = Timer.periodic(Duration(seconds: 30), _sendPingToAll);

    // Start cleanup timer to remove stale connections
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), _cleanupStaleConnections);
  }

  /// Handle new WebSocket connection
  Future<void> handleConnection(WebSocket socket, String? userId, UserRole? userRole) async {
    final sessionId = _generateSessionId();
    final client = WebSocketClient(
      socket: socket,
      userId: userId,
      sessionId: sessionId,
      userRole: userRole,
    );

    _clients[sessionId] = client;

    // Track user sessions
    if (userId != null) {
      _userSessions.putIfAbsent(userId, () => {}).add(sessionId);
    }

    // Track role subscriptions
    if (userRole != null) {
      _roleSubscriptions.putIfAbsent(userRole.name, () => {}).add(sessionId);
    }

    print('WebSocket client connected: $sessionId, user: $userId, role: $userRole');

    // Send welcome message
    await client.sendMessage(WebSocketMessage(
      type: WebSocketMessageType.userOnline,
      data: {
        'sessionId': sessionId,
        'connectedAt': client.connectedAt.toIso8601String(),
      },
      userId: userId,
      sessionId: sessionId,
    ));

    // Listen for messages
    try {
      await for (final message in socket) {
        await _handleMessage(client, message);
      }
    } catch (e) {
      print('WebSocket error for session $sessionId: $e');
    } finally {
      await _handleDisconnection(sessionId);
    }
  }

  /// Handle incoming WebSocket message
  Future<void> _handleMessage(WebSocketClient client, dynamic message) async {
    try {
      client.updateActivity();

      final messageData = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(messageData);

      switch (wsMessage.type) {
        case WebSocketMessageType.ping:
          await client.sendMessage(WebSocketMessage(
            type: WebSocketMessageType.pong,
            data: {},
            userId: client.userId,
            sessionId: client.sessionId,
          ));
          break;

        case WebSocketMessageType.pong:
          // Client responded to ping, connection is alive
          break;

        case WebSocketMessageType.chatMessage:
          await _handleChatMessage(client, wsMessage);
          break;

        default:
          // Echo message back or handle other message types
          await client.sendMessage(WebSocketMessage(
            type: WebSocketMessageType.error,
            data: {'error': 'Unknown message type: ${wsMessage.type.value}'},
            userId: client.userId,
            sessionId: client.sessionId,
          ));
      }
    } catch (e) {
      await client.sendMessage(WebSocketMessage(
        type: WebSocketMessageType.error,
        data: {'error': 'Invalid message format: $e'},
        userId: client.userId,
        sessionId: client.sessionId,
      ));
    }
  }

  /// Handle chat message
  Future<void> _handleChatMessage(WebSocketClient client, WebSocketMessage message) async {
    final chatId = message.data['chatId'] as String?;
    final content = message.data['content'] as String?;
    final recipientId = message.data['recipientId'] as String?;

    if (chatId == null || content == null || recipientId == null) {
      await client.sendMessage(WebSocketMessage(
        type: WebSocketMessageType.error,
        data: {'error': 'Missing required chat message fields'},
        userId: client.userId,
        sessionId: client.sessionId,
      ));
      return;
    }

    // Forward message to recipient
    await sendToUser(recipientId, WebSocketMessage(
      type: WebSocketMessageType.chatMessage,
      data: {
        'chatId': chatId,
        'content': content,
        'senderId': client.userId,
        'timestamp': message.timestamp.toIso8601String(),
      },
    ));

    // Send confirmation to sender
    await client.sendMessage(WebSocketMessage(
      type: WebSocketMessageType.chatMessage,
      data: {
        'chatId': chatId,
        'content': content,
        'delivered': true,
        'timestamp': message.timestamp.toIso8601String(),
      },
      userId: client.userId,
      sessionId: client.sessionId,
    ));
  }

  /// Handle client disconnection
  Future<void> _handleDisconnection(String sessionId) async {
    final client = _clients.remove(sessionId);
    if (client == null) return;

    print('WebSocket client disconnected: $sessionId, user: ${client.userId}');

    // Remove from user sessions
    if (client.userId != null) {
      _userSessions[client.userId]?.remove(sessionId);
      if (_userSessions[client.userId]?.isEmpty ?? false) {
        _userSessions.remove(client.userId);
      }
    }

    // Remove from role subscriptions
    if (client.userRole != null) {
      _roleSubscriptions[client.userRole!.name]?.remove(sessionId);
      if (_roleSubscriptions[client.userRole!.name]?.isEmpty ?? false) {
        _roleSubscriptions.remove(client.userRole!.name);
      }
    }

    // Clean up subscriptions
    _orderSubscriptions.values.forEach((sessions) => sessions.remove(sessionId));
    _chatSubscriptions.values.forEach((sessions) => sessions.remove(sessionId));

    // Remove empty sets
    _orderSubscriptions.removeWhere((key, value) => value.isEmpty);
    _chatSubscriptions.removeWhere((key, value) => value.isEmpty);

    client.dispose();
  }

  /// Send message to specific user
  Future<void> sendToUser(String userId, WebSocketMessage message) async {
    final sessions = _userSessions[userId];
    if (sessions == null) return;

    final futures = <Future>[];
    for (final sessionId in sessions) {
      final client = _clients[sessionId];
      if (client != null && client.isAlive) {
        futures.add(client.sendMessage(message));
      }
    }

    await Future.wait(futures);
  }

  /// Send message to users with specific role
  Future<void> sendToRole(UserRole role, WebSocketMessage message) async {
    final sessions = _roleSubscriptions[role.name];
    if (sessions == null) return;

    final futures = <Future>[];
    for (final sessionId in sessions) {
      final client = _clients[sessionId];
      if (client != null && client.isAlive) {
        futures.add(client.sendMessage(message));
      }
    }

    await Future.wait(futures);
  }

  /// Send message to users subscribed to specific order
  Future<void> sendToOrderSubscribers(String orderId, WebSocketMessage message) async {
    final sessions = _orderSubscriptions[orderId];
    if (sessions == null) return;

    final futures = <Future>[];
    for (final sessionId in sessions) {
      final client = _clients[sessionId];
      if (client != null && client.isAlive) {
        futures.add(client.sendMessage(message));
      }
    }

    await Future.wait(futures);
  }

  /// Subscribe client to order updates
  void subscribeToOrder(String sessionId, String orderId) {
    _orderSubscriptions.putIfAbsent(orderId, () => {}).add(sessionId);
  }

  /// Unsubscribe client from order updates
  void unsubscribeFromOrder(String sessionId, String orderId) {
    _orderSubscriptions[orderId]?.remove(sessionId);
    if (_orderSubscriptions[orderId]?.isEmpty ?? false) {
      _orderSubscriptions.remove(orderId);
    }
  }

  /// Subscribe client to chat
  void subscribeToChat(String sessionId, String chatId) {
    _chatSubscriptions.putIfAbsent(chatId, () => {}).add(sessionId);
  }

  /// Unsubscribe client from chat
  void unsubscribeFromChat(String sessionId, String chatId) {
    _chatSubscriptions[chatId]?.remove(sessionId);
    if (_chatSubscriptions[chatId]?.isEmpty ?? false) {
      _chatSubscriptions.remove(chatId);
    }
  }

  /// Broadcast order status update
  Future<void> broadcastOrderStatusUpdate(Order order) async {
    final message = WebSocketMessage(
      type: WebSocketMessageType.orderStatusChange,
      data: {
        'orderId': order.id.toString(),
        'status': order.status.name,
        'customerId': order.customerId.toString(),
        'partnerId': order.partnerId.toString(),
        'riderId': order.riderId?.toString(),
        'updatedAt': order.updatedAt.toIso8601String(),
      },
    );

    // Send to customer
    await sendToUser(order.customerId.toString(), message);

    // Send to partner if assigned
    if (order.partnerId != null) {
      await sendToUser(order.partnerId.toString(), message);
    }

    // Send to rider if assigned
    if (order.riderId != null) {
      await sendToUser(order.riderId.toString(), message);
    }

    // Send to order subscribers
    await sendToOrderSubscribers(order.id.toString(), message);
  }

  /// Broadcast rider location update
  Future<void> broadcastRiderLocation({
    required String riderId,
    required String orderId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  }) async {
    final message = WebSocketMessage(
      type: WebSocketMessageType.riderLocationUpdate,
      data: {
        'riderId': riderId,
        'orderId': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Send to customer and partner
    await sendToOrderSubscribers(orderId, message);
  }

  /// Broadcast notification
  Future<void> broadcastNotification(String userId, Notification notification) async {
    final message = WebSocketMessage(
      type: WebSocketMessageType.notification,
      data: {
        'notificationId': notification.id.toString(),
        'title': notification.title,
        'body': notification.body,
        'type': notification.type,
        'data': notification.data,
        'sentAt': notification.sentAt.toIso8601String(),
      },
      userId: userId,
    );

    await sendToUser(userId, message);
  }

  /// Send ping to all clients
  void _sendPingToAll(Timer timer) {
    final message = WebSocketMessage(
      type: WebSocketMessageType.ping,
      data: {'timestamp': DateTime.now().toIso8601String()},
    );

    final futures = <Future>[];
    for (final client in _clients.values) {
      if (client.isAlive) {
        futures.add(client.sendMessage(message));
      }
    }

    Future.wait(futures).catchError((error) {
      print('Error sending ping to clients: $error');
    });
  }

  /// Clean up stale connections
  void _cleanupStaleConnections(Timer timer) {
    final staleSessions = <String>[];

    for (final entry in _clients.entries) {
      if (entry.value.isStale) {
        staleSessions.add(entry.key);
      }
    }

    for (final sessionId in staleSessions) {
      print('Cleaning up stale connection: $sessionId');
      _handleDisconnection(sessionId);
    }

    if (staleSessions.isNotEmpty) {
      print('Cleaned up ${staleSessions.length} stale WebSocket connections');
    }
  }

  /// Get connection statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalConnections': _clients.length,
      'activeConnections': _clients.values.where((c) => c.isAlive).length,
      'userSessions': _userSessions.length,
      'roleSubscriptions': _roleSubscriptions.length,
      'orderSubscriptions': _orderSubscriptions.length,
      'chatSubscriptions': _chatSubscriptions.length,
    };
  }

  /// Shutdown WebSocket service
  void shutdown() {
    _pingTimer?.cancel();
    _cleanupTimer?.cancel();

    for (final client in _clients.values) {
      client.dispose();
    }

    _clients.clear();
    _userSessions.clear();
    _roleSubscriptions.clear();
    _orderSubscriptions.clear();
    _chatSubscriptions.clear();

    print('WebSocket service shutdown');
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'ws_${DateTime.now().millisecondsSinceEpoch}_${_clients.length}';
  }

  /// Get connected users count
  int getConnectedUsersCount() {
    return _userSessions.length;
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    return _userSessions.containsKey(userId);
  }

  /// Get online users
  List<String> getOnlineUsers() {
    return _userSessions.keys.toList();
  }
}
