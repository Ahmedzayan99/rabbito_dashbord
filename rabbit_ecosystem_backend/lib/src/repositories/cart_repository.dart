import 'package:postgres/postgres.dart';
import 'base_repository.dart';
import '../models/cart.dart';

/// Repository for cart-related database operations
class CartRepository extends BaseRepository<CartItem> {
  CartRepository(super.connection);

  @override
  String get tableName => 'cart_items';

  @override
  CartItem fromMap(Map<String, dynamic> map) {
    return CartItem.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(CartItem cartItem) {
    return cartItem.toJson();
  }
  /// Add item to cart
  Future<CartItem> addCartItem({
    required int userId,
    required int productId,
    int? variantId,
    required int quantity,
    String? specialInstructions,
  }) async {
    final result = await connection.execute(
      '''
      INSERT INTO cart_items (
        user_id, product_id, product_variant_id, quantity,
        special_instructions, created_at, updated_at
      )
      VALUES (\$1, \$2, \$3, \$4, \$5, NOW(), NOW())
      RETURNING id, user_id, product_id, product_variant_id, quantity,
                special_instructions, is_saved_for_later, created_at, updated_at
      ''',
      parameters: [
        userId,
        productId,
        variantId,
        quantity,
        specialInstructions,
      ],
    );

    return CartItem.fromMap(result.first.toColumnMap());
  }

  /// Find cart item by ID
  Future<CartItem?> findById(int id) async {
    final result = await connection.execute(
      '''
      SELECT ci.*, p.name as product_name, p.image as product_image,
             pv.name as variant_name, pv.price as variant_price
      FROM cart_items ci
      LEFT JOIN products p ON ci.product_id = p.id
      LEFT JOIN product_variants pv ON ci.product_variant_id = pv.id
      WHERE ci.id = \$1
      ''',
      parameters: [id],
    );

    if (result.isEmpty) return null;
    return CartItem.fromMap(result.first.toColumnMap());
  }

  /// Find existing cart item for user and product
  Future<CartItem?> findCartItem(int userId, int productId, int? variantId) async {
    final result = await connection.execute(
      '''
      SELECT * FROM cart_items
      WHERE user_id = \$1
        AND product_id = \$2
        AND product_variant_id IS NOT DISTINCT FROM \$3
        AND is_saved_for_later = false
      ''',
      parameters: [
        userId,
        productId,
        variantId,
      ],
    );

    if (result.isEmpty) return null;
    return CartItem.fromMap(result.first.toColumnMap());
  }

  /// Get all cart items for user
  Future<List<CartItem>> getUserCartItems(int userId) async {
    final result = await connection.execute(
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
      WHERE ci.user_id = \$1 AND ci.is_saved_for_later = false
      ORDER BY ci.created_at DESC
      ''',
      parameters: [userId],
    );

    return result.map((row) => CartItem.fromMap(row.toColumnMap())).toList();
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

    final parameters = <dynamic>[itemId];
    final setClauses = <String>[];

    if (quantity != null) {
      setClauses.add('quantity = \$2');
      parameters.add(quantity);
    }

    if (specialInstructions != null) {
      setClauses.add('special_instructions = \$${parameters.length + 1}');
      parameters.add(specialInstructions);
    }

    if (setClauses.isEmpty) {
      return await findById(itemId);
    }

    setClauses.add('updated_at = NOW()');

    final result = await connection.execute(
      '''
      UPDATE cart_items
      SET ${setClauses.join(', ')}
      WHERE id = \$1
      RETURNING id, user_id, product_id, product_variant_id, quantity,
                special_instructions, is_saved_for_later, created_at, updated_at
      ''',
      parameters: parameters,
    );

    if (result.isEmpty) return null;
    return CartItem.fromMap(result.first.toColumnMap());
  }

  /// Update cart item quantity
  Future<CartItem> updateCartItemQuantity(
    int itemId,
    int quantity,
    String? specialInstructions,
  ) async {
    final result = await connection.execute(
      '''
      UPDATE cart_items
      SET quantity = \$2,
          special_instructions = \$3,
          updated_at = NOW()
      WHERE id = \$1
      RETURNING id, user_id, product_id, product_variant_id, quantity,
                special_instructions, is_saved_for_later, created_at, updated_at
      ''',
      parameters: [
        itemId,
        quantity,
        specialInstructions,
      ],
    );

    return CartItem.fromMap(result.first.toColumnMap());
  }

  /// Remove cart item
  Future<bool> removeCartItem(int itemId) async {
    final result = await connection.execute(
      'DELETE FROM cart_items WHERE id = \$1',
      parameters: [itemId],
    );

    return result.affectedRows > 0;
  }

  /// Clear user's cart
  Future<void> clearUserCart(int userId) async {
    await connection.execute(
      'DELETE FROM cart_items WHERE user_id = \$1 AND is_saved_for_later = false',
      parameters: [userId],
    );
  }

  /// Save item for later
  Future<bool> saveForLater(int itemId) async {
    final result = await connection.execute(
      'UPDATE cart_items SET is_saved_for_later = true, updated_at = NOW() WHERE id = \$1',
      parameters: [itemId],
    );

    return result.affectedRows > 0;
  }

  /// Move saved item back to cart
  Future<bool> moveToCart(int itemId) async {
    final result = await connection.execute(
      'UPDATE cart_items SET is_saved_for_later = false, updated_at = NOW() WHERE id = \$1',
      parameters: [itemId],
    );

    return result.affectedRows > 0;
  }

  /// Get saved for later items
  Future<List<CartItem>> getSavedItems(int userId) async {
    final result = await connection.execute(
      '''
      SELECT ci.*, p.name as product_name, p.image as product_image,
             p.base_price, p.discounted_price,
             pv.name as variant_name, pv.price as variant_price
      FROM cart_items ci
      LEFT JOIN products p ON ci.product_id = p.id
      LEFT JOIN product_variants pv ON ci.product_variant_id = pv.id
      WHERE ci.user_id = \$1 AND ci.is_saved_for_later = true
      ORDER BY ci.created_at DESC
      ''',
      parameters: [userId],
    );

    return result.map((row) => CartItem.fromMap(row.toColumnMap())).toList();
  }

  /// Get cart items count for user
  Future<int> getCartItemsCount(int userId) async {
    final result = await connection.execute(
      'SELECT COALESCE(SUM(quantity), 0) as count FROM cart_items WHERE user_id = \$1 AND is_saved_for_later = false',
      parameters: [userId],
    );

    return result.first[0] as int? ?? 0;
  }

  /// Check if product exists in user's cart
  Future<bool> isProductInCart(int userId, int productId, int? variantId) async {
    final result = await connection.execute(
      '''
      SELECT COUNT(*) as count FROM cart_items
      WHERE user_id = \$1 AND product_id = \$2
        AND product_variant_id IS NOT DISTINCT FROM \$3
        AND is_saved_for_later = false
      ''',
      parameters: [
        userId,
        productId,
        variantId,
      ],
    );

    return (result.first[0] as int) > 0;
  }
}
