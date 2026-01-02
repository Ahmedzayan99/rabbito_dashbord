import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/partner_service.dart';

class PartnerController {
  // TODO: Initialize with proper repositories
  static final PartnerService _partnerService = PartnerService(null as dynamic, null as dynamic);
  
  static Future<Response> getPartners(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final cityId = int.tryParse(queryParams['cityId'] ?? '');
      final categoryId = int.tryParse(queryParams['categoryId'] ?? '');
      
      final partners = await _partnerService.getPartners(
        limit: limit,
        offset: (page - 1) * limit,
      );
      
      return Response.ok(
        jsonEncode({
          'partners': partners.map((p) => p.toJson()).toList(),
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
}