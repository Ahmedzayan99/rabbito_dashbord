import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';

class PartnerManagementController {
  static final PartnerService _partnerService = PartnerService();
  
  static Future<Response> getPartners(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final statusFilter = queryParams['status'];
      
      PartnerStatus? status;
      if (statusFilter != null) {
        status = PartnerStatus.values.firstWhere(
          (s) => s.name == statusFilter,
          orElse: () => PartnerStatus.active,
        );
      }
      
      final partners = await _partnerService.getPartners(
        page: page,
        limit: limit,
        status: status,
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
  
  static Future<Response> updatePartnerStatus(Request request) async {
    try {
      final partnerId = int.tryParse(request.params['partnerId'] ?? '');
      
      if (partnerId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final statusString = data['status'] as String?;
      
      if (statusString == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Status is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final status = PartnerStatus.values.firstWhere(
        (s) => s.name == statusString,
        orElse: () => PartnerStatus.active,
      );
      
      final updatedPartner = await _partnerService.updatePartnerStatus(partnerId, status);
      
      if (updatedPartner == null) {
        return Response.notFound(
          jsonEncode({'error': 'Partner not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      return Response.ok(
        jsonEncode(updatedPartner.toJson()),
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