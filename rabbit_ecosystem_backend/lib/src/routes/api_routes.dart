import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/permission_middleware.dart';
import '../controllers/user_controller.dart';
import '../controllers/partner_controller.dart';
import '../controllers/mobile/order_controller.dart';
import '../controllers/mobile/product_controller.dart';
import '../controllers/dashboard/analytics_controller.dart';
import '../controllers/dashboard/user_management_controller.dart';
import '../controllers/dashboard/partner_management_controller.dart';
import '../controllers/dashboard/order_management_controller.dart';
import '../controllers/dashboard/product_management_controller.dart';
import '../models/user_role.dart';

/// Main API routes configuration with role-based access control
class ApiRoutes {
  ApiRoutes();

  Router get router {
    final router = Router();

    // Public routes (no authentication required)
    router.get('/health', _healthCheck);
    router.post('/auth/login', UserController.login);
    router.post('/auth/register', UserController.register);
    router.post('/auth/refresh', UserController.refreshToken);

    // Mobile API routes (requires mobile access)
    router.mount('/api/mobile/', _mobileRoutes());

    // Dashboard API routes (requires dashboard access)
    router.mount('/api/dashboard/', _dashboardRoutes());

    return router;
  }

  /// Mobile API routes for customers, partners, and riders
  Router _mobileRoutes() {
    final router = Router();
    final pipeline = Pipeline();

    // Authentication routes
    router.post('/auth/logout', UserController.logout);
    router.get('/auth/me', UserController.getCurrentUser);

    // User profile routes
    router.get('/user/profile', UserController.getProfile);
    router.put('/user/profile',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('profile.update'))
            .addHandler(UserController.updateProfile));

