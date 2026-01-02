import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'base_controller.dart';
import '../services/cart_service.dart';
import '../models/cart.dart';

/// Controller for cart-related endpoints
class CartController extends BaseController {
  final CartService _cartService;

  CartController(this._cartService);

  /// POST /cart/add - Add item to cart
  Future<Response> addToCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['product_id', 'quantity'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      // Validate quantity
      final quantity = body!['quantity'];
      if (quantity is! int || quantity <= 0) {
        return BaseController.error(
          message: 'Quantity must be a positive integer',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Add item to cart
      final cartItem = await _cartService.addToCart(
        userId: user.id,
        productId: body['product_id'] as int,
        variantId: body['variant_id'] as int?,
        quantity: quantity,
        specialInstructions: body['special_instructions'] as String?,
      );

      return BaseController.success(
        data: cartItem.toJson(),
        message: 'Item added to cart successfully',
        statusCode: HttpStatus.created,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /cart - Get user's cart
  Future<Response> getCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final cart = await _cartService.getUserCart(user.id);

      return BaseController.success(
        data: cart.toJson(),
        message: 'Cart retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /cart/items/{itemId} - Update cart item
  Future<Response> updateCartItem(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final itemId = BaseController.getIdFromParams(request, 'itemId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (itemId == null) {
        return BaseController.error(
          message: 'Invalid item ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final body = await BaseController.parseJsonBody(request);
      
      if (body == null || body.isEmpty) {
        return BaseController.error(
          message: 'Request body is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Validate quantity if provided
      final quantity = body['quantity'];
      if (quantity != null && (quantity is! int || quantity <= 0)) {
        return BaseController.error(
          message: 'Quantity must be a positive integer',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Update cart item
      final updatedItem = await _cartService.updateCartItem(
        itemId,
        userId: user.id,
        quantity: quantity,
        specialInstructions: body['special_instructions'] as String?,
      );

      if (updatedItem == null) {
        return BaseController.notFound('Cart item not found');
      }

      return BaseController.success(
        data: updatedItem.toJson(),
        message: 'Cart item updated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /cart/items/{itemId} - Remove item from cart
  Future<Response> removeFromCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final itemId = BaseController.getIdFromParams(request, 'itemId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (itemId == null) {
        return BaseController.error(
          message: 'Invalid item ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final success = await _cartService.removeFromCart(itemId, user.id);

      if (!success) {
        return BaseController.notFound('Cart item not found');
      }

      return BaseController.success(
        message: 'Item removed from cart successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /cart/clear - Clear entire cart
  Future<Response> clearCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      await _cartService.clearCart(user.id);

      return BaseController.success(
        message: 'Cart cleared successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /cart/summary - Get cart summary with totals
  Future<Response> getCartSummary(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final summary = await _cartService.getCartSummary(user.id);

      return BaseController.success(
        data: summary,
        message: 'Cart summary retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /cart/validate - Validate cart before checkout
  Future<Response> validateCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final validation = await _cartService.validateCart(user.id);

      if (!validation['is_valid']) {
        return BaseController.error(
          message: 'Cart validation failed',
          errors: validation['errors'],
          statusCode: HttpStatus.badRequest,
        );
      }

      return BaseController.success(
        data: validation,
        message: 'Cart is valid for checkout',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /cart/merge - Merge guest cart with user cart
  Future<Response> mergeCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['guest_cart_items'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final guestCartItems = body!['guest_cart_items'] as List<dynamic>;
      
      // Validate guest cart items structure
      for (int i = 0; i < guestCartItems.length; i++) {
        final item = guestCartItems[i] as Map<String, dynamic>;
        
        if (!item.containsKey('product_id') || !item.containsKey('quantity')) {
          return BaseController.error(
            message: 'Item ${i + 1}: product_id and quantity are required',
            statusCode: HttpStatus.badRequest,
          );
        }

        final quantity = item['quantity'];
        if (quantity is! int || quantity <= 0) {
          return BaseController.error(
            message: 'Item ${i + 1}: quantity must be a positive integer',
            statusCode: HttpStatus.badRequest,
          );
        }
      }

      // Merge carts
      final mergedCart = await _cartService.mergeGuestCart(
        user.id,
        guestCartItems.cast<Map<String, dynamic>>(),
      );

      return BaseController.success(
        data: mergedCart.toJson(),
        message: 'Cart merged successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /cart/count - Get cart items count
  Future<Response> getCartCount(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final count = await _cartService.getCartItemsCount(user.id);

      return BaseController.success(
        data: {'count': count},
        message: 'Cart count retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /cart/apply-coupon - Apply coupon to cart
  Future<Response> applyCoupon(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['coupon_code'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final couponCode = body!['coupon_code'] as String;

      // Apply coupon
      final result = await _cartService.applyCoupon(user.id, couponCode);

      if (!result['success']) {
        return BaseController.error(
          message: result['message'] as String,
          statusCode: HttpStatus.badRequest,
        );
      }

      return BaseController.success(
        data: result['cart_summary'],
        message: result['message'] as String,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /cart/remove-coupon - Remove applied coupon
  Future<Response> removeCoupon(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final result = await _cartService.removeCoupon(user.id);

      return BaseController.success(
        data: result,
        message: 'Coupon removed successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /cart/save-for-later - Save cart item for later
  Future<Response> saveForLater(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final itemId = BaseController.getIdFromParams(request, 'itemId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (itemId == null) {
        return BaseController.error(
          message: 'Invalid item ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final success = await _cartService.saveForLater(itemId, user.id);

      if (!success) {
        return BaseController.notFound('Cart item not found');
      }

      return BaseController.success(
        message: 'Item saved for later successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /cart/move-to-cart - Move saved item back to cart
  Future<Response> moveToCart(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final itemId = BaseController.getIdFromParams(request, 'itemId');
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      if (itemId == null) {
        return BaseController.error(
          message: 'Invalid item ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final success = await _cartService.moveToCart(itemId, user.id);

      if (!success) {
        return BaseController.notFound('Saved item not found');
      }

      return BaseController.success(
        message: 'Item moved to cart successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /cart/saved-items - Get saved for later items
  Future<Response> getSavedItems(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (user == null) {
        return BaseController.unauthorized();
      }

      final savedItems = await _cartService.getSavedItems(user.id);

      return BaseController.success(
        data: savedItems.map((item) => item.toJson()).toList(),
        message: 'Saved items retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}