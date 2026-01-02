import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'base_controller.dart';
import '../services/partner_service.dart';
import '../models/partner.dart';

/// Controller for partner-related endpoints
class PartnerController extends BaseController {
  final PartnerService _partnerService;

  PartnerController(this._partnerService);

  /// GET /partners - Get all partners
  Future<Response> getPartners(Request request) async {
    try {
      final pagination = BaseController.getPaginationParams(request);
      final searchQuery = BaseController.getSearchQuery(request);
      
      List<dynamic> partners;
      if (searchQuery != null) {
        partners = await _partnerService.searchPartners(
          searchQuery,
          limit: pagination['limit'],
          offset: pagination['offset'],
        );
      } else {
        partners = await _partnerService.getPartners(
          limit: pagination['limit'],
          offset: pagination['offset'],
        );
      }

      final partnersJson = partners.map((p) => p.toJson()).toList();

      return BaseController.paginated(
        data: partnersJson,
        total: partnersJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Partners retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /partners/{id} - Get partner by ID
  Future<Response> getPartner(Request request) async {
    try {
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      final partner = await _partnerService.getPartnerById(partnerId);
      
      if (partner == null) {
        return BaseController.notFound('Partner not found');
      }

      return BaseController.success(
        data: partner.toJson(),
        message: 'Partner retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /partners - Create new partner (admin only)
  Future<Response> createPartner(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (!BaseController.hasPermission(user, 'partners.create')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['name', 'mobile', 'email', 'address'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      // Validate email format
      final email = body!['email'] as String;
      if (!BaseController.isValidEmail(email)) {
        return BaseController.error(
          message: 'Invalid email format',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Validate mobile format
      final mobile = body['mobile'] as String;
      if (!BaseController.isValidMobile(mobile)) {
        return BaseController.error(
          message: 'Invalid mobile number format',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Create partner
      final partner = await _partnerService.createPartner(
        name: body['name'] as String,
        mobile: mobile,
        email: email,
        address: body['address'] as String,
        description: body['description'] as String?,
        logoUrl: body['logo_url'] as String?,
        businessLicense: body['business_license'] as String?,
      );

      return BaseController.success(
        data: partner.toJson(),
        message: 'Partner created successfully',
        statusCode: HttpStatus.created,
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /partners/{id} - Update partner
  Future<Response> updatePartner(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (!BaseController.hasPermission(user, 'partners.update')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      
      if (body == null || body.isEmpty) {
        return BaseController.error(
          message: 'Request body is required',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Validate email format if provided
      final email = body['email'] as String?;
      if (email != null && email.isNotEmpty && !BaseController.isValidEmail(email)) {
        return BaseController.error(
          message: 'Invalid email format',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Validate mobile format if provided
      final mobile = body['mobile'] as String?;
      if (mobile != null && mobile.isNotEmpty && !BaseController.isValidMobile(mobile)) {
        return BaseController.error(
          message: 'Invalid mobile number format',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Update partner
      final updatedPartner = await _partnerService.updatePartnerProfile(
        partnerId,
        businessName: body['name'] as String?,
        phone: mobile,
        email: email,
        address: body['address'] as String?,
        description: body['description'] as String?,
        logo: body['logo_url'] as String?,
        businessLicense: body['business_license'] as String?,
      );

      if (updatedPartner == null) {
        return BaseController.notFound('Partner not found');
      }

      return BaseController.success(
        data: updatedPartner.toJson(),
        message: 'Partner updated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// PUT /partners/{id}/status - Update partner status
  Future<Response> updatePartnerStatus(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (!BaseController.hasPermission(user, 'partners.update')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['status'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      // Parse status
      PartnerStatus status;
      try {
        status = PartnerStatus.values.firstWhere(
          (s) => s.name == body!['status'],
        );
      } catch (e) {
        return BaseController.error(
          message: 'Invalid partner status',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Update partner status
      final updatedPartner = await _partnerService.updatePartnerStatus(
        partnerId,
        status,
      );

      if (updatedPartner == null) {
        return BaseController.notFound('Partner not found');
      }

      return BaseController.success(
        data: updatedPartner.toJson(),
        message: 'Partner status updated successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// DELETE /partners/{id} - Delete partner (admin only)
  Future<Response> deletePartner(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (!BaseController.hasPermission(user, 'partners.delete')) {
        return BaseController.forbidden();
      }

      final success = await _partnerService.deletePartner(partnerId);

      if (!success) {
        return BaseController.notFound('Partner not found');
      }

      return BaseController.success(
        message: 'Partner deleted successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /partners/{id}/statistics - Get partner statistics
  Future<Response> getPartnerStatistics(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Check if user can access this partner's statistics
      if (!BaseController.canAccessResource(user, partnerId, 'partners.read')) {
        return BaseController.forbidden();
      }

      final params = BaseController.getQueryParams(request);
      DateTime? startDate;
      DateTime? endDate;
      
      if (params['start_date'] != null) {
        startDate = DateTime.tryParse(params['start_date']!);
      }
      
      if (params['end_date'] != null) {
        endDate = DateTime.tryParse(params['end_date']!);
      }

      final statistics = await _partnerService.getPartnerStatistics(
        partnerId,
        startDate: startDate,
        endDate: endDate,
      );

      return BaseController.success(
        data: statistics,
        message: 'Partner statistics retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /partners/{id}/orders - Get partner orders
  Future<Response> getPartnerOrders(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      // Check if user can access this partner's orders
      if (!BaseController.canAccessResource(user, partnerId, 'orders.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      
      final orders = await _partnerService.getPartnerOrders(
        partnerId,
        limit: pagination['limit'],
        offset: pagination['offset'],
      );

      final ordersJson = orders;

      return BaseController.paginated(
        data: ordersJson,
        total: ordersJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Partner orders retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /partners/pending - Get pending partner applications
  Future<Response> getPendingPartners(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      
      if (!BaseController.hasPermission(user, 'partners.read')) {
        return BaseController.forbidden();
      }

      final pagination = BaseController.getPaginationParams(request);
      
      final partners = await _partnerService.getPendingPartners(
        limit: pagination['limit'],
        offset: pagination['offset'],
      );

      final partnersJson = partners.map((p) => p.toJson()).toList();

      return BaseController.paginated(
        data: partnersJson,
        total: partnersJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Pending partners retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /partners/{id}/approve - Approve partner application
  Future<Response> approvePartner(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (!BaseController.hasPermission(user, 'partners.approve')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      final notes = body?['notes'] as String?;

      final approvedPartner = await _partnerService.approvePartner(
        partnerId,
        approvedBy: user!.id,
        notes: notes,
      );

      if (approvedPartner == null) {
        return BaseController.notFound('Partner not found');
      }

      return BaseController.success(
        data: approvedPartner.toJson(),
        message: 'Partner approved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// POST /partners/{id}/reject - Reject partner application
  Future<Response> rejectPartner(Request request) async {
    try {
      final user = BaseController.getUserFromRequest(request);
      final partnerId = BaseController.getIdFromParams(request, 'partnerId');
      
      if (partnerId == null) {
        return BaseController.error(
          message: 'Invalid partner ID',
          statusCode: HttpStatus.badRequest,
        );
      }

      if (!BaseController.hasPermission(user, 'partners.approve')) {
        return BaseController.forbidden();
      }

      final body = await BaseController.parseJsonBody(request);
      
      // Validate required fields
      final errors = BaseController.validateRequiredFields(
        body,
        ['reason'],
      );
      
      if (errors.isNotEmpty) {
        return BaseController.validationError(errors);
      }

      final rejectedPartner = await _partnerService.rejectPartner(
        partnerId,
        rejectedBy: user!.id,
        reason: body!['reason'] as String,
      );

      if (rejectedPartner == null) {
        return BaseController.notFound('Partner not found');
      }

      return BaseController.success(
        data: rejectedPartner.toJson(),
        message: 'Partner rejected successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /partners/active - Get active partners only
  Future<Response> getActivePartners(Request request) async {
    try {
      final pagination = BaseController.getPaginationParams(request);
      
      final partners = await _partnerService.getActivePartners(
        limit: pagination['limit'],
        offset: pagination['offset'],
      );

      final partnersJson = partners.map((p) => p.toJson()).toList();

      return BaseController.paginated(
        data: partnersJson,
        total: partnersJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Active partners retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }

  /// GET /partners/nearby - Get nearby partners based on location
  Future<Response> getNearbyPartners(Request request) async {
    try {
      final params = BaseController.getQueryParams(request);
      
      // Validate required location parameters
      final latStr = params['latitude'];
      final lngStr = params['longitude'];
      final radiusStr = params['radius'] ?? '10'; // Default 10km radius
      
      if (latStr == null || lngStr == null) {
        return BaseController.error(
          message: 'Latitude and longitude are required',
          statusCode: HttpStatus.badRequest,
        );
      }

      final latitude = double.tryParse(latStr);
      final longitude = double.tryParse(lngStr);
      final radius = double.tryParse(radiusStr) ?? 10.0;

      if (latitude == null || longitude == null) {
        return BaseController.error(
          message: 'Invalid latitude or longitude format',
          statusCode: HttpStatus.badRequest,
        );
      }

      final pagination = BaseController.getPaginationParams(request);
      
      final partners = await _partnerService.getNearbyPartners(
        latitude,
        longitude,
        maxDistance: radius,
        limit: pagination['limit'],
        offset: pagination['offset'],
      );

      final partnersJson = partners.map((p) => p.toJson()).toList();

      return BaseController.paginated(
        data: partnersJson,
        total: partnersJson.length,
        page: pagination['page']!,
        limit: pagination['limit']!,
        message: 'Nearby partners retrieved successfully',
      );
    } catch (e) {
      return BaseController.handleException(e);
    }
  }
}