import '../repositories/cart_repository.dart';
import '../repositories/product_repository.dart';
import '../models/cart.dart';
import '../models/product.dart';

/// Service for cart-related business logic
class CartService {
  final CartRepository _cartRepository;
  final ProductRepository _productRepository;

  CartService(this._cartRepository, this._productRepository);

  /// Add item to cart
  Future<CartItem> addToCart({
    required int userId,
    required int productId,
    int? variantId,
    required int quantity,
    String? specialInstructions,
  }) async {
    // Validate product exists
    final product = await _productRepository.findById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }

    // Validate product is active
    if (product.status != 'active') {
      throw Exception('Product is not available');
    }

    // Validate variant if provided
    if (variantId != null) {
      final variant = product.variants?.firstWhere(
        (v) => v.id == variantId,
        orElse: () => throw Exception('Product variant not found'),
      );
      if (variant == null) {
        throw Exception('Product variant not found');
      }
    }

    // Check if item already exists in cart
    final existingItem = await _cartRepository.findCartItem(userId, productId, variantId);

    if (existingItem != null) {
      // Update quantity
      final newQuantity = existingItem.quantity + quantity;
      return await _cartRepository.updateCartItemQuantity(
        existingItem.id,
        newQuantity,
        specialInstructions,
      );
    } else {
      // Add new item
      return await _cartRepository.addCartItem(
        userId: userId,
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        specialInstructions: specialInstructions,
      );
    }
  }

  /// Get user's cart with all items
  Future<Cart> getUserCart(int userId) async {
    final cartItems = await _cartRepository.getUserCartItems(userId);
    return Cart(userId: userId, items: cartItems);
  }

  /// Update cart item
  Future<CartItem?> updateCartItem(
    int itemId,
    {
    int? quantity,
    String? specialInstructions,
    required int userId,
  }
  ) async {
    // Verify item belongs to user
    final item = await _cartRepository.findById(itemId);
    if (item == null || item.userId != userId) {
      return null;
    }

    return await _cartRepository.updateCartItem(
      itemId,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
  }

  /// Remove item from cart
  Future<bool> removeFromCart(int itemId, int userId) async {
    // Verify item belongs to user
    final item = await _cartRepository.findById(itemId);
    if (item == null || item.userId != userId) {
      return false;
    }

    return await _cartRepository.removeCartItem(itemId);
  }

  /// Clear entire cart
  Future<void> clearCart(int userId) async {
    await _cartRepository.clearUserCart(userId);
  }

  /// Get cart summary with totals
  Future<Map<String, dynamic>> getCartSummary(int userId) async {
    final cartItems = await _cartRepository.getUserCartItems(userId);

    double subtotal = 0.0;
    int totalItems = 0;

    for (final item in cartItems) {
      subtotal += item.totalPrice;
      totalItems += item.quantity;
    }

    // Calculate delivery charge (simplified logic)
    double deliveryCharge = subtotal > 50 ? 0.0 : 5.0;

    // Calculate tax (simplified 5% tax)
    double taxAmount = subtotal * 0.05;

    double total = subtotal + deliveryCharge + taxAmount;

    return {
      'subtotal': subtotal,
      'delivery_charge': deliveryCharge,
      'tax_amount': taxAmount,
      'total': total,
      'total_items': totalItems,
      'items': cartItems.map((item) => item.toJson()).toList(),
    };
  }

  /// Validate cart before checkout
  Future<Map<String, dynamic>> validateCart(int userId) async {
    final cartItems = await _cartRepository.getUserCartItems(userId);
    final errors = <String>[];

    if (cartItems.isEmpty) {
      errors.add('Cart is empty');
    }

    // Validate each item
    for (final item in cartItems) {
      // Check product availability
      final product = await _productRepository.findById(item.productId);
      if (product == null) {
        errors.add('Product ${item.productId} no longer exists');
        continue;
      }

      if (product.status != 'active') {
        errors.add('Product ${product.name} is not available');
      }

      // Check variant availability if applicable
      if (item.variantId != null) {
        final variant = product.variants?.firstWhere(
          (v) => v.id == item.variantId,
          orElse: () => throw Exception('Variant not found'),
        );
        if (variant == null) {
          errors.add('Product variant for ${product.name} is not available');
        }
      }
    }

    return {
      'is_valid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// Get cart items count
  Future<int> getCartItemsCount(int userId) async {
    final cartItems = await _cartRepository.getUserCartItems(userId);
    return cartItems.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  /// Apply coupon to cart
  Future<Map<String, dynamic>> applyCoupon(int userId, String couponCode) async {
    // This is a simplified implementation
    // In a real system, you'd have a coupon repository and validation logic

    final summary = await getCartSummary(userId);

    // Example coupon logic
    double discount = 0.0;
    String message = 'Invalid coupon code';

    if (couponCode == 'WELCOME10') {
      discount = summary['subtotal'] * 0.1; // 10% off
      message = '10% discount applied';
    } else if (couponCode == 'FREEDELIVERY') {
      discount = summary['delivery_charge'];
      summary['delivery_charge'] = 0.0;
      message = 'Free delivery applied';
    }

    summary['discount'] = discount;
    summary['total'] = summary['total'] - discount;

    return {
      'success': discount > 0,
      'message': message,
      'cart_summary': summary,
    };
  }

  /// Remove applied coupon
  Future<Map<String, dynamic>> removeCoupon(int userId) async {
    final summary = await getCartSummary(userId);
    summary['discount'] = 0.0;
    summary['total'] = summary['subtotal'] + summary['delivery_charge'] + summary['tax_amount'];

    return summary;
  }

  /// Save item for later
  Future<bool> saveForLater(int itemId, int userId) async {
    // Verify item belongs to user
    final item = await _cartRepository.findById(itemId);
    if (item == null || item.userId != userId) {
      return false;
    }

    return await _cartRepository.saveForLater(itemId);
  }

  /// Move saved item back to cart
  Future<bool> moveToCart(int itemId, int userId) async {
    // Verify item belongs to user
    final item = await _cartRepository.findById(itemId);
    if (item == null || item.userId != userId) {
      return false;
    }

    return await _cartRepository.moveToCart(itemId);
  }

  /// Get saved for later items
  Future<List<CartItem>> getSavedItems(int userId) async {
    return await _cartRepository.getSavedItems(userId);
  }

  /// Merge guest cart with user cart
  Future<Cart> mergeGuestCart(int userId, List<Map<String, dynamic>> guestCartItems) async {
    for (final guestItem in guestCartItems) {
      final productId = guestItem['product_id'] as int;
      final quantity = guestItem['quantity'] as int;
      final variantId = guestItem['variant_id'] as int?;
      final specialInstructions = guestItem['special_instructions'] as String?;

      await addToCart(
        userId: userId,
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        specialInstructions: specialInstructions,
      );
    }

    return await getUserCart(userId);
  }
}

