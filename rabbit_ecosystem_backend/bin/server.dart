import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../lib/src/database/database_manager.dart';
import '../lib/src/middleware/auth_middleware.dart';
import '../lib/src/middleware/role_middleware.dart';
import '../lib/src/middleware/api_route_middleware.dart';
import '../lib/src/routes/mobile_routes.dart';
import '../lib/src/routes/dashboard_routes.dart';

void main(List<String> args) async {
  // Initialize database
  await DatabaseManager.instance.initialize();
  
  final router = Router();
  
  // Health check endpoint
  router.get('/health', (Request request) {
    return Response.ok('Rabbit Ecosystem Backend is running!');
  });
  
  // Mobile API routes
  router.mount('/api/mobile/', MobileRoutes().router);
  
  // Dashboard API routes  
  router.mount('/api/dashboard/', DashboardRoutes().router);
  
  // Create middleware pipeline
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addMiddleware(ApiRouteMiddleware.middleware)
      .addHandler(router);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  
  print('Rabbit Ecosystem Backend serving at http://${server.address.host}:${server.port}');
}