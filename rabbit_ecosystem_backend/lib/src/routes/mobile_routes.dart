import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/mobile/auth_controller.dart';
import '../controllers/mobile/user_controller.dart';
import '../controllers/mobile/partner_controller.dart';
import '../controllers/mobile/order_controller.dart';
import '../controllers/mobile/product_controller.dart';
import '../controllers/mobile/wallet_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/payment_controller.dart';
import '../middleware/auth_middleware.dart';

class MobileRoutes {
  // TODO: Inject controllers via dependency injection
  static final CartController _cartController = CartController(null as dynamic);
  static final PaymentController _paymentController = PaymentController(null as dynamic);

  Router get router {
    final router = Router();

    // Auth routes (no authentication required)
    router.post('/auth/login', AuthController.login);
    router.post('/auth/register', AuthController.register);
    router.post('/auth/refresh', AuthController.refresh);

    // Protected routes (authentication required)
    final authPipeline = Pipeline().addMiddleware(AuthMiddleware.middleware);

    // User routes
    router.get('/user/profile',
        authPipeline.addHandler(UserController.getProfile));
    router.put('/user/profile',
        authPipeline.addHandler(UserController.updateProfile));

    // Partner and product routes
    router.get('/partners', PartnerController.getPartners);
    router.get('/partners/<partnerId>/products', ProductController.getPartnerProducts);
    router.get('/products/<productId>', ProductController.getProduct);
    // TODO: Implement getCategories method
    // router.get('/categories', ProductController.getCategories);

    // Order routes
    router.post('/orders',
        authPipeline.addHandler(OrderController.createOrder));
    router.get('/orders',
        authPipeline.addHandler(OrderController.getUserOrders));
    router.get('/orders/<orderId>',
        authPipeline.addHandler(OrderController.getOrder));
    // TODO: Implement cancelOrder method
    // router.put('/orders/<orderId>/cancel',
    //     authPipeline.addHandler(OrderController.cancelOrder));

    // Cart routes
    router.post('/cart/add',
        authPipeline.addHandler(_cartController.addToCart));
    router.get('/cart',
        authPipeline.addHandler(_cartController.getCart));
    router.put('/cart/items/<itemId>',
        authPipeline.addHandler(_cartController.updateCartItem));
    router.delete('/cart/items/<itemId>',
        authPipeline.addHandler(_cartController.removeFromCart));
    router.delete('/cart/clear',
        authPipeline.addHandler(_cartController.clearCart));
    router.get('/cart/summary',
        authPipeline.addHandler(_cartController.getCartSummary));
    router.post('/cart/validate',
        authPipeline.addHandler(_cartController.validateCart));
    router.get('/cart/count',
        authPipeline.addHandler(_cartController.getCartCount));
    router.post('/cart/apply-coupon',
        authPipeline.addHandler(_cartController.applyCoupon));
    router.delete('/cart/remove-coupon',
        authPipeline.addHandler(_cartController.removeCoupon));
    router.post('/cart/save-for-later/<itemId>',
        authPipeline.addHandler(_cartController.saveForLater));
    router.post('/cart/move-to-cart/<itemId>',
        authPipeline.addHandler(_cartController.moveToCart));
    router.get('/cart/saved-items',
        authPipeline.addHandler(_cartController.getSavedItems));

    // Payment routes
    router.post('/payments/process',
        authPipeline.addHandler(_paymentController.processPayment));
    router.get('/payments/<paymentId>',
        authPipeline.addHandler(_paymentController.getPayment));
    router.get('/payments',
        authPipeline.addHandler(_paymentController.getUserPayments));
    router.post('/payments/<paymentId>/refund',
        authPipeline.addHandler(_paymentController.refundPayment));
    router.get('/payments/methods',
        authPipeline.addHandler(_paymentController.getPaymentMethods));
    router.post('/payments/validate',
        authPipeline.addHandler(_paymentController.validatePayment));
    router.get('/payments/receipts/<paymentId>',
        authPipeline.addHandler(_paymentController.getPaymentReceipt));
    router.post('/payments/save-method',
        authPipeline.addHandler(_paymentController.savePaymentMethod));
    router.get('/payments/saved-methods',
        authPipeline.addHandler(_paymentController.getSavedPaymentMethods));
    router.delete('/payments/saved-methods/<methodId>',
        authPipeline.addHandler(_paymentController.deleteSavedPaymentMethod));

    // Wallet routes
    router.get('/wallet/balance',
        authPipeline.addHandler(WalletController.getBalance));
    router.get('/wallet/summary',
        authPipeline.addHandler(WalletController.getSummary));
    router.post('/wallet/topup',
        authPipeline.addHandler(WalletController.topup));
    router.post('/wallet/withdraw',
        authPipeline.addHandler(WalletController.withdraw));
    router.post('/wallet/transfer',
        authPipeline.addHandler(WalletController.transfer));
    router.get('/wallet/transactions',
        authPipeline.addHandler(WalletController.getTransactions));
    router.get('/wallet/limits',
        authPipeline.addHandler(WalletController.getLimits));
    router.post('/wallet/validate',
        authPipeline.addHandler(WalletController.validateOperation));

    return router;
  }
}