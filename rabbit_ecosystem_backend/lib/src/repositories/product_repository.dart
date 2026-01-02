import 'dart:async';
import 'package:postgres/postgres.dart';
import 'base_repository.dart';
import '../models/product.dart';

/// Repository for product-related database operations
class ProductRepository extends BaseRepository<Product> {
  ProductRepository(super.connection);

  @override
  String get tableName => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) {
    return Product.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Product product) {
    return {
      'partner_id': product.partnerId,
      'category_id': product.categoryId,
      'name': product.name,
      'short_description': product.shortDescription,
      'long_description': product.longDescription,
      'base_price': product.basePrice,
      'image': product.image,
      'images': product.images,
      'status': product.status.name,
      'rating': product.rating,
      'no_of_ratings': product.numberOfRatings,
      'is_featured': product.isFeatured,
      'preparation_time': product.preparationTime,
      'calories': product.calories,
      'ingredients': product.ingredients,
      'allergens': product.allergens,
      'tags': product.tags,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt?.toIso8601String(),
    };
  }

  /// Find products by partner ID
  Future<List<Product>> findByPartnerId(int partnerId, {int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM products 
      WHERE partner_id = @partner_id AND status = @status 
      ORDER BY is_featured DESC, created_at DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {
        'partner_id': partnerId,
        'status': ProductStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find products by category ID
  Future<List<Product>> findByCategoryId(int categoryId, {int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM products 
      WHERE category_id = @category_id AND status = @status 
      ORDER BY is_featured DESC, rating DESC, created_at DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {
        'category_id': categoryId,
        'status': ProductStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find products by status
  Future<List<Product>> findByStatus(ProductStatus status, {int? limit, int? offset}) async {
    String query = 'SELECT * FROM products WHERE status = @status ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'status': status.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find active products
  Future<List<Product>> findActiveProducts({int? limit, int? offset}) async {
    return await findByStatus(ProductStatus.active, limit: limit, offset: offset);
  }

  /// Find featured products
  Future<List<Product>> findFeaturedProducts({int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM products 
      WHERE status = @status AND is_featured = true 
      ORDER BY rating DESC, created_at DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'status': ProductStatus.active.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Search products by name, description, or tags
  Future<List<Product>> searchProducts(String query, {int? limit, int? offset}) async {
    final searchQuery = '''
      SELECT * FROM products 
      WHERE (
        name ILIKE @query OR 
        short_description ILIKE @query OR 
        long_description ILIKE @query OR
        tags ILIKE @query
      )
      AND status = @status
      ORDER BY 
        CASE WHEN name ILIKE @query THEN 1 ELSE 2 END,
        rating DESC, 
        created_at DESC
    ''';

    String finalQuery = searchQuery;
    if (limit != null) {
      finalQuery += ' LIMIT $limit';
    }
    if (offset != null) {
      finalQuery += ' OFFSET $offset';
    }

    final result = await connection.execute(
      finalQuery,
      parameters: {
        'query': '%$query%',
        'status': ProductStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Update product status
  Future<Product?> updateStatus(int productId, ProductStatus status) async {
    return await update(productId, {'status': status.name});
  }

  /// Update product rating
  Future<Product?> updateRating(int productId, double newRating, int totalRatings) async {
    return await update(productId, {
      'rating': newRating,
      'no_of_ratings': totalRatings,
    });
  }

  /// Toggle featured status
  Future<Product?> toggleFeatured(int productId, bool isFeatured) async {
    return await update(productId, {'is_featured': isFeatured});
  }

  /// Get product with variants and add-ons
  Future<Map<String, dynamic>?> getProductWithDetails(int productId) async {
    final productResult = await executeQuerySingle(
      'SELECT * FROM products WHERE id = @id',
      parameters: {'id': productId},
    );

    if (productResult == null) return null;

    final variantsResult = await executeQuery(
      'SELECT * FROM product_variants WHERE product_id = @product_id ORDER BY is_default DESC, price ASC',
      parameters: {'product_id': productId},
    );

    final addOnsResult = await executeQuery(
      'SELECT * FROM product_addons WHERE product_id = @product_id ORDER BY is_required DESC, price ASC',
      parameters: {'product_id': productId},
    );

    return {
      'product': productResult,
      'variants': variantsResult,
      'addons': addOnsResult,
    };
  }

  /// Get top rated products
  Future<List<Product>> getTopRatedProducts({int limit = 10}) async {
    final result = await connection.execute(
      '''SELECT * FROM products 
         WHERE status = @status AND no_of_ratings >= 5
         ORDER BY rating DESC, no_of_ratings DESC
         LIMIT $limit''',
      parameters: {'status': ProductStatus.active.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Get most ordered products
  Future<List<Map<String, dynamic>>> getMostOrderedProducts({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    Map<String, dynamic> parameters = {};

    if (startDate != null || endDate != null) {
      whereClause = 'WHERE ';
      final conditions = <String>[];
      
      if (startDate != null) {
        conditions.add('o.created_at >= @start_date');
        parameters['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        conditions.add('o.created_at <= @end_date');
        parameters['end_date'] = endDate.toIso8601String();
      }
      
      whereClause += conditions.join(' AND ');
    }

    final result = await executeQuery('''
      SELECT 
        p.*,
        COUNT(oi.id) as total_orders,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.total_price) as total_revenue
      FROM products p
      LEFT JOIN order_items oi ON p.id = oi.product_id
      LEFT JOIN orders o ON oi.order_id = o.id
      $whereClause
      GROUP BY p.id
      ORDER BY total_quantity DESC, total_revenue DESC
      LIMIT $limit
    ''', parameters: parameters);

    return result;
  }

  /// Get products by price range
  Future<List<Product>> findByPriceRange(double minPrice, double maxPrice, {int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM products 
      WHERE base_price >= @min_price AND base_price <= @max_price AND status = @status
      ORDER BY base_price ASC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {
        'min_price': minPrice,
        'max_price': maxPrice,
        'status': ProductStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStats() async {
    final result = await executeQuerySingle('''
      SELECT 
        COUNT(*) as total_products,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products,
        COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive_products,
        COUNT(CASE WHEN status = 'out_of_stock' THEN 1 END) as out_of_stock_products,
        COUNT(CASE WHEN is_featured = true THEN 1 END) as featured_products,
        AVG(base_price) as average_price,
        AVG(rating) as average_rating,
        MIN(base_price) as min_price,
        MAX(base_price) as max_price
      FROM products
    ''');

    return result ?? {};
  }

  /// Get products by partner with category info
  Future<List<Map<String, dynamic>>> getProductsByPartnerWithCategory(int partnerId) async {
    final result = await executeQuery('''
      SELECT 
        p.*,
        c.name as category_name,
        c.description as category_description
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.partner_id = @partner_id AND p.status = @status
      ORDER BY c.sort_order ASC, p.is_featured DESC, p.name ASC
    ''', parameters: {
      'partner_id': partnerId,
      'status': ProductStatus.active.name,
    });

    return result;
  }

  /// Update product inventory status
  Future<Product?> updateInventoryStatus(int productId, bool inStock) async {
    final status = inStock ? ProductStatus.active : ProductStatus.outOfStock;
    return await updateStatus(productId, status);
  }

  /// Get products with low ratings (for quality control)
  Future<List<Product>> getProductsWithLowRatings({double threshold = 3.0, int? limit}) async {
    String query = '''
      SELECT * FROM products 
      WHERE rating < @threshold AND no_of_ratings >= 5 AND status = @status
      ORDER BY rating ASC, no_of_ratings DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }

    final result = await connection.execute(
      query,
      parameters: {
        'threshold': threshold,
        'status': ProductStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }
}