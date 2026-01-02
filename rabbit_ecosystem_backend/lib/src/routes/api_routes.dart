import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/permission_middleware.dart';
import '../controllers/user_controller.dart';
import '../controllers/partner_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/dashboard/analytics_controller.dart';
import '../models/user_role.dart';

/// Main API routes configuration with role-based access control
class ApiRoutes {
  final UserController _userController;
  final PartnerController _partnerController;
  final OrderController _orderController;
  final ProductController _productController;
  final AnalyticsController _analyticsController;

  ApiRoutes(
    this._userController,
    this._partnerController,
    this._orderController,
    this._productController,
  ) : _analyticsController = AnalyticsController();

  Router get router {
    final router = Router();

    // Public routes (no authentication required)
    router.get('/health', _healthCheck);
    router.post('/auth/login', _userController.login);
    router.post('/auth/register', _userController.register);
    router.post('/auth/refresh', _userController.refreshToken);

    // Mobile API routes (requires mobile access)
    router.mount('/api/mobile/', _mobileRoutes());

    // Dashboard API routes (requires dashboard access)
    router.mount('/api/dashboard/', _dashboardRoutes());

    return router;
  }

  /// Mobile API routes for customers, partners, and riders
  Router _mobileRoutes() {
    final router = Router();

    // Apply authentication and mobile access middleware to all mobile routes
    final pipeline = Pipeline()
        .addMiddleware(AuthMiddleware.authenticate())
        .addMiddleware(PermissionMiddleware.requireMobileAccess());

    // Authentication routes
    router.post('/auth/logout', _userController.logout);
    router.get('/auth/me', _userController.getCurrentUser);

    // User profile routes
    router.get('/user/profile', _userController.getProfile);
    router.put('/user/profile', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('profile.update'))
            .addHandler(_userController.updateProfile));

