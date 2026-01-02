import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/product_service.dart';

class ProductController {
  // TODO: Initialize with proper repositories
  static final ProductService _productService = ProductService(null as dynamic, null as dynamic);
  
  static Future<Response> getPartnerProducts(Request request) async {
    try {
      final partnerId = int.tryParse(request.url.queryParameters['partnerId'] ?? '');
      
      if (partnerId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final categoryId = int.tryParse(queryParams['categoryId'] ?? '');
      
      final products = await _productService.getProductsByPartner(
        partnerId,
        limit: limit,
        offset: (page - 1) * limit,
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
  
  static Future<Response> getProduct(Request request) async {
    try {
      final productId = int.tryParse(request.url.queryParameters['productId'] ?? '');
      
      if (productId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid product ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final product = await _productService.getProductById(productId);
      
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
}