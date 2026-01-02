import 'base_repository.dart';
import '../models/cart.dart';
import '../database/database_manager.dart';

/// Repository for cart-related database operations
class CartRepository extends BaseRepository {
  /// Add item to cart
  Future<CartItem> addCartItem({
    required int userId,
    required int productId,
    int? variantId,
    required int quantity,
    String? specialInstructions,
  }) async {
    final result = await db.query(
      '''
      INSERT INTO cart_items (
        user_id, product_id, product_variant_id, quantity,
        special_instructions, created_at, updated_at
      )
      VALUES (@userId, @productId, @variantId, @quantity, @instructions, NOW(), NOW())
      RETURNING id, user_id, product_id, product_variant_id, quantity,
                special_instructions, is_saved_for_later, created_at, updated_at
      ''',
      substitutionValues: {
        'userId': userId,
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'instructions': specialInstructions,
      },
    );

    return CartItem.fromMap(result.first.asMap());
  }

  /// Find cart item by ID
  Future<CartItem?> findById(int id) async {
    final result = await db.query(
      '''
      SELECT ci.*, p.name as product_name, p.image as product_image,
             pv.name as variant_name, pv.price as variant_price
      FROM cart_items ci
      LEFT JOIN products p ON ci.product_id = p.id
      LEFT JOIN product_variants pv ON ci.product_variant_id = pv.id
      WHERE ci.id = @id
      ''',
      substitutionValues: {'id': id},
    );

    if (result.isEmpty) return null;
    return CartItem.fromMap(result.first.asMap());
  }

  /// Find existing cart item for user and product
  Future<CartItem?> findCartItem(int userId, int productId, int? variantId) async {
    final result = await db.query(
      '''
      SELECT * FROM cart_items
      WHERE user_id = @userId
        AND product_id = @productId
        AND product_variant_id IS NOT DISTINCT FROM @variantId
        AND is_saved_for_later = false
      ''',
      substitutionValues: {
        'userId': userId,
        'productId': productId,
        'variantId': variantId,
      },
    );

    if (result.isEmpty) return null;
    return CartItem.fromMap(result.first.asMap());
  }

  /// Get all cart items for user
  Future<List<CartItem>> getUserCartItems(int userId) async {
    final result = await db.query(
      '''
      SELECT ci.*, p.name as product_name, p.image as product_image,
             p.base_price, p.discounted_price,
             pv.name as variant_name, pv.price as variant_price,
             CASE WHEN pv.price IS NOT NULL THEN pv.price
                  WHEN p.discounted_price IS NOT NULL THEN p.discounted_price
                  ELSE p.base_price END as unit_price
      FROM cart_items ci
      LEFT JOIN products p ON ci.product_id = p.id
      LEFT JOIN product_variants pv ON ci.product_variant_id = pv.id
      WHERE ci.user_id = @userId AND ci.is_saved_for_later = false
      ORDER BY ci.created_at DESC
      ''',
      substitutionValues: {'userId': userId},
    );

    return result.map((row) => CartItem.fromMap(row.asMap())).toList();
  }

  /// Update cart item
  Future<CartItem?> updateCartItem(
    int itemId, {
    int? quantity,
    String? specialInstructions,
  }) async {
    final updates = <String>[];
    final values = <String, dynamic>{'id': itemId};

    if (quantity != null) {
      updates.add('quantity = @quantity');
      values['quantity'] = quantity;
    }

    if (specialInstructions != null) {
      updates.add('special_instructions = @instructions');
      values['instructions'] = specialInstructions;
    }

    if (updates.isEmpty) {
      return await findById(itemId);
    }

    updates.add('updated_at = NOW()');

    final result = await db.query(
      '''
      UPDATE cart_items
      SET ${updates.join(', ')}
      WHERE id = @id
      RETURNING id, user_id, product_id, product_variant_id, quantity,
                special_instructions, is_saved_for_later, created_at, updated_at
      ''',
      substitutionValues: values,
    );

    if (result.isEmpty) return null;
    return CartItem.fromMap(result.first.asMap());
  }

  /// Update cart item quantity
  Future<CartItem> updateCartItemQuantity(
    int itemId,
    int quantity,
    String? specialInstructions,
  ) async {
    final result = await db.query(
      '''
      UPDATE cart_items
      SET quantity = @quantity,
          special_instructions = @instructions,
          updated_at = NOW()
      WHERE id = @id
      RETURNING id, user_id, product_id, product_variant_id, quantity,
                special_instructions, is_saved_for_later, created_at, updated_at
      ''',
      substitutionValues: {
        'id': itemId,
        'quantity': quantity,
        'instructions': specialInstructions,
      },
    );

    return CartItem.fromMap(result.first.asMap());
  }

  /// Remove cart item
  Future<bool> removeCartItem(int itemId) async {
    final result = await db.query(
      'DELETE FROM cart_items WHERE id = @id',
      substitutionValues: {'id': itemId},
    );

    return result.affectedRowCount > 0;
  }

  /// Clear user's cart
  Future<void> clearUserCart(int userId) async {
    await db.query(
      'DELETE FROM cart_items WHERE user_id = @userId AND is_saved_for_later = false',
      substitutionValues: {'userId': userId},
    );
  }

  /// Save item for later
  Future<bool> saveForLater(int itemId) async {
    final result = await db.query(
      'UPDATE cart_items SET is_saved_for_later = true, updated_at = NOW() WHERE id = @id',
      substitutionValues: {'id': itemId},
    );

    return result.affectedRowCount > 0;
  }

  /// Move saved item back to cart
  Future<bool> moveToCart(int itemId) async {
    final result = await db.query(
      'UPDATE cart_items SET is_saved_for_later = false, updated_at = NOW() WHERE id = @id',
      substitutionValues: {'id': itemId},
    );

    return result.affectedRowCount > 0;
  }

  /// Get saved for later items
  Future<List<CartItem>> getSavedItems(int userId) async {
    final result = await db.query(
      '''
      SELECT ci.*, p.name as product_name, p.image as product_image,
             p.base_price, p.discounted_price,
             pv.name as variant_name, pv.price as variant_price
      FROM cart_items ci
      LEFT JOIN products p ON ci.product_id = p.id
      LEFT JOIN product_variants pv ON ci.product_variant_id = pv.id
      WHERE ci.user_id = @userId AND ci.is_saved_for_later = true
      ORDER BY ci.created_at DESC
      ''',
      substitutionValues: {'userId': userId},
    );

    return result.map((row) => CartItem.fromMap(row.asMap())).toList();
  }

  /// Get cart items count for user
  Future<int> getCartItemsCount(int userId) async {
    final result = await db.query(
      'SELECT COALESCE(SUM(quantity), 0) as count FROM cart_items WHERE user_id = @userId AND is_saved_for_later = false',
      substitutionValues: {'userId': userId},
    );

    return result.first[0] as int? ?? 0;
  }

  /// Check if product exists in user's cart
  Future<bool> isProductInCart(int userId, int productId, int? variantId) async {
    final result = await db.query(
      '''
      SELECT COUNT(*) as count FROM cart_items
      WHERE user_id = @userId AND product_id = @productId
        AND product_variant_id IS NOT DISTINCT FROM @variantId
        AND is_saved_for_later = false
      ''',
      substitutionValues: {
        'userId': userId,
        'productId': productId,
        'variantId': variantId,
      },
    );

    return (result.first[0] as int) > 0;
  }
}
