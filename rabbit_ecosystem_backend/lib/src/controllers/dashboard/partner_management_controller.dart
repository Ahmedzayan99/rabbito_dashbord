import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../services/partner_service.dart';
import '../../models/partner.dart';
import '../base_controller.dart';

class PartnerManagementController {
  static final PartnerService _partnerService = PartnerService(null as dynamic, null as dynamic);
  
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
      
      final offset = (page - 1) * limit;
      final partners = await _partnerService.getPartners(
        limit: limit,
        offset: offset,
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
  
  static Future<Response> getPartner(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final partner = await _partnerService.getPartnerById(id);
      if (partner == null) {
        return Response.notFound(
          jsonEncode({'error': 'Partner not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(partner.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> createPartner(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final partner = await _partnerService.createPartner(
        name: data['name'] as String? ?? data['businessName'] as String? ?? '',
        mobile: data['mobile'] as String? ?? data['phone'] as String? ?? '',
        email: data['email'] as String? ?? '',
        address: data['address'] as String? ?? '',
        description: data['description'] as String?,
        logoUrl: data['logoUrl'] as String? ?? data['logo'] as String?,
        businessLicense: data['businessLicense'] as String?,
      );

      return Response.ok(
        jsonEncode(partner.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updatePartner(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final updatedPartner = await _partnerService.updatePartnerProfile(
        id,
        businessName: data['businessName'] as String?,
        businessType: data['businessType'] as String?,
        address: data['address'] as String?,
        latitude: data['latitude'] != null ? (data['latitude'] as num).toDouble() : null,
        longitude: data['longitude'] != null ? (data['longitude'] as num).toDouble() : null,
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        description: data['description'] as String?,
        logo: data['logo'] as String? ?? data['logoUrl'] as String?,
      );

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
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deletePartner(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _partnerService.deletePartner(id);
      if (!success) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Failed to delete partner'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'message': 'Partner deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getPartnerStatistics(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final queryParams = request.url.queryParameters;
      final startDate = queryParams['startDate'] != null
          ? DateTime.tryParse(queryParams['startDate']!)
          : null;
      final endDate = queryParams['endDate'] != null
          ? DateTime.tryParse(queryParams['endDate']!)
          : null;

      final stats = await _partnerService.getPartnerStatistics(
        id,
        startDate: startDate,
        endDate: endDate,
      );

      return Response.ok(
        jsonEncode(stats),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getPartnerOrders(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final offset = (page - 1) * limit;

      final orders = await _partnerService.getPartnerOrders(
        id,
        limit: limit,
        offset: offset,
      );

      return Response.ok(
        jsonEncode({
          'orders': orders,
          'page': page,
          'limit': limit,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getPendingPartners(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final offset = (page - 1) * limit;

      final partners = await _partnerService.getPendingPartners(
        limit: limit,
        offset: offset,
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
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> approvePartner(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final approvedBy = BaseController.getUserFromRequest(request)?.id ?? 0;
      final notes = data['notes'] as String?;

      final partner = await _partnerService.approvePartner(
        id,
        approvedBy: approvedBy,
        notes: notes,
      );

      if (partner == null) {
        return Response.notFound(
          jsonEncode({'error': 'Partner not found or cannot be approved'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(partner.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> rejectPartner(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid partner ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final rejectedBy = BaseController.getUserFromRequest(request)?.id ?? 0;
      final reason = data['reason'] as String? ?? 'No reason provided';

      final partner = await _partnerService.rejectPartner(
        id,
        rejectedBy: rejectedBy,
        reason: reason,
      );

      if (partner == null) {
        return Response.notFound(
          jsonEncode({'error': 'Partner not found or cannot be rejected'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(partner.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getActivePartners(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final offset = (page - 1) * limit;

      final partners = await _partnerService.getActivePartners(
        limit: limit,
        offset: offset,
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
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getNearbyPartners(Request request) async {
    try {
      final queryParams = request.url.queryParameters;
      final latitude = double.tryParse(queryParams['latitude'] ?? '');
      final longitude = double.tryParse(queryParams['longitude'] ?? '');

      if (latitude == null || longitude == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Latitude and longitude are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final offset = (page - 1) * limit;
      final radius = double.tryParse(queryParams['radius'] ?? '10') ?? 10.0;

      final partners = await _partnerService.getNearbyPartnersByLocation(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: limit,
        offset: offset,
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
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updatePartnerStatus(Request request) async {
    try {
      final params = request.context['shelf_router/params'] as Map<String, String>?;
      final partnerId = params?['partnerId'];
      final id = int.tryParse(partnerId ?? '');
      if (id == null) {
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
      
      final updatedPartner = await _partnerService.updatePartnerStatus(id, status);
      
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
        body: jsonEncode({'error': 'Internal server error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}