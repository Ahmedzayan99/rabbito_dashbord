import 'dart:async';
import '../repositories/product_repository.dart';
import '../repositories/partner_repository.dart';
import '../models/product.dart';
import '../models/partner.dart';
import '../models/user.dart';

/// Service for product-related business logic
class ProductService {
  final ProductRepository _productRepository;
  final PartnerRepository _partnerRepository;

  ProductService(this._productRepository, this._partnerRepository);

  /// Create a new product
  Future<Product> createProduct({
    required int partnerId,
    required int categoryId,
    required String name,
    required String shortDescription,
    required double basePrice,
    String? longDescription,
    String? image,
    List<String>? images,
    int? preparationTime,
    int? calories,
    List<String>? ingredients,
    List<String>? allergens,
    List<String>? tags,
  }) async {
    try {
      // Validate partner exists and is active
      final partner = await _partnerRepository.findById(partnerId);
      if (partner == null || partner.status != PartnerStatus.active) {
        throw Exception('Partner not found or inactive');
      }

      // Validate product data
      if (name.trim().isEmpty) {
        throw Exception('Product name is required');
      }

      if (shortDescription.trim().isEmpty) {
        throw Exception('Product description is required');
      }

      if (basePrice <= 0) {
        throw Exception('Product price must be positive');
      }

      // Create product data
      final productData = {
        'partner_id': partnerId,
        'category_id': categoryId,
        'name': name.trim(),
        'short_description': shortDescription.trim(),
        'long_description': longDescription?.trim(),
        'base_price': basePrice,
        'image': image,
        'images': images,
        'status': ProductStatus.active.name,
        'rating': 0.0,
        'no_of_ratings': 0,
        'is_featured': false,
        'preparation_time': preparationTime ?? 15, // Default 15 minutes
        'calories': calories,
        'ingredients': ingredients,
        'allergens': allergens,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
      };

      return await _productRepository.create(productData);
    } catch (e) {
      throw Exception('Product creation failed: ${e.toString()}');
    }
  }

  /// Get product by ID with details
  Future<Map<String, dynamic>?> getProductWithDetails(int productId) async {
    return await _productRepository.getProductWithDetails(productId);
  }

  /// Get product by ID
  Future<Product?> getProductById(int productId) async {
    return await _productRepository.findById(productId);
  }

  /// Get products by partner
  Future<List<Product>> getProductsByPartner(int partnerId, {int? limit, int? offset}) async {
    return await _productRepository.findByPartnerId(partnerId, limit: limit, offset: offset);
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId, {int? limit, int? offset}) async {
    return await _productRepository.findByCategoryId(categoryId, limit: limit, offset: offset);
  }

