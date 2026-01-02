import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/product_service.dart';

class ProductController {
  static final ProductService _productService = ProductService(null as dynamic, null as dynamic);

  static Future<Response> getProducts(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final partnerId = queryParams['partner_id'];
      final categoryId = queryParams['category_id'];
      final search = queryParams['search'];

      final offset = (page - 1) * limit;
      final products = await _productService.getProductsWithFilters(
        limit: limit,
        offset: offset,
        partnerId: partnerId != null ? int.tryParse(partnerId) : null,
        categoryId: categoryId != null ? int.tryParse(categoryId) : null,
      );

      return Response.ok(
        jsonEncode({
          'products': products.map((p) => p.toJson()).toList(),
          'page': page,
          'limit': limit,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> createProduct(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // Create product from request data
      final product = await _productService.createProduct(
        partnerId: data['partnerId'] as int,
        categoryId: data['categoryId'] as int,
        name: data['name'] as String,
        shortDescription: data['shortDescription'] as String? ?? data['description'] as String? ?? '',
        basePrice: (data['basePrice'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 0.0,
        longDescription: data['longDescription'] as String?,
        image: data['image'] as String?,
        images: data['images'] != null ? List<String>.from(data['images'] as List) : null,
        preparationTime: data['preparationTime'] as int?,
        calories: data['calories'] as int?,
        ingredients: data['ingredients'] != null ? List<String>.from(data['ingredients'] as List) : null,
        allergens: data['allergens'] != null ? List<String>.from(data['allergens'] as List) : null,
        tags: data['tags'] != null ? List<String>.from(data['tags'] as List) : null,
      );


      return Response.ok(
        jsonEncode(product.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getProduct(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final productId = params?['productId'];
      final id = int.tryParse(productId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid product ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final product = await _productService.getProductById(id);
      if (product == null) {
        return Response.notFound(
          jsonEncode({'error': 'Product not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(product.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updateProduct(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final productId = params?['productId'];
      final id = int.tryParse(productId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid product ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final updated = await _productService.updateProduct(
        id,
        name: data['name'] as String?,
        shortDescription: data['shortDescription'] as String? ?? data['description'] as String?,
        longDescription: data['longDescription'] as String?,
        basePrice: data['basePrice'] != null ? (data['basePrice'] as num).toDouble() : (data['price'] != null ? (data['price'] as num).toDouble() : null),
        image: data['image'] as String?,
        images: data['images'] != null ? List<String>.from(data['images'] as List) : null,
        preparationTime: data['preparationTime'] as int?,
        calories: data['calories'] as int?,
        ingredients: data['ingredients'] != null ? List<String>.from(data['ingredients'] as List) : null,
        allergens: data['allergens'] != null ? List<String>.from(data['allergens'] as List) : null,
        tags: data['tags'] != null ? List<String>.from(data['tags'] as List) : null,
      );
      if (updated == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to update product'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(updated.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deleteProduct(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final productId = params?['productId'];
      final id = int.tryParse(productId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid product ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _productService.deleteProduct(id);
      if (!success) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to delete product'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'Product deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
