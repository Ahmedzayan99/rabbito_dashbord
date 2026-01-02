import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/dashboard/analytics_controller.dart';
import '../controllers/dashboard/user_management_controller.dart';
import '../controllers/dashboard/partner_management_controller.dart';
import '../controllers/dashboard/order_management_controller.dart';
import '../controllers/dashboard/wallet_management_controller.dart';
import '../controllers/dashboard/notification_management_controller.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_middleware.dart';
import '../models/user_role.dart';

class DashboardRoutes {
  Router get router {
    final router = Router();
    
    // Analytics routes (admin roles only)
    router.get('/analytics/overview', 
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(AnalyticsController.getOverview));
    
    router.get('/analytics/sales', 
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(AnalyticsController.getSalesReport));
    
    // User management routes
    router.get('/users', 
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(UserManagementController.getUsers));
    
    router.post('/users', 
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(UserManagementController.createUser));
    
    // Partner management routes
    router.get('/partners', 
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(PartnerManagementController.getPartners));
    
    router.put('/partners/<partnerId>/status', 
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(PartnerManagementController.updatePartnerStatus));
    
    // Order management routes
    router.get('/orders',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(OrderManagementController.getOrders));

    router.get('/orders/<orderId>',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(OrderManagementController.getOrder));

    router.put('/orders/<orderId>/status',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(OrderManagementController.updateOrderStatus));

    router.post('/orders/<orderId>/assign-rider',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.dispatcher]))
            .addHandler(OrderManagementController.assignRider));

    router.post('/orders/<orderId>/cancel',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(OrderManagementController.cancelOrder));

    router.get('/orders/statistics',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(OrderManagementController.getOrderStatistics));

    router.get('/orders/recent',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(OrderManagementController.getRecentOrders));

    router.get('/orders/pending',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.dispatcher]))
            .addHandler(OrderManagementController.getPendingOrders));

    // Wallet management routes
    router.get('/wallets/statistics',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(WalletManagementController.getStatistics));

    router.get('/wallets/users',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(WalletManagementController.getUsersWallets));

    router.get('/wallets/user/<userId>',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(WalletManagementController.getUserWallet));

    router.get('/wallets/user/<userId>/transactions',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(WalletManagementController.getUserTransactions));

    router.post('/wallets/user/<userId>/credit',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(WalletManagementController.creditUserWallet));

    router.post('/wallets/user/<userId>/debit',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(WalletManagementController.debitUserWallet));

    router.post('/wallets/user/<userId>/reset',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin]))
            .addHandler(WalletManagementController.resetUserWallet));

    router.get('/wallets/low-balance',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(WalletManagementController.getUsersWithLowBalance));

    router.get('/wallets/activity',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.finance]))
            .addHandler(WalletManagementController.getWalletActivity));

    router.post('/wallets/transfer',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(WalletManagementController.transferBetweenUsers));

    // Notification management routes
    router.get('/notifications',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(NotificationManagementController.getNotifications));

    router.get('/notifications/<notificationId>',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(NotificationManagementController.getNotification));

    router.post('/notifications',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(NotificationManagementController.sendNotification));

    router.post('/notifications/bulk',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(NotificationManagementController.sendBulkNotification));

    router.post('/notifications/targeted',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.marketing]))
            .addHandler(NotificationManagementController.sendTargetedNotification));

    router.put('/notifications/<notificationId>/read',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(NotificationManagementController.markAsRead));

    router.put('/notifications/user/<userId>/read-all',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.support]))
            .addHandler(NotificationManagementController.markAllAsRead));

    router.delete('/notifications/<notificationId>',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin]))
            .addHandler(NotificationManagementController.deleteNotification));

    router.get('/notifications/statistics',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.analytics]))
            .addHandler(NotificationManagementController.getStatistics));

    router.get('/notifications/types',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.analytics]))
            .addHandler(NotificationManagementController.getTypesSummary));

    router.get('/notifications/trends',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin, UserRole.admin, UserRole.analytics]))
            .addHandler(NotificationManagementController.getTrends));

    router.post('/notifications/cleanup',
        Pipeline()
            .addMiddleware(AuthMiddleware.middleware)
            .addMiddleware(RoleMiddleware.requireRoles([UserRole.superAdmin]))
            .addHandler(NotificationManagementController.cleanupOldNotifications));

    return router;
  }
}