  /// Get all active products
  Future<List<Product>> getActiveProducts({int? limit, int? offset}) async {
    return await _productRepository.findActiveProducts(limit: limit, offset: offset);
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int? limit, int? offset}) async {
    return await _productRepository.findFeaturedProducts(limit: limit, offset: offset);
  }

  /// Search products
  Future<List<Product>> searchProducts(String query, {int? limit, int? offset}) async {
    if (query.trim().isEmpty) {
      return await getActiveProducts(limit: limit, offset: offset);
    }
    return await _productRepository.searchProducts(query, limit: limit, offset: offset);
  }

  /// Get products by price range
  Future<List<Product>> getProductsByPriceRange(
    double minPrice,
    double maxPrice, {
    int? limit,
    int? offset,
  }) async {
    if (minPrice < 0 || maxPrice < 0 || minPrice > maxPrice) {
      throw Exception('Invalid price range');
    }
    return await _productRepository.findByPriceRange(minPrice, maxPrice, limit: limit, offset: offset);
  }

  /// Update product
  Future<Product?> updateProduct(int productId, {
    String? name,
    String? shortDescription,
    String? longDescription,
    double? basePrice,
    String? image,
    List<String>? images,
    int? preparationTime,
    int? calories,
    List<String>? ingredients,
    List<String>? allergens,
    List<String>? tags,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) {
        if (name.trim().isEmpty) {
          throw Exception('Product name cannot be empty');
        }
        updateData['name'] = name.trim();
      }

      if (shortDescription != null) {
        if (shortDescription.trim().isEmpty) {
          throw Exception('Product description cannot be empty');
        }
        updateData['short_description'] = shortDescription.trim();
      }

      if (longDescription != null) {
        updateData['long_description'] = longDescription.trim();
      }

      if (basePrice != null) {
        if (basePrice <= 0) {
          throw Exception('Product price must be positive');
        }
        updateData['base_price'] = basePrice;
      }

      if (image != null) updateData['image'] = image;
      if (images != null) updateData['images'] = images;
      if (preparationTime != null) {
        if (preparationTime <= 0) {
          throw Exception('Preparation time must be positive');
        }
        updateData['preparation_time'] = preparationTime;
      }
      if (calories != null) updateData['calories'] = calories;
      if (ingredients != null) updateData['ingredients'] = ingredients;
      if (allergens != null) updateData['allergens'] = allergens;
      if (tags != null) updateData['tags'] = tags;

      if (updateData.isEmpty) {
        return await _productRepository.findById(productId);
      }

      return await _productRepository.update(productId, updateData);
    } catch (e) {
      throw Exception('Product update failed: ${e.toString()}');
    }
  }

  /// Update product status
  Future<Product?> updateProductStatus(int productId, ProductStatus status) async {
    return await _productRepository.updateStatus(productId, status);
  }

  /// Toggle product featured status
  Future<Product?> toggleProductFeatured(int productId, bool isFeatured) async {
    return await _productRepository.toggleFeatured(productId, isFeatured);
  }

  /// Update product inventory status
  Future<Product?> updateInventoryStatus(int productId, bool inStock) async {
    return await _productRepository.updateInventoryStatus(productId, inStock);
  }

  /// Update product rating
  Future<Product?> updateProductRating(int productId, double rating) async {
    try {
      final product = await _productRepository.findById(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      if (rating < 0 || rating > 5) {
        throw Exception('Rating must be between 0 and 5');
      }

      // Calculate new average rating
      final totalRatings = product.numberOfRatings + 1;
      final currentTotal = product.rating * product.numberOfRatings;
      final newAverage = (currentTotal + rating) / totalRatings;

      return await _productRepository.updateRating(productId, newAverage, totalRatings);
    } catch (e) {
      throw Exception('Rating update failed: ${e.toString()}');
    }
  }

  /// Delete product (soft delete)
  Future<bool> deleteProduct(int productId) async {
    try {
      final product = await _productRepository.updateStatus(productId, ProductStatus.inactive);
      return product != null;
    } catch (e) {
      throw Exception('Product deletion failed: ${e.toString()}');
    }
  }

  /// Get top rated products
  Future<List<Product>> getTopRatedProducts({int limit = 10}) async {
    return await _productRepository.getTopRatedProducts(limit: limit);
  }

  /// Get most ordered products
  Future<List<Map<String, dynamic>>> getMostOrderedProducts({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _productRepository.getMostOrderedProducts(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get products with low ratings
  Future<List<Product>> getProductsWithLowRatings({double threshold = 3.0, int? limit}) async {
    return await _productRepository.getProductsWithLowRatings(threshold: threshold, limit: limit);
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    return await _productRepository.getProductStats();
  }

  /// Get products by partner with category info
  Future<List<Map<String, dynamic>>> getProductsByPartnerWithCategory(int partnerId) async {
    return await _productRepository.getProductsByPartnerWithCategory(partnerId);
  }

  /// Validate product data
  Map<String, String> validateProductData({
    required String name,
    required String shortDescription,
    required double basePrice,
    int? preparationTime,
    int? calories,
  }) {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Product name is required';
    }

    if (shortDescription.trim().isEmpty) {
      errors['short_description'] = 'Product description is required';
    }

    if (basePrice <= 0) {
      errors['base_price'] = 'Product price must be positive';
    }

    if (preparationTime != null && preparationTime <= 0) {
      errors['preparation_time'] = 'Preparation time must be positive';
    }

    if (calories != null && calories < 0) {
      errors['calories'] = 'Calories cannot be negative';
    }

    return errors;
  }

  /// Check if user can manage product
  bool canUserManageProduct(User user, Product product) {
    // Partner can manage their own products
    if (user.role.value == 'partner') {
      // Would need to check if user owns the partner account
      // For now, simplified check
      return true;
    }
    
    // Admin/staff can manage all products
    if (user.role.isStaff) return true;
    
    return false;
  }

  /// Get products by multiple filters
  Future<List<Product>> getProductsWithFilters({
    int? partnerId,
    int? categoryId,
    ProductStatus? status,
    bool? isFeatured,
    double? minPrice,
    double? maxPrice,
    List<String>? tags,
    int? limit,
    int? offset,
  }) async {
    // This would require a more complex query builder
    // For now, implement basic filtering
    
    if (partnerId != null) {
      return await getProductsByPartner(partnerId, limit: limit, offset: offset);
    }
    
    if (categoryId != null) {
      return await getProductsByCategory(categoryId, limit: limit, offset: offset);
    }
    
    if (isFeatured == true) {
      return await getFeaturedProducts(limit: limit, offset: offset);
    }
    
    if (minPrice != null && maxPrice != null) {
      return await getProductsByPriceRange(minPrice, maxPrice, limit: limit, offset: offset);
    }
    
    return await getActiveProducts(limit: limit, offset: offset);
  }

  /// Check if product exists and is active
  Future<bool> productExists(int productId) async {
    final product = await _productRepository.findById(productId);
    return product != null && product.status == ProductStatus.active;
  }

  /// Get product recommendations (simplified)
  Future<List<Product>> getProductRecommendations(int productId, {int limit = 5}) async {
    try {
      final product = await _productRepository.findById(productId);
      if (product == null) return [];

      // Get products from same category
      final recommendations = await _productRepository.findByCategoryId(
        product.categoryId,
        limit: limit + 1, // +1 to exclude current product
      );

      // Remove current product from recommendations
      recommendations.removeWhere((p) => p.id == productId);
      
      // Return only requested limit
      return recommendations.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Bulk update product status
  Future<List<Product>> bulkUpdateProductStatus(List<int> productIds, ProductStatus status) async {
    final updatedProducts = <Product>[];
    
    for (final productId in productIds) {
      try {
        final product = await updateProductStatus(productId, status);
        if (product != null) {
          updatedProducts.add(product);
        }
      } catch (e) {
        // Log error but continue with other products
        print('Failed to update product $productId: $e');
      }
    }
    
    return updatedProducts;
  }
}