    // Address management routes
    router.get('/user/addresses', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('addresses.read'))
            .addHandler(_userController.getAddresses));
    router.post('/user/addresses', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('addresses.create'))
            .addHandler(_userController.createAddress));
    router.put('/user/addresses/<addressId>', 
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('addresses.update'))
            .addHandler(_userController.updateAddress));
    router.delete('/user/addresses/<addressId>', 
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('addresses.delete'))
            .addHandler(_userController.deleteAddress));

    // Partner routes
    router.get('/partners', _partnerController.getPartners);
    router.get('/partners/<partnerId>', _partnerController.getPartner);
    router.get('/partners/<partnerId>/products', _productController.getPartnerProducts);

    // Product routes
    router.get('/products/<productId>', _productController.getProduct);
    router.get('/categories', _productController.getCategories);

    // Order routes for customers
    router.post('/orders', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.create'))
            .addHandler(_orderController.createOrder));
    router.get('/orders', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(_orderController.getUserOrders));
    router.get('/orders/<orderId>', 
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('orders.read'))
            .addHandler(_orderController.getOrder));
    router.put('/orders/<orderId>/cancel', 
        pipeline.addMiddleware(PermissionMiddleware.requireOwnershipOrPermission('orders.update'))
            .addHandler(_orderController.cancelOrder));

    // Partner-specific routes
    router.get('/partner/orders', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.partner))
            .addHandler(_orderController.getPartnerOrders));
    router.put('/partner/orders/<orderId>/status', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.partner))
            .addHandler(_orderController.updateOrderStatus));

    // Partner product management
    router.get('/partner/products', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.read'))
            .addHandler(_productController.getMyProducts));
    router.post('/partner/products', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.create'))
            .addHandler(_productController.createProduct));
    router.put('/partner/products/<productId>', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.update'))
            .addHandler(_productController.updateProduct));
    router.delete('/partner/products/<productId>', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.delete'))
            .addHandler(_productController.deleteProduct));

    // Rider-specific routes
    router.get('/rider/orders', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.rider))
            .addHandler(_orderController.getRiderOrders));
    router.put('/rider/orders/<orderId>/accept', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.rider))
            .addHandler(_orderController.acceptOrder));
    router.put('/rider/orders/<orderId>/complete', 
        pipeline.addMiddleware(PermissionMiddleware.requireRole(UserRole.rider))
            .addHandler(_orderController.completeOrder));

    return pipeline.addHandler(router);
  }

  /// Dashboard API routes for admin, staff, and management
  Router _dashboardRoutes() {
    final router = Router();

    // Apply authentication and dashboard access middleware
    final pipeline = Pipeline()
        .addMiddleware(AuthMiddleware.authenticate())
        .addMiddleware(PermissionMiddleware.requireDashboardAccess());

    // Analytics routes
    router.get('/analytics/overview',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_analyticsController.getOverview));
    router.get('/analytics/sales',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_analyticsController.getSalesReport));
    router.get('/analytics/users',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_analyticsController.getUserAnalytics));
    router.get('/analytics/orders',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_analyticsController.getOrderAnalytics));
    router.get('/analytics/revenue',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_analyticsController.getRevenueAnalytics));
    router.get('/analytics/partners',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_analyticsController.getPartnerAnalytics));

    // User management routes
    router.get('/users',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.read'))
            .addHandler(_userController.getUsers));
    router.post('/users',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.create'))
            .addHandler(_userController.createUser));
    router.get('/users/<userId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.read'))
            .addHandler(_userController.getUser));
    router.put('/users/<userId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(_userController.updateUser));
    router.delete('/users/<userId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.delete'))
            .addHandler(_userController.deleteUser));

    // Additional user management routes
    router.get('/users/statistics',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('analytics.read'))
            .addHandler(_userController.getUserStatistics));
    router.put('/users/<userId>/activate',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(_userController.activateUser));
    router.put('/users/<userId>/deactivate',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(_userController.deactivateUser));
    router.put('/users/<userId>/role',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('users.update'))
            .addHandler(_userController.updateUserRole));

    // Partner management routes
    router.get('/partners',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(_partnerController.getPartners));
    router.post('/partners',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.create'))
            .addHandler(_partnerController.createPartner));
    router.get('/partners/<partnerId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(_partnerController.getPartner));
    router.put('/partners/<partnerId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.update'))
            .addHandler(_partnerController.updatePartner));
    router.put('/partners/<partnerId>/status',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.update'))
            .addHandler(_partnerController.updatePartnerStatus));
    router.delete('/partners/<partnerId>',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.delete'))
            .addHandler(_partnerController.deletePartner));

    // Additional partner management routes
    router.get('/partners/<partnerId>/statistics',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(_partnerController.getPartnerStatistics));
    router.get('/partners/<partnerId>/orders',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(_partnerController.getPartnerOrders));
    router.get('/partners/pending',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(_partnerController.getPendingPartners));
    router.post('/partners/<partnerId>/approve',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.approve'))
            .addHandler(_partnerController.approvePartner));
    router.post('/partners/<partnerId>/reject',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.approve'))
            .addHandler(_partnerController.rejectPartner));
    router.get('/partners/active',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(_partnerController.getActivePartners));
    router.get('/partners/nearby',
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('partners.read'))
            .addHandler(_partnerController.getNearbyPartners));

    // Order management routes
    router.get('/orders', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(_orderController.getAllOrders));
    router.get('/orders/<orderId>', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.read'))
            .addHandler(_orderController.getOrder));
    router.put('/orders/<orderId>/status', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.update'))
            .addHandler(_orderController.updateOrderStatus));
    router.post('/orders/<orderId>/assign-rider', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('orders.update'))
            .addHandler(_orderController.assignRider));

    // Product management routes
    router.get('/products', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.read'))
            .addHandler(_productController.getAllProducts));
    router.post('/products', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.create'))
            .addHandler(_productController.createProduct));
    router.put('/products/<productId>', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.update'))
            .addHandler(_productController.updateProduct));
    router.delete('/products/<productId>', 
        pipeline.addMiddleware(PermissionMiddleware.requirePermission('products.delete'))
            .addHandler(_productController.deleteProduct));

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