import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'routes/api_routes.dart';
import 'routes/mobile_routes.dart';
import 'routes/dashboard_routes.dart';

// This is the starting point of your Shelf server.
void main(List<String> args) async {
  // Create API routes
  final apiRoutes = ApiRoutes();
  final mobileRoutes = MobileRoutes();
  final dashboardRoutes = DashboardRoutes();

  // Create handler with CORS
  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler((Request request) {
        // Route to appropriate handler based on path
        if (request.url.path.startsWith('api/mobile')) {
          return mobileRoutes.router(request);
        } else if (request.url.path.startsWith('api/dashboard')) {
          return dashboardRoutes.router(request);
        } else {
          return apiRoutes.router(request);
        }
      });

  // Start server
  final server = await shelf_io.serve(handler, 'localhost', 8080);
  print('Server running on http://localhost:8080');
}