    // Address management routes
    router.get('/user/addresses',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('addresses.read'))
            .addHandler(UserController.getAddresses));
    router.post('/user/addresses',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('addresses.create'))
            .addHandler(UserController.createAddress));
    router.put('/user/addresses/<addressId>',
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('addresses.update'))
            .addHandler(UserController.updateAddress));
    router.delete('/user/addresses/<addressId>',
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('addresses.delete'))
            .addHandler(UserController.deleteAddress));

    // Partner routes
    router.get('/partners', PartnerManagementController.getPartners);
    router.get('/partners/<partnerId>', PartnerManagementController.getPartner);
    router.get('/partners/<partnerId>/products', ProductManagementController.getPartnerProducts);

    // Product routes
    router.get('/products/<productId>', ProductManagementController.getProduct);
    // TODO: Implement getCategories method
    // router.get('/categories', ProductManagementController.getCategories);

    // Order routes for customers
    router.post('/orders',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.create'))
            .addHandler(OrderController.createOrder));
    router.get('/orders',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(OrderController.getUserOrders));
    router.get('/orders/<orderId>',
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('orders.read'))
            .addHandler(OrderController.getOrder));
    // TODO: Implement cancelOrder method
    // router.put('/orders/<orderId>/cancel',
    //     pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('orders.update'))
    //         .addHandler(OrderController.cancelOrder));

    // Partner-specific routes
    // TODO: Implement getPartnerOrders method
    // router.get('/partner/orders',
    //     pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.partner))
    //         .addHandler(OrderController.getPartnerOrders));
    // TODO: Implement updateOrderStatus method in OrderController
    // router.put('/partner/orders/<orderId>/status',
    //     pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.partner))
    //         .addHandler(OrderController.updateOrderStatus));

    // Partner product management
    // TODO: Implement these methods in ProductController
    // router.get('/partner/products',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.read'))
    //         .addHandler(ProductController.getMyProducts));
    // router.post('/partner/products',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.create'))
    //         .addHandler(ProductController.createProduct));
    // router.put('/partner/products/<productId>',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.update'))
    //         .addHandler(ProductController.updateProduct));
    // router.delete('/partner/products/<productId>',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.delete'))
    //         .addHandler(ProductController.deleteProduct));

    // Rider-specific routes
    // TODO: Implement these methods in OrderController
    // router.get('/rider/orders',
    //     pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.rider))
    //         .addHandler(OrderController.getRiderOrders));
    // router.put('/rider/orders/<orderId>/accept',
    //     pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.rider))
    //         .addHandler(OrderController.acceptOrder));
    // router.put('/rider/orders/<orderId>/complete',
    //     Pipeline()
    //         .addMiddleware(AuthMiddleware.middleware)
    //         .addMiddleware(PermissionMiddleware.requireMobileAccess())
    //         .addMiddleware(PermissionMiddleware.requireRole(UserRole.rider))
    //         .addHandler(OrderController.completeOrder));

    return router;
  }

  /// Dashboard API routes for admin, staff, and management
  Handler _dashboardRoutes() {
    final router = Router();

    // Apply authentication and dashboard access middleware
    final pipeline = Pipeline()
        .addMiddleware(AuthMiddleware.middleware)
        .addMiddleware(PermissionMiddleware.requireDashboardAccess());

    // Analytics routes
    router.get('/analytics/overview',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(AnalyticsController.getOverview));
    router.get('/analytics/sales',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(AnalyticsController.getSalesReport));
    router.get('/analytics/users',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(AnalyticsController.getUserAnalytics));
    router.get('/analytics/orders',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(AnalyticsController.getOrderAnalytics));
    router.get('/analytics/revenue',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(AnalyticsController.getRevenueAnalytics));
    router.get('/analytics/partners',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(AnalyticsController.getPartnerAnalytics));

    // User management routes
    router.get('/users',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.read'))
            .addHandler(UserManagementController.getUsers));
    router.post('/users',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.create'))
            .addHandler(UserManagementController.createUser));
    router.get('/users/<userId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.read'))
            .addHandler(UserManagementController.getUser));
    router.put('/users/<userId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(UserManagementController.updateUser));
    router.delete('/users/<userId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.delete'))
            .addHandler(UserManagementController.deleteUser));

    // Additional user management routes
    router.get('/users/statistics',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(UserManagementController.getUserStatistics));
    router.put('/users/<userId>/activate',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(UserManagementController.activateUser));
    router.put('/users/<userId>/deactivate',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(UserManagementController.deactivateUser));
    router.put('/users/<userId>/role',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(UserManagementController.updateUserRole));

    // Partner management routes
    router.get('/partners',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(PartnerManagementController.getPartners));
    router.post('/partners',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.create'))
            .addHandler(PartnerManagementController.createPartner));
    router.get('/partners/<partnerId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(PartnerManagementController.getPartner));
    router.put('/partners/<partnerId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.update'))
            .addHandler(PartnerManagementController.updatePartner));
    router.put('/partners/<partnerId>/status',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.update'))
            .addHandler(PartnerManagementController.updatePartnerStatus));
    router.delete('/partners/<partnerId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.delete'))
            .addHandler(PartnerManagementController.deletePartner));

    // Additional partner management routes
    router.get('/partners/<partnerId>/statistics',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(PartnerManagementController.getPartnerStatistics));
    router.get('/partners/<partnerId>/orders',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(PartnerManagementController.getPartnerOrders));
    router.get('/partners/pending',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(PartnerManagementController.getPendingPartners));
    router.post('/partners/<partnerId>/approve',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.approve'))
            .addHandler(PartnerManagementController.approvePartner));
    router.post('/partners/<partnerId>/reject',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.approve'))
            .addHandler(PartnerManagementController.rejectPartner));
    router.get('/partners/active',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(PartnerManagementController.getActivePartners));
    router.get('/partners/nearby',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(PartnerManagementController.getNearbyPartners));

    // Order management routes
    // TODO: Implement these methods in OrderController
    // router.get('/orders',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
    //         .addHandler(OrderController.getAllOrders));
    router.get('/orders/<orderId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(OrderController.getOrder));
    // router.put('/orders/<orderId>/status',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.update'))
    //         .addHandler(OrderController.updateOrderStatus));
    // router.post('/orders/<orderId>/assign-rider',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.update'))
    //         .addHandler(OrderController.assignRider));

    // Product management routes
    // TODO: Implement these methods in ProductController
    // router.get('/products',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.read'))
    //         .addHandler(ProductController.getAllProducts));
    // router.post('/products',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.create'))
    //         .addHandler(ProductController.createProduct));
    // router.put('/products/<productId>',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.update'))
    //         .addHandler(ProductController.updateProduct));
    // router.delete('/products/<productId>',
    //     pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.delete'))
    //         .addHandler(ProductController.deleteProduct));

    // Transaction management routes (finance role)
    router.get('/transactions', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('transactions.read'))
            .addHandler(_getTransactions));
    router.put('/transactions/<transactionId>', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('transactions.update'))
            .addHandler(_updateTransaction));

    // System settings routes (super admin only)
    router.get('/settings', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.superAdmin))
            .addHandler(_getSettings));
    router.put('/settings', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.superAdmin))
            .addHandler(_updateSettings));

    return pipeline.addHandler(router);
  }

  // Health check handler
  static Response _healthCheck(Request request) {
    return Response.ok('{"status": "healthy", "timestamp": "${DateTime.now().toIso8601String()}"}',
        headers: {'Content-Type': 'application/json'});
  }

  static Response _getTransactions(Request request) {
    return Response.ok('{"message": "Transactions endpoint"}',
        headers: {'Content-Type': 'application/json'});
  }

  static Response _updateTransaction(Request request) {
    return Response.ok('{"message": "Update transaction endpoint"}',
        headers: {'Content-Type': 'application/json'});
  }

  static Response _getSettings(Request request) {
    return Response.ok('{"message": "Settings endpoint"}',
        headers: {'Content-Type': 'application/json'});
  }

  static Response _updateSettings(Request request) {
    return Response.ok('{"message": "Update settings endpoint"}',
        headers: {'Content-Type': 'application/json'});
  }
}