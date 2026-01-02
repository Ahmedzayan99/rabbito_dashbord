import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'middleware/auth_middleware.dart';
import 'services/websocket_service.dart';

// /// WebSocket handler for real-time communication
// class WebSocketHandler {
//   final WebSocketService _webSocketService;
//
//   WebSocketHandler(this._webSocketService);
//
//   /// Handle WebSocket upgrade request
//   Handler get handler {
//     return webSocketHandler((WebSocketChannel webSocket) {
//       _handleWebSocketConnection(webSocket);
//     });
//   }
//
//   /// Handle WebSocket connection with authentication
//   Future<void> _handleWebSocketConnection(WebSocketChannel webSocket) async {
//     try {
//       // Extract user information from WebSocket upgrade request
//       // In a real implementation, you'd extract this from headers or query parameters
//       // that were validated during the HTTP upgrade request
//
//       // For now, assume anonymous connection
//       // In production, you'd validate JWT tokens here
//       String? userId;
//       String? userRole;
//
//       // Extract user info from WebSocket protocol or headers if available
//       // This is a simplified version
//
//       final socket = WebSocket.fromUpgradedSocket(
//         webSocket.sink,
//         protocol: webSocket.protocol,
//       );
//
//       await _webSocketService.handleConnection(
//         socket,
//         userId,
//         userRole != null ? _parseUserRole(userRole) : null,
//       );
//     } catch (e) {
//       print('Failed to handle WebSocket connection: $e');
//       webSocket.sink.close();
//     }
//   }
//
//   /// Authenticated WebSocket handler with JWT validation
//   Handler get authenticatedHandler {
//     return Pipeline()
//         .addMiddleware(_webSocketAuthMiddleware())
//         .addHandler(webSocketHandler((WebSocketChannel webSocket) {
//           _handleAuthenticatedWebSocketConnection(webSocket);
//         }));
//   }
//
//   /// Middleware to authenticate WebSocket connections
//   Middleware _webSocketAuthMiddleware() {
//     return (Handler innerHandler) {
//       return (Request request) async {
//         try {
//           // Extract token from query parameters or headers
//           final token = request.url.queryParameters['token'] ??
//                       request.headers['authorization']?.replaceFirst('Bearer ', '');
//
//           if (token == null) {
//             return Response.forbidden('No authentication token provided');
//           }
//
//           // Validate JWT token (simplified - in real implementation use AuthMiddleware)
//           // final user = await _validateJwtToken(token);
//
//           // For now, assume token is valid and extract user info
//           // In production, you'd decode and validate the JWT here
//           final userId = 'extracted_user_id'; // Extract from JWT
//           final userRole = 'customer'; // Extract from JWT
//
//           // Add user info to request context for the WebSocket handler
//           final authenticatedRequest = request.change(context: {
//             ...request.context,
//             'userId': userId,
//             'userRole': userRole,
//           });
//
//           return innerHandler(authenticatedRequest);
//         } catch (e) {
//           return Response.forbidden('Invalid authentication token');
//         }
//       };
//     };
//   }
//
//   /// Handle authenticated WebSocket connection
//   Future<void> _handleAuthenticatedWebSocketConnection(WebSocketChannel webSocket) async {
//     try {
//       // Extract user information from request context
//       final userId = webSocket.sink as dynamic; // This would come from middleware
//       final userRole = 'customer'; // This would come from middleware
//
//       final socket = WebSocket.fromUpgradedSocket(
//         webSocket.sink as WebSocketSink,
//         protocol: webSocket.protocol,
//       );
//
//       await _webSocketService.handleConnection(
//         socket,
//         userId as String?,
//         userRole != null ? _parseUserRole(userRole) : null,
//       );
//     } catch (e) {
//       print('Failed to handle authenticated WebSocket connection: $e');
//       webSocket.sink.close();
//     }
//   }
//
//   /// WebSocket route handler for specific endpoints
//   Handler get routeHandler {
//     return (Request request) {
//       final path = request.url.path;
//
//       switch (path) {
//         case '/ws':
//           return authenticatedHandler(request);
//         case '/ws/public':
//           return handler(request);
//         case '/ws/orders':
//           return _orderWebSocketHandler(request);
//         case '/ws/chat':
//           return _chatWebSocketHandler(request);
//         default:
//           return Response.notFound('WebSocket endpoint not found');
//       }
//     };
//   }
//
//   /// Order-specific WebSocket handler
//   Handler _orderWebSocketHandler(Request request) {
//     return Pipeline()
//         .addMiddleware(_webSocketAuthMiddleware())
//         .addHandler(webSocketHandler((WebSocketChannel webSocket) {
//           _handleOrderWebSocketConnection(webSocket, request);
//         }));
//   }
//
//   /// Chat-specific WebSocket handler
//   Handler _chatWebSocketHandler(Request request) {
//     return Pipeline()
//         .addMiddleware(_webSocketAuthMiddleware())
//         .addHandler(webSocketHandler((WebSocketChannel webSocket) {
//           _handleChatWebSocketConnection(webSocket, request);
//         }));
//   }
//
//   /// Handle order WebSocket connection
//   Future<void> _handleOrderWebSocketConnection(WebSocketChannel webSocket, Request request) async {
//     try {
//       final userId = 'extracted_user_id'; // From middleware
//       final userRole = 'customer'; // From middleware
//       final orderId = request.url.queryParameters['orderId'];
//
//       if (orderId == null) {
//         webSocket.sink.close(4000, 'Order ID required');
//         return;
//       }
//
//       final socket = WebSocket.fromUpgradedSocket(
//         webSocket.sink as WebSocketSink,
//         protocol: webSocket.protocol,
//       );
//
//       final client = await _webSocketService.handleConnection(
//         socket,
//         userId,
//         userRole != null ? _parseUserRole(userRole) : null,
//       );
//
//       // Subscribe to order updates
//       // Note: This would need to be modified based on WebSocketService API
//       // _webSocketService.subscribeToOrder(client.sessionId, orderId);
//
//     } catch (e) {
//       print('Failed to handle order WebSocket connection: $e');
//       webSocket.sink.close();
//     }
//   }
//
//   /// Handle chat WebSocket connection
//   Future<void> _handleChatWebSocketConnection(WebSocketChannel webSocket, Request request) async {
//     try {
//       final userId = 'extracted_user_id'; // From middleware
//       final userRole = 'customer'; // From middleware
//       final chatId = request.url.queryParameters['chatId'];
//
//       if (chatId == null) {
//         webSocket.sink.close(4000, 'Chat ID required');
//         return;
//       }
//
//       final socket = WebSocket.fromUpgradedSocket(
//         webSocket.sink as WebSocketSink,
//         protocol: webSocket.protocol,
//       );
//
//       final client = await _webSocketService.handleConnection(
//         socket,
//         userId,
//         userRole != null ? _parseUserRole(userRole) : null,
//       );
//
//       // Subscribe to chat updates
//       // Note: This would need to be modified based on WebSocketService API
//       // _webSocketService.subscribeToChat(client.sessionId, chatId);
//
//     } catch (e) {
//       print('Failed to handle chat WebSocket connection: $e');
//       webSocket.sink.close();
//     }
//   }
//
//   /// Parse user role from string
//   UserRole? _parseUserRole(String roleString) {
//     try {
//       return UserRole.values.firstWhere(
//         (role) => role.name == roleString,
//       );
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Get WebSocket statistics
//   Map<String, dynamic> getStatistics() {
//     return _webSocketService.getStatistics();
//   }
//
//   /// Shutdown WebSocket handler
//   void shutdown() {
//     _webSocketService.shutdown();
//   }
// }
//
// // Extension to add WebSocket support to Serverpod
// extension WebSocketSupport on WebSocket {
//   static WebSocket fromUpgradedSocket(WebSocketSink sink, {String? protocol}) {
//     // This is a simplified implementation
//     // In a real Serverpod setup, you'd use their WebSocket utilities
//     throw UnimplementedError('WebSocket.fromUpgradedSocket needs Serverpod implementation');
//   }
// }
//
// // Mock UserRole enum (should be imported from models)
// enum UserRole {
//   customer,
//   partner,
//   rider,
//   superAdmin,
//   admin,
//   finance,
//   support,
// }